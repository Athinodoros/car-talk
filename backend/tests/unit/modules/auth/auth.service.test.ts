import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';

// -------------------------------------------------------------------
// vi.hoisted() returns values available inside vi.mock factories,
// because vi.mock calls are hoisted to the top of the file.
// -------------------------------------------------------------------
const { mockDbQuery, mockDbInsert, mockDbUpdate, mockDbTransaction, mockBcrypt } = vi.hoisted(() => ({
  mockDbQuery: {
    users: { findFirst: vi.fn() },
    licensePlates: { findFirst: vi.fn() },
  },
  mockDbInsert: vi.fn(),
  mockDbUpdate: vi.fn(),
  mockDbTransaction: vi.fn(),
  mockBcrypt: {
    hash: vi.fn().mockResolvedValue('$2a$12$hashedpassword'),
    compare: vi.fn(),
  },
}));

vi.mock('../../../../src/db/index.js', () => ({
  db: {
    query: mockDbQuery,
    insert: mockDbInsert,
    update: mockDbUpdate,
    transaction: mockDbTransaction,
  },
}));

vi.mock('bcryptjs', () => ({
  default: mockBcrypt,
}));

import bcrypt from 'bcryptjs';
import {
  hashPassword,
  verifyPassword,
  generateTokens,
  registerUser,
  loginUser,
  refreshTokens,
} from '../../../../src/modules/auth/auth.service.js';

// ---- Helpers ----

function createMockFastify(): FastifyInstance {
  return {
    jwt: {
      sign: vi.fn().mockReturnValue('mock-jwt-token'),
      verify: vi.fn(),
    },
    httpErrors: {
      conflict: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 409;
        return err;
      },
      unauthorized: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 401;
        return err;
      },
    },
  } as unknown as FastifyInstance;
}

function chainReturning(data: unknown[]) {
  return { returning: vi.fn().mockResolvedValue(data) };
}

function chainValuesReturning(data: unknown[]) {
  return { values: vi.fn().mockReturnValue(chainReturning(data)) };
}

function chainSetWhere(data: unknown[] = []) {
  return {
    set: vi.fn().mockReturnValue({
      where: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue(data),
      }),
    }),
  };
}

describe('hashPassword', () => {
  it('should call bcrypt.hash with 12 rounds', async () => {
    const result = await hashPassword('testpassword');
    expect(bcrypt.hash).toHaveBeenCalledWith('testpassword', 12);
    expect(result).toBe('$2a$12$hashedpassword');
  });
});

describe('verifyPassword', () => {
  it('should return true for matching password', async () => {
    vi.mocked(bcrypt.compare).mockResolvedValue(true as never);
    const result = await verifyPassword('password', 'hash');
    expect(result).toBe(true);
    expect(bcrypt.compare).toHaveBeenCalledWith('password', 'hash');
  });

  it('should return false for non-matching password', async () => {
    vi.mocked(bcrypt.compare).mockResolvedValue(false as never);
    const result = await verifyPassword('wrong', 'hash');
    expect(result).toBe(false);
  });
});

describe('generateTokens', () => {
  it('should generate access and refresh tokens', () => {
    const fastify = createMockFastify();
    const payload = { id: 'user-1', email: 'test@example.com' };

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    const tokens = generateTokens(fastify, payload);

    expect(fastify.jwt.sign).toHaveBeenCalledTimes(2);
    expect(fastify.jwt.sign).toHaveBeenCalledWith(payload, { expiresIn: '15m' });
    expect(fastify.jwt.sign).toHaveBeenCalledWith(payload, expect.objectContaining({ expiresIn: '7d' }));
    expect(tokens.accessToken).toBe('access-token');
    expect(tokens.refreshToken).toBe('refresh-token');
  });
});

describe('registerUser', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  const validBody = {
    email: 'test@example.com',
    password: 'password123',
    displayName: 'Test User',
    plateNumber: 'ABC-1234',
    stateOrRegion: 'CA',
  };

  it('should register a new user with a new plate (happy path)', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue(undefined);
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    const newUser = { id: 'user-1', email: 'test@example.com', displayName: 'Test User' };

    mockDbTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        insert: vi.fn().mockReturnValue(chainValuesReturning([newUser])),
      };
      return fn(tx);
    });

    mockDbUpdate.mockReturnValue(chainSetWhere());

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    const result = await registerUser(fastify, validBody);

    expect(result.user.id).toBe('user-1');
    expect(result.user.email).toBe('test@example.com');
    expect(result.tokens.accessToken).toBe('access-token');
    expect(result.tokens.refreshToken).toBe('refresh-token');
    expect(mockDbQuery.users.findFirst).toHaveBeenCalled();
    expect(mockDbQuery.licensePlates.findFirst).toHaveBeenCalled();
    expect(mockDbTransaction).toHaveBeenCalled();
  });

  it('should throw conflict when email already registered', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue({ id: 'existing-user', email: 'test@example.com' });

    await expect(registerUser(fastify, validBody)).rejects.toThrow('Email already registered');
  });

  it('should throw conflict when plate is already claimed', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue(undefined);
    mockDbQuery.licensePlates.findFirst.mockResolvedValue({
      id: 'plate-1',
      userId: 'other-user',
      plateNumber: 'ABC1234',
    });

    await expect(registerUser(fastify, validBody)).rejects.toThrow('License plate already claimed');
  });

  it('should claim existing unclaimed plate', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue(undefined);
    mockDbQuery.licensePlates.findFirst.mockResolvedValue({
      id: 'plate-1',
      userId: null,
      plateNumber: 'ABC1234',
    });

    const newUser = { id: 'user-1', email: 'test@example.com', displayName: 'Test User' };

    mockDbTransaction.mockImplementation(async (fn: (tx: unknown) => Promise<unknown>) => {
      const tx = {
        insert: vi.fn().mockReturnValue(chainValuesReturning([newUser])),
        update: vi.fn().mockReturnValue(chainSetWhere()),
      };
      return fn(tx);
    });

    mockDbUpdate.mockReturnValue(chainSetWhere());

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    const result = await registerUser(fastify, validBody);
    expect(result.user.id).toBe('user-1');
  });

  it('should normalize the plate number before lookup', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue({ id: 'existing-user', email: 'test@example.com' });

    await expect(registerUser(fastify, { ...validBody, plateNumber: 'abc - 1234' })).rejects.toThrow(
      'Email already registered',
    );
  });
});

