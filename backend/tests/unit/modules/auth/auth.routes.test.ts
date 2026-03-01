import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.hoisted(() => {
  // We need these mocked before the route module tries to import them
});

vi.mock('../../../../src/modules/auth/auth.handlers.js', () => ({
  registerHandler: vi.fn(),
  loginHandler: vi.fn(),
  refreshHandler: vi.fn(),
}));

import authRoutes from '../../../../src/modules/auth/auth.routes.js';

describe('authRoutes', () => {
  it('should register POST /api/auth/register, /api/auth/login, /api/auth/refresh', async () => {
    const mockFastify = {
      post: vi.fn(),
      get: vi.fn(),
      addHook: vi.fn(),
    };

    await authRoutes(mockFastify as any);

    expect(mockFastify.post).toHaveBeenCalledTimes(3);
    expect(mockFastify.post).toHaveBeenCalledWith('/api/auth/register', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/auth/login', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/auth/refresh', expect.any(Function));
  });
});
