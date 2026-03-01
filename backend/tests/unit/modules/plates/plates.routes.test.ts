import { describe, it, expect, vi } from 'vitest';

vi.mock('../../../../src/middleware/auth.js', () => ({
  authenticate: vi.fn(),
}));

vi.mock('../../../../src/modules/plates/plates.handlers.js', () => ({
  claimPlateHandler: vi.fn(),
  listPlatesHandler: vi.fn(),
  releasePlateHandler: vi.fn(),
}));

import platesRoutes from '../../../../src/modules/plates/plates.routes.js';

describe('platesRoutes', () => {
  it('should register all plate routes with auth hook', async () => {
    const mockFastify = {
      post: vi.fn(),
      get: vi.fn(),
      delete: vi.fn(),
      addHook: vi.fn(),
    };

    await platesRoutes(mockFastify as any);

    expect(mockFastify.addHook).toHaveBeenCalledWith('onRequest', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/plates', expect.any(Function));
    expect(mockFastify.get).toHaveBeenCalledWith('/api/plates', expect.any(Function));
    expect(mockFastify.delete).toHaveBeenCalledWith('/api/plates/:id', expect.any(Function));
  });
});
