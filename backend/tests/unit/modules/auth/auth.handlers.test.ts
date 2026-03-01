import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockRegisterUser, mockLoginUser, mockRefreshTokens } = vi.hoisted(() => ({
  mockRegisterUser: vi.fn(),
  mockLoginUser: vi.fn(),
  mockRefreshTokens: vi.fn(),
}));

vi.mock('../../../../src/modules/auth/auth.service.js', () => ({
  registerUser: mockRegisterUser,
  loginUser: mockLoginUser,
  refreshTokens: mockRefreshTokens,
}));

// We need to mock the db transitively because auth.schemas imports zod (fine),
// but auth.service imports db. The mock above takes care of the service.

import { registerHandler, loginHandler, refreshHandler } from '../../../../src/modules/auth/auth.handlers.js';

function createMockRequest(body: unknown = {}, user?: { id: string; email: string }) {
  return {
    body,
    query: {},
    params: {},
    user: user ?? { id: 'user-1', email: 'test@example.com' },
    server: { httpErrors: {} },
  };
}

function createMockReply() {
  const reply = {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
  return reply;
}

describe('registerHandler', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should parse body and call registerUser, returning 201', async () => {
    const body = {
      email: 'test@example.com',
      password: 'password123',
      displayName: 'Test User',
      plateNumber: 'ABC1234',
    };
    const serviceResult = { user: { id: 'u1' }, tokens: { accessToken: 'a', refreshToken: 'r' } };
    mockRegisterUser.mockResolvedValue(serviceResult);

    const request = createMockRequest(body);
    const reply = createMockReply();

    await registerHandler(request as any, reply as any);

    expect(mockRegisterUser).toHaveBeenCalledWith(request.server, body);
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith(serviceResult);
  });
});

describe('loginHandler', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should parse body and call loginUser', async () => {
    const body = { email: 'test@example.com', password: 'password123' };
    const serviceResult = { user: { id: 'u1' }, tokens: { accessToken: 'a', refreshToken: 'r' } };
    mockLoginUser.mockResolvedValue(serviceResult);

    const request = createMockRequest(body);
    const reply = createMockReply();

    await loginHandler(request as any, reply as any);

    expect(mockLoginUser).toHaveBeenCalledWith(request.server, body);
    expect(reply.send).toHaveBeenCalledWith(serviceResult);
  });
});

describe('refreshHandler', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should parse body and call refreshTokens', async () => {
    const body = { refreshToken: 'some-refresh-token' };
    const serviceResult = { tokens: { accessToken: 'new-a', refreshToken: 'new-r' } };
    mockRefreshTokens.mockResolvedValue(serviceResult);

    const request = createMockRequest(body);
    const reply = createMockReply();

    await refreshHandler(request as any, reply as any);

    expect(mockRefreshTokens).toHaveBeenCalledWith(request.server, 'some-refresh-token');
    expect(reply.send).toHaveBeenCalledWith(serviceResult);
  });
});
