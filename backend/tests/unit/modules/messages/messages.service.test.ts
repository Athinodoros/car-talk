import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';

// -------------------------------------------------------------------
// vi.hoisted() returns values available inside vi.mock factories
// -------------------------------------------------------------------
const { mockDbQuery, mockDbInsert, mockDbUpdate, mockDbSelect, mockSocketService } = vi.hoisted(() => ({
  mockDbQuery: {
    licensePlates: { findFirst: vi.fn(), findMany: vi.fn() },
    messages: { findFirst: vi.fn() },
  },
  mockDbInsert: vi.fn(),
  mockDbUpdate: vi.fn(),
  mockDbSelect: vi.fn(),
  mockSocketService: {
    emitToUser: vi.fn(),
  },
}));

vi.mock('../../../../src/db/index.js', () => ({
  db: {
    query: mockDbQuery,
    insert: mockDbInsert,
    update: mockDbUpdate,
    select: mockDbSelect,
  },
}));

vi.mock('../../../../src/socket/socket-service.js', () => ({
  socketService: mockSocketService,
}));

vi.mock('../../../../src/modules/notifications/notifications.service.js', () => ({
  sendPushNotification: vi.fn().mockResolvedValue(undefined),
}));

import {
  sendMessage,
  getInbox,
  getMessageDetail,
  markAsRead,
  addReply,
  getUnreadCount,
  getSent,
} from '../../../../src/modules/messages/messages.service.js';

// ---- Helpers ----

function createMockFastify(): FastifyInstance {
  return {
    httpErrors: {
      notFound: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 404;
        return err;
      },
      forbidden: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 403;
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

describe('sendMessage', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should send a message to an existing plate (happy path)', async () => {
    const plate = { id: 'plate-1', plateNumber: 'ABC1234', userId: 'owner-1' };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(plate);

    const newMessage = {
      id: 'msg-1',
      senderId: 'sender-1',
      recipientPlateId: 'plate-1',
      subject: 'Hi',
      body: 'Your lights are on',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newMessage]));

    // getUserPlateIds for unread count
    mockDbQuery.licensePlates.findMany.mockResolvedValue([{ id: 'plate-1' }]);
    // getUnreadCountByPlateIds
    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue([{ value: 3 }]),
      }),
    });

    const result = await sendMessage(fastify, 'sender-1', {
      plateNumber: 'ABC-1234',
      subject: 'Hi',
      body: 'Your lights are on',
    });

    expect(result.id).toBe('msg-1');
    expect(mockDbQuery.licensePlates.findFirst).toHaveBeenCalled();
    expect(mockDbInsert).toHaveBeenCalled();
    // Should emit real-time events to the plate owner
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith('owner-1', 'new_message', { message: newMessage });
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith('owner-1', 'unread_count', { count: 3 });
  });

  it('should create new plate if plate does not exist', async () => {
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    const newPlate = { id: 'plate-new', plateNumber: 'XYZ9999', userId: null };
    const newMessage = {
      id: 'msg-2',
      senderId: 'sender-1',
      recipientPlateId: 'plate-new',
      subject: undefined,
      body: 'Hello there',
      createdAt: new Date(),
    };

    // First insert call = create plate, second = create message
    mockDbInsert
      .mockReturnValueOnce(chainValuesReturning([newPlate]))
      .mockReturnValueOnce(chainValuesReturning([newMessage]));

    const result = await sendMessage(fastify, 'sender-1', {
      plateNumber: 'XYZ-9999',
      body: 'Hello there',
    });

    expect(result.id).toBe('msg-2');
    // Two inserts: plate + message
    expect(mockDbInsert).toHaveBeenCalledTimes(2);
    // No socket emit since userId is null (unclaimed plate)
    expect(mockSocketService.emitToUser).not.toHaveBeenCalled();
  });

  it('should not emit socket events for unclaimed plate', async () => {
    const plate = { id: 'plate-1', plateNumber: 'ABC1234', userId: null };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(plate);

    const newMessage = { id: 'msg-3', senderId: 'sender-1', recipientPlateId: 'plate-1', body: 'Test' };
    mockDbInsert.mockReturnValue(chainValuesReturning([newMessage]));

    await sendMessage(fastify, 'sender-1', { plateNumber: 'ABC1234', body: 'Test' });

    expect(mockSocketService.emitToUser).not.toHaveBeenCalled();
  });
});

