import { describe, it, expect, vi } from 'vitest';

vi.mock('../../../../src/middleware/auth.js', () => ({
  authenticate: vi.fn(),
}));

vi.mock('../../../../src/modules/messages/messages.handlers.js', () => ({
  sendMessageHandler: vi.fn(),
  getInboxHandler: vi.fn(),
  getSentHandler: vi.fn(),
  getUnreadCountHandler: vi.fn(),
  getMessageDetailHandler: vi.fn(),
  markAsReadHandler: vi.fn(),
  addReplyHandler: vi.fn(),
}));

import messagesRoutes from '../../../../src/modules/messages/messages.routes.js';

describe('messagesRoutes', () => {
  it('should register all message routes with auth hook', async () => {
    const mockFastify = {
      post: vi.fn(),
      get: vi.fn(),
      patch: vi.fn(),
      addHook: vi.fn(),
    };

    await messagesRoutes(mockFastify as any);

    expect(mockFastify.addHook).toHaveBeenCalledWith('onRequest', expect.any(Function));
    // POST /api/messages (with rate limit config)
    expect(mockFastify.post).toHaveBeenCalledWith('/api/messages', expect.objectContaining({
      handler: expect.any(Function),
    }));
    expect(mockFastify.get).toHaveBeenCalledWith('/api/messages/inbox', expect.any(Function));
    expect(mockFastify.get).toHaveBeenCalledWith('/api/messages/sent', expect.any(Function));
    expect(mockFastify.get).toHaveBeenCalledWith('/api/messages/unread-count', expect.any(Function));
    expect(mockFastify.get).toHaveBeenCalledWith('/api/messages/:id', expect.any(Function));
    expect(mockFastify.patch).toHaveBeenCalledWith('/api/messages/:id/read', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/messages/:id/replies', expect.any(Function));
  });
});
