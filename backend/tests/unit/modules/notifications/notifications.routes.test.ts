import { describe, it, expect, vi } from 'vitest';

vi.mock('../../../../src/middleware/auth.js', () => ({
  authenticate: vi.fn(),
}));

vi.mock('../../../../src/modules/notifications/notifications.handlers.js', () => ({
  registerDeviceHandler: vi.fn(),
  removeDeviceHandler: vi.fn(),
}));

import notificationsRoutes from '../../../../src/modules/notifications/notifications.routes.js';

describe('notificationsRoutes', () => {
  it('should register device routes with auth hook', async () => {
    const mockFastify = {
      post: vi.fn(),
      delete: vi.fn(),
      addHook: vi.fn(),
    };

    await notificationsRoutes(mockFastify as any);

    expect(mockFastify.addHook).toHaveBeenCalledWith('onRequest', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/devices', expect.any(Function));
    expect(mockFastify.delete).toHaveBeenCalledWith('/api/devices/:token', expect.any(Function));
  });
});