describe('getInbox', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return empty when user has no plates', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([]);

    const result = await getInbox('user-1');
    expect(result.messages).toEqual([]);
    expect(result.nextCursor).toBeNull();
  });

  it('should return paginated inbox messages', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([{ id: 'plate-1' }]);

    const now = new Date();
    const mockMessages = Array.from({ length: 3 }, (_, i) => ({
      id: `msg-${i}`,
      senderId: `sender-${i}`,
      recipientPlateId: 'plate-1',
      subject: `Subject ${i}`,
      body: `Body ${i}`,
      isRead: false,
      createdAt: new Date(now.getTime() - i * 1000),
      updatedAt: now,
      senderDisplayName: `User ${i}`,
    }));

    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        innerJoin: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue(mockMessages),
            }),
          }),
        }),
      }),
    });

    const result = await getInbox('user-1', undefined, 20);

    expect(result.messages).toHaveLength(3);
    expect(result.nextCursor).toBeNull();
  });

  it('should return nextCursor when there are more messages', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([{ id: 'plate-1' }]);

    const now = new Date();
    const mockMessages = Array.from({ length: 3 }, (_, i) => ({
      id: `msg-${i}`,
      senderId: `sender-${i}`,
      recipientPlateId: 'plate-1',
      subject: `Subject ${i}`,
      body: `Body ${i}`,
      isRead: false,
      createdAt: new Date(now.getTime() - i * 1000),
      updatedAt: now,
      senderDisplayName: `User ${i}`,
    }));

    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        innerJoin: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue(mockMessages),
            }),
          }),
        }),
      }),
    });

    const result = await getInbox('user-1', undefined, 2);

    expect(result.messages).toHaveLength(2);
    expect(result.nextCursor).not.toBeNull();
    expect(result.nextCursor).toBe(result.messages[1].createdAt.toISOString());
  });

  it('should pass cursor for pagination', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([{ id: 'plate-1' }]);

    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        innerJoin: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue([]),
            }),
          }),
        }),
      }),
    });

    const result = await getInbox('user-1', '2024-01-01T00:00:00.000Z', 20);
    expect(result.messages).toEqual([]);
    expect(result.nextCursor).toBeNull();
  });
});

describe('getSent', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return sent messages for user', async () => {
    const now = new Date();
    const mockMessages = [
      {
        id: 'msg-1',
        senderId: 'user-1',
        recipientPlateId: 'plate-1',
        subject: 'Hi',
        body: 'Hello',
        isRead: false,
        createdAt: now,
        updatedAt: now,
        recipientPlateNumber: 'ABC1234',
      },
    ];

    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        innerJoin: vi.fn().mockReturnValue({
          where: vi.fn().mockReturnValue({
            orderBy: vi.fn().mockReturnValue({
              limit: vi.fn().mockResolvedValue(mockMessages),
            }),
          }),
        }),
      }),
    });

    const result = await getSent('user-1');
    expect(result.messages).toHaveLength(1);
    expect(result.messages[0].id).toBe('msg-1');
  });
});

describe('getUnreadCount', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return 0 when user has no plates', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([]);
    const result = await getUnreadCount('user-1');
    expect(result).toBe(0);
  });

  it('should return unread count for user plates', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([{ id: 'plate-1' }, { id: 'plate-2' }]);
    mockDbSelect.mockReturnValue({
      from: vi.fn().mockReturnValue({
        where: vi.fn().mockResolvedValue([{ value: 5 }]),
      }),
    });

    const result = await getUnreadCount('user-1');
    expect(result).toBe(5);
  });
});

