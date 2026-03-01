import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { buildApp, getMockDb, resetDbMocks, signTestToken, fakeUuid, type MockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';
import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';

describe('Auth routes', () => {
  let app: FastifyInstance;
  let mockDb: MockDb;

  beforeAll(async () => {
    app = await buildApp();
    mockDb = getMockDb();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    resetDbMocks();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/auth/register
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/auth/register', () => {
    const validBody = {
      email: 'alice@example.com',
      password: 'Password123',
      displayName: 'Alice',
      plateNumber: 'ABC 123',
    };

    it('should register a new user and return 201 with tokens', async () => {
      const userId = fakeUuid();

      // No existing user
      mockDb.query.users.findFirst.mockResolvedValue(null);
      // No existing plate
      mockDb.query.licensePlates.findFirst.mockResolvedValue(null);

      // Transaction creates user + plate
      mockDb.transaction.mockImplementation(async (fn: (tx: unknown) => Promise<unknown>) => {
        const txInsertChain = {
          values: vi.fn().mockReturnThis(),
          returning: vi.fn().mockResolvedValue([
            { id: userId, email: validBody.email, displayName: validBody.displayName },
          ]),
        };
        const txInsertPlateFn = vi.fn().mockReturnValue({
          values: vi.fn().mockReturnThis(),
          returning: vi.fn().mockResolvedValue([]),
        });

        let insertCallCount = 0;
        const tx = {
          insert: vi.fn().mockImplementation(() => {
            insertCallCount++;
            if (insertCallCount === 1) {
              return txInsertChain; // user insert
            }
            return txInsertPlateFn(); // plate insert
          }),
          update: vi.fn().mockReturnValue({
            set: vi.fn().mockReturnThis(),
            where: vi.fn().mockResolvedValue(undefined),
          }),
        };
        return fn(tx);
      });

      // update for storing refresh token hash
      mockDb.update.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue(undefined),
        }),
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: validBody,
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.user).toBeDefined();
      expect(body.user.id).toBe(userId);
      expect(body.user.email).toBe(validBody.email);
      expect(body.user.displayName).toBe(validBody.displayName);
      expect(body.tokens).toBeDefined();
      expect(body.tokens.accessToken).toBeDefined();
      expect(body.tokens.refreshToken).toBeDefined();
    });

    it('should return 409 when email is already registered', async () => {
      mockDb.query.users.findFirst.mockResolvedValue({
        id: fakeUuid(),
        email: validBody.email,
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: validBody,
      });

      expect(response.statusCode).toBe(409);
    });

    it('should return 409 when plate is already claimed', async () => {
      // No existing user
      mockDb.query.users.findFirst.mockResolvedValue(null);
      // Plate exists and is claimed
      mockDb.query.licensePlates.findFirst.mockResolvedValue({
        id: fakeUuid(),
        userId: 'some-other-user-id',
        plateNumber: 'ABC123',
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: validBody,
      });

      expect(response.statusCode).toBe(409);
    });

    it('should return 400 for missing email', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: {
          password: 'Password123',
          displayName: 'Alice',
          plateNumber: 'ABC123',
        },
      });

      expect(response.statusCode).toBe(400);
      const body = response.json();
      expect(body.error).toBe('Validation Error');
    });

    it('should return 400 for short password', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: {
          email: 'alice@example.com',
          password: 'short',
          displayName: 'Alice',
          plateNumber: 'ABC123',
        },
      });

      expect(response.statusCode).toBe(400);
      const body = response.json();
      expect(body.error).toBe('Validation Error');
      expect(body.message).toContain('Password must be at least 8 characters');
    });

    it('should return 400 for invalid email format', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: {
          email: 'not-an-email',
          password: 'Password123',
          displayName: 'Alice',
          plateNumber: 'ABC123',
        },
      });

      expect(response.statusCode).toBe(400);
      const body = response.json();
      expect(body.error).toBe('Validation Error');
    });

    it('should return 400 for missing plate number', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: {
          email: 'alice@example.com',
          password: 'Password123',
          displayName: 'Alice',
        },
      });

      expect(response.statusCode).toBe(400);
      const body = response.json();
      expect(body.error).toBe('Validation Error');
    });

    it('should return 400 for empty displayName', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/register',
        payload: {
          email: 'alice@example.com',
          password: 'Password123',
          displayName: '',
          plateNumber: 'ABC123',
        },
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/auth/login
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/auth/login', () => {
    const userId = fakeUuid();

    it('should login and return tokens', async () => {
      const passwordHash = await bcrypt.hash('Password123', 12);

      mockDb.query.users.findFirst.mockResolvedValue({
        id: userId,
        email: 'alice@example.com',
        passwordHash,
        displayName: 'Alice',
      });

      mockDb.update.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue(undefined),
        }),
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {
          email: 'alice@example.com',
          password: 'Password123',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.user).toBeDefined();
      expect(body.user.id).toBe(userId);
      expect(body.user.email).toBe('alice@example.com');
      expect(body.tokens).toBeDefined();
      expect(body.tokens.accessToken).toBeDefined();
      expect(body.tokens.refreshToken).toBeDefined();
    });

    it('should return 401 for non-existent email', async () => {
      mockDb.query.users.findFirst.mockResolvedValue(null);

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {
          email: 'nobody@example.com',
          password: 'Password123',
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it('should return 401 for wrong password', async () => {
      const passwordHash = await bcrypt.hash('CorrectPassword', 12);

      mockDb.query.users.findFirst.mockResolvedValue({
        id: userId,
        email: 'alice@example.com',
        passwordHash,
        displayName: 'Alice',
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {
          email: 'alice@example.com',
          password: 'WrongPassword',
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it('should return 400 for missing email', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {
          password: 'Password123',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing password', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {
          email: 'alice@example.com',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for empty body', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/login',
        payload: {},
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/auth/refresh
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/auth/refresh', () => {
    it('should refresh tokens with a valid refresh token', async () => {
      const userId = fakeUuid();
      const refreshToken = app.jwt.sign(
        { id: userId, email: 'alice@example.com' },
        { expiresIn: '7d', jti: crypto.randomUUID() },
      );
      const refreshTokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');

      mockDb.query.users.findFirst.mockResolvedValue({
        id: userId,
        email: 'alice@example.com',
        refreshTokenHash,
      });

      mockDb.update.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue(undefined),
        }),
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/refresh',
        payload: {
          refreshToken,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.tokens).toBeDefined();
      expect(body.tokens.accessToken).toBeDefined();
      expect(body.tokens.refreshToken).toBeDefined();
      // New tokens should be different from the old one
      expect(body.tokens.refreshToken).not.toBe(refreshToken);
    });

    it('should return 401 for invalid refresh token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/refresh',
        payload: {
          refreshToken: 'definitely-not-a-valid-jwt',
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it('should return 401 when token hash does not match stored hash', async () => {
      const userId = fakeUuid();
      const refreshToken = app.jwt.sign(
        { id: userId, email: 'alice@example.com' },
        { expiresIn: '7d', jti: crypto.randomUUID() },
      );

      mockDb.query.users.findFirst.mockResolvedValue({
        id: userId,
        email: 'alice@example.com',
        refreshTokenHash: 'a-completely-different-hash',
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/refresh',
        payload: {
          refreshToken,
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it('should return 400 for missing refreshToken field', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/auth/refresh',
        payload: {},
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Auth guard: protected routes without token
  // ──────────────────────────────────────────────────────────────────────────
  describe('Auth guard — protected routes without token', () => {
    const protectedRoutes: Array<{ method: 'GET' | 'POST' | 'PATCH' | 'DELETE'; url: string }> = [
      { method: 'GET', url: '/api/plates' },
      { method: 'POST', url: '/api/plates' },
      { method: 'DELETE', url: '/api/plates/some-id' },
      { method: 'POST', url: '/api/messages' },
      { method: 'GET', url: '/api/messages/inbox' },
      { method: 'GET', url: '/api/messages/sent' },
      { method: 'GET', url: '/api/messages/unread-count' },
      { method: 'GET', url: '/api/messages/some-id' },
      { method: 'PATCH', url: '/api/messages/some-id/read' },
      { method: 'POST', url: '/api/messages/some-id/replies' },
      { method: 'POST', url: '/api/reports' },
      { method: 'POST', url: '/api/devices' },
      { method: 'DELETE', url: '/api/devices/some-token' },
    ];

    for (const { method, url } of protectedRoutes) {
      it(`should return 401 for ${method} ${url} without auth token`, async () => {
        const response = await app.inject({
          method,
          url,
        });

        expect(response.statusCode).toBe(401);
        const body = response.json();
        expect(body.error).toBe('Unauthorized');
      });
    }

    it('should return 401 with an expired token', async () => {
      // Create a token that is already expired by setting iat far in the past
      const pastIat = Math.floor(Date.now() / 1000) - 3600; // 1 hour ago
      const token = app.jwt.sign(
        { id: fakeUuid(), email: 'alice@example.com', iat: pastIat },
        { expiresIn: '1s' },
      );

      // Token with iat 1 hour ago + expiresIn 1s is definitely expired
      const response = await app.inject({
        method: 'GET',
        url: '/api/plates',
        headers: {
          authorization: `Bearer ${token}`,
        },
      });

      expect(response.statusCode).toBe(401);
    });

    it('should return 401 with a malformed bearer header', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/api/plates',
        headers: {
          authorization: 'NotBearer some-token',
        },
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