describe('loginUser', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  const validBody = { email: 'test@example.com', password: 'password123' };

  it('should login successfully with valid credentials', async () => {
    const user = {
      id: 'user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      passwordHash: '$2a$12$existinghash',
    };
    mockDbQuery.users.findFirst.mockResolvedValue(user);
    vi.mocked(bcrypt.compare).mockResolvedValue(true as never);
    mockDbUpdate.mockReturnValue(chainSetWhere());

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    const result = await loginUser(fastify, validBody);

    expect(result.user.id).toBe('user-1');
    expect(result.user.email).toBe('test@example.com');
    expect(result.tokens.accessToken).toBe('access-token');
    expect(result.tokens.refreshToken).toBe('refresh-token');
  });

  it('should throw unauthorized for nonexistent user', async () => {
    mockDbQuery.users.findFirst.mockResolvedValue(undefined);

    await expect(loginUser(fastify, validBody)).rejects.toThrow('Invalid email or password');
  });

  it('should throw unauthorized for wrong password', async () => {
    const user = {
      id: 'user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      passwordHash: '$2a$12$existinghash',
    };
    mockDbQuery.users.findFirst.mockResolvedValue(user);
    vi.mocked(bcrypt.compare).mockResolvedValue(false as never);

    await expect(loginUser(fastify, validBody)).rejects.toThrow('Invalid email or password');
  });

  it('should store refresh token hash after successful login', async () => {
    const user = {
      id: 'user-1',
      email: 'test@example.com',
      displayName: 'Test User',
      passwordHash: '$2a$12$existinghash',
    };
    mockDbQuery.users.findFirst.mockResolvedValue(user);
    vi.mocked(bcrypt.compare).mockResolvedValue(true as never);

    const mockSet = vi.fn().mockReturnValue({ where: vi.fn() });
    mockDbUpdate.mockReturnValue({ set: mockSet });

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('access-token')
      .mockReturnValueOnce('refresh-token');

    await loginUser(fastify, validBody);

    expect(mockDbUpdate).toHaveBeenCalled();
    expect(mockSet).toHaveBeenCalledWith(expect.objectContaining({ refreshTokenHash: expect.any(String) }));
  });
});

describe('refreshTokens', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should throw unauthorized for invalid/expired refresh token', async () => {
    vi.mocked(fastify.jwt.verify).mockImplementation(() => {
      throw new Error('jwt expired');
    });

    await expect(refreshTokens(fastify, 'expired-token')).rejects.toThrow(
      'Invalid or expired refresh token',
    );
  });

  it('should throw unauthorized if user not found', async () => {
    vi.mocked(fastify.jwt.verify).mockReturnValue({ id: 'user-1', email: 'test@example.com' } as never);
    mockDbQuery.users.findFirst.mockResolvedValue(undefined);

    await expect(refreshTokens(fastify, 'valid-token')).rejects.toThrow(
      'Invalid or expired refresh token',
    );
  });

  it('should throw unauthorized if refresh token hash does not match', async () => {
    vi.mocked(fastify.jwt.verify).mockReturnValue({ id: 'user-1', email: 'test@example.com' } as never);
    mockDbQuery.users.findFirst.mockResolvedValue({
      id: 'user-1',
      email: 'test@example.com',
      refreshTokenHash: 'wrong-hash',
    });

    await expect(refreshTokens(fastify, 'valid-token')).rejects.toThrow(
      'Invalid or expired refresh token',
    );
  });

  it('should rotate tokens on valid refresh', async () => {
    const crypto = await import('node:crypto');
    const tokenHash = crypto.createHash('sha256').update('valid-refresh-token').digest('hex');

    vi.mocked(fastify.jwt.verify).mockReturnValue({ id: 'user-1', email: 'test@example.com' } as never);
    mockDbQuery.users.findFirst.mockResolvedValue({
      id: 'user-1',
      email: 'test@example.com',
      refreshTokenHash: tokenHash,
    });

    mockDbUpdate.mockReturnValue(chainSetWhere());

    vi.mocked(fastify.jwt.sign)
      .mockReturnValueOnce('new-access-token')
      .mockReturnValueOnce('new-refresh-token');

    const result = await refreshTokens(fastify, 'valid-refresh-token');

    expect(result.tokens.accessToken).toBe('new-access-token');
    expect(result.tokens.refreshToken).toBe('new-refresh-token');
    expect(mockDbUpdate).toHaveBeenCalled();
  });
});