describe('getMessageDetail', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should return message detail when user is the sender', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'user-1',
      body: 'Hello',
      recipientPlate: { id: 'plate-1', plateNumber: 'ABC1234', userId: 'other-user' },
      sender: { id: 'user-1', displayName: 'Sender' },
      replies: [],
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    const result = await getMessageDetail(fastify, 'user-1', 'msg-1');
    expect(result.id).toBe('msg-1');
  });

  it('should return message detail when user is the plate owner (recipient)', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'other-user',
      body: 'Hello',
      recipientPlate: { id: 'plate-1', plateNumber: 'ABC1234', userId: 'user-1' },
      sender: { id: 'other-user', displayName: 'Other' },
      replies: [],
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    const result = await getMessageDetail(fastify, 'user-1', 'msg-1');
    expect(result.id).toBe('msg-1');
  });

  it('should throw notFound when message does not exist', async () => {
    mockDbQuery.messages.findFirst.mockResolvedValue(undefined);

    await expect(getMessageDetail(fastify, 'user-1', 'nonexistent')).rejects.toThrow('Message not found');
  });

  it('should throw forbidden when user is neither sender nor recipient', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'other-user',
      body: 'Hello',
      recipientPlate: { id: 'plate-1', plateNumber: 'ABC1234', userId: 'another-user' },
      sender: { id: 'other-user', displayName: 'Other' },
      replies: [],
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    await expect(getMessageDetail(fastify, 'user-1', 'msg-1')).rejects.toThrow(
      'You do not have access to this message',
    );
  });
});

describe('markAsRead', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should mark message as read by recipient', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'sender-1',
      recipientPlate: { userId: 'user-1' },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);
    mockDbUpdate.mockReturnValue(chainSetWhere());

    const result = await markAsRead(fastify, 'user-1', 'msg-1');
    expect(result.success).toBe(true);
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith('sender-1', 'message_read', { messageId: 'msg-1' });
  });

  it('should throw notFound if message does not exist', async () => {
    mockDbQuery.messages.findFirst.mockResolvedValue(undefined);

    await expect(markAsRead(fastify, 'user-1', 'nonexistent')).rejects.toThrow('Message not found');
  });

  it('should throw forbidden if user is not the recipient', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'sender-1',
      recipientPlate: { userId: 'other-user' },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    await expect(markAsRead(fastify, 'user-1', 'msg-1')).rejects.toThrow(
      'Only the recipient can mark as read',
    );
  });
});

describe('addReply', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should add reply when user is the sender', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'user-1',
      recipientPlate: { userId: 'owner-1' },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    const newReply = { id: 'reply-1', messageId: 'msg-1', senderId: 'user-1', body: 'Reply text' };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReply]));
    mockDbUpdate.mockReturnValue(chainSetWhere());

    const result = await addReply(fastify, 'user-1', 'msg-1', { body: 'Reply text' });

    expect(result.id).toBe('reply-1');
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith('owner-1', 'new_reply', {
      messageId: 'msg-1',
      reply: newReply,
    });
  });

  it('should add reply when user is the recipient (plate owner)', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'sender-1',
      recipientPlate: { userId: 'user-1' },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    const newReply = { id: 'reply-2', messageId: 'msg-1', senderId: 'user-1', body: 'Thanks!' };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReply]));
    mockDbUpdate.mockReturnValue(chainSetWhere());

    const result = await addReply(fastify, 'user-1', 'msg-1', { body: 'Thanks!' });

    expect(result.id).toBe('reply-2');
    expect(mockSocketService.emitToUser).toHaveBeenCalledWith('sender-1', 'new_reply', {
      messageId: 'msg-1',
      reply: newReply,
    });
  });

  it('should throw notFound if message does not exist', async () => {
    mockDbQuery.messages.findFirst.mockResolvedValue(undefined);

    await expect(addReply(fastify, 'user-1', 'nonexistent', { body: 'test' })).rejects.toThrow(
      'Message not found',
    );
  });

  it('should throw forbidden if user is neither sender nor recipient', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'other-user',
      recipientPlate: { userId: 'another-user' },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    await expect(addReply(fastify, 'user-1', 'msg-1', { body: 'test' })).rejects.toThrow(
      'You do not have access to this thread',
    );
  });

  it('should handle null recipient plate userId (no notification emitted)', async () => {
    const message = {
      id: 'msg-1',
      senderId: 'user-1',
      recipientPlate: { userId: null },
    };
    mockDbQuery.messages.findFirst.mockResolvedValue(message);

    const newReply = { id: 'reply-3', messageId: 'msg-1', senderId: 'user-1', body: 'Reply' };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReply]));
    mockDbUpdate.mockReturnValue(chainSetWhere());

    const result = await addReply(fastify, 'user-1', 'msg-1', { body: 'Reply' });
    expect(result.id).toBe('reply-3');
    expect(mockSocketService.emitToUser).not.toHaveBeenCalled();
  });
});
