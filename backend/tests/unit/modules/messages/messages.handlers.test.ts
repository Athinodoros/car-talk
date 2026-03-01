import { describe, it, expect, vi, beforeEach } from 'vitest';

const {
  mockSendMessage,
  mockGetInbox,
  mockGetSent,
  mockGetUnreadCount,
  mockGetMessageDetail,
  mockMarkAsRead,
  mockAddReply,
} = vi.hoisted(() => ({
  mockSendMessage: vi.fn(),
  mockGetInbox: vi.fn(),
  mockGetSent: vi.fn(),
  mockGetUnreadCount: vi.fn(),
  mockGetMessageDetail: vi.fn(),
  mockMarkAsRead: vi.fn(),
  mockAddReply: vi.fn(),
}));

vi.mock('../../../../src/modules/messages/messages.service.js', () => ({
  sendMessage: mockSendMessage,
  getInbox: mockGetInbox,
  getSent: mockGetSent,
  getUnreadCount: mockGetUnreadCount,
  getMessageDetail: mockGetMessageDetail,
  markAsRead: mockMarkAsRead,
  addReply: mockAddReply,
}));

import {
  sendMessageHandler,
  getInboxHandler,
  getSentHandler,
  getUnreadCountHandler,
  getMessageDetailHandler,
  markAsReadHandler,
  addReplyHandler,
} from '../../../../src/modules/messages/messages.handlers.js';

function createMockReply() {
  const reply = {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
  return reply;
}

describe('sendMessageHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse body and call sendMessage, returning 201', async () => {
    const body = { plateNumber: 'ABC1234', body: 'Hello' };
    const msg = { id: 'msg-1' };
    mockSendMessage.mockResolvedValue(msg);

    const request = { body, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await sendMessageHandler(request, reply as any);

    expect(mockSendMessage).toHaveBeenCalledWith(request.server, 'u1', body);
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith({ message: msg });
  });
});

describe('getInboxHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse query and call getInbox', async () => {
    const result = { messages: [], nextCursor: null };
    mockGetInbox.mockResolvedValue(result);

    const request = { query: {}, user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await getInboxHandler(request, reply as any);

    expect(mockGetInbox).toHaveBeenCalledWith('u1', undefined, 20);
    expect(reply.send).toHaveBeenCalledWith(result);
  });
});

describe('getSentHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse query and call getSent', async () => {
    const result = { messages: [], nextCursor: null };
    mockGetSent.mockResolvedValue(result);

    const request = { query: {}, user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await getSentHandler(request, reply as any);

    expect(mockGetSent).toHaveBeenCalledWith('u1', undefined, 20);
    expect(reply.send).toHaveBeenCalledWith(result);
  });
});

describe('getUnreadCountHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call getUnreadCount and return count', async () => {
    mockGetUnreadCount.mockResolvedValue(5);

    const request = { user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await getUnreadCountHandler(request, reply as any);

    expect(mockGetUnreadCount).toHaveBeenCalledWith('u1');
    expect(reply.send).toHaveBeenCalledWith({ count: 5 });
  });
});

describe('getMessageDetailHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call getMessageDetail with params.id', async () => {
    const msg = { id: 'msg-1' };
    mockGetMessageDetail.mockResolvedValue(msg);

    const request = { params: { id: 'msg-1' }, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await getMessageDetailHandler(request, reply as any);

    expect(mockGetMessageDetail).toHaveBeenCalledWith(request.server, 'u1', 'msg-1');
    expect(reply.send).toHaveBeenCalledWith({ message: msg });
  });
});

describe('markAsReadHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call markAsRead with params.id', async () => {
    const result = { success: true };
    mockMarkAsRead.mockResolvedValue(result);

    const request = { params: { id: 'msg-1' }, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await markAsReadHandler(request, reply as any);

    expect(mockMarkAsRead).toHaveBeenCalledWith(request.server, 'u1', 'msg-1');
    expect(reply.send).toHaveBeenCalledWith(result);
  });
});

describe('addReplyHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse body and call addReply, returning 201', async () => {
    const replyData = { id: 'reply-1' };
    mockAddReply.mockResolvedValue(replyData);

    const request = { body: { body: 'Reply text' }, params: { id: 'msg-1' }, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await addReplyHandler(request, reply as any);

    expect(mockAddReply).toHaveBeenCalledWith(request.server, 'u1', 'msg-1', { body: 'Reply text' });
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith({ reply: replyData });
  });
});
