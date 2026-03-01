import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { buildApp, getMockDb, resetDbMocks, signTestToken, fakeUuid, fakeUuid2, type MockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('Messages routes', () => {
  let app: FastifyInstance;
  let authToken: string;
  let mockDb: MockDb;
  const userId = fakeUuid();
  const userEmail = 'alice@example.com';

  beforeAll(async () => {
    app = await buildApp();
    mockDb = getMockDb();
    authToken = signTestToken(app, { id: userId, email: userEmail });
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    resetDbMocks();
  });

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/messages — Send a message
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/messages', () => {
    const plateId = fakeUuid2();
    const messageId = '22222222-3333-4444-5555-666666666666';

    it('should send a message to a plate and return 201', async () => {
      const createdAt = new Date().toISOString();

      // Plate exists (unclaimed)
      mockDb.query.licensePlates.findFirst.mockResolvedValue({
        id: plateId,
        userId: null,
        plateNumber: 'ABC123',
      });

      const messageData = {
        id: messageId,
        senderId: userId,
        recipientPlateId: plateId,
        subject: 'Hey!',
        body: 'Your lights are on',
        isRead: false,
        createdAt,
        updatedAt: createdAt,
      };
      mockDb._setInsertResult([messageData]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'ABC123',
          subject: 'Hey!',
          body: 'Your lights are on',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.message).toBeDefined();
      expect(body.message.id).toBe(messageId);
      expect(body.message.body).toBe('Your lights are on');
    });

    it('should create the plate if it does not exist', async () => {
      const newPlateId = fakeUuid2();
      const createdAt = new Date().toISOString();

      // No existing plate
      mockDb.query.licensePlates.findFirst.mockResolvedValue(null);

      // First insert creates the plate, second creates the message
      let insertCall = 0;
      mockDb.insert.mockImplementation(() => {
        insertCall++;
        const chain = {
          values: vi.fn().mockReturnThis(),
          returning: vi.fn(),
        };
        if (insertCall === 1) {
          // Plate insert
          chain.returning.mockResolvedValue([
            { id: newPlateId, plateNumber: 'NEWPLATE', userId: null },
          ]);
        } else {
          // Message insert
          chain.returning.mockResolvedValue([
            {
              id: messageId,
              senderId: userId,
              recipientPlateId: newPlateId,
              subject: null,
              body: 'Test message',
              isRead: false,
              createdAt,
              updatedAt: createdAt,
            },
          ]);
        }
        return chain;
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'NEW PLATE',
          body: 'Test message',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.message).toBeDefined();
      expect(body.message.body).toBe('Test message');
    });

    it('should return 400 for missing body', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'ABC123',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing plateNumber', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: 'Hello there',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for empty message body', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'ABC123',
          body: '',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for overly long subject', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/messages',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'ABC123',
          subject: 'x'.repeat(101),
          body: 'Test',
        },
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/messages/inbox — Paginated inbox
  // ──────────────────────────────────────────────────────────────────────────
  describe('GET /api/messages/inbox', () => {
    it('should return inbox messages for the user', async () => {
      const plateId = fakeUuid2();

      // User has one plate
      mockDb.query.licensePlates.findMany.mockResolvedValue([{ id: plateId }]);

      // Select returns messages
      const inboxMessages = [
        {
          id: 'msg-1',
          senderId: 'sender-1',
          recipientPlateId: plateId,
          subject: 'Hello',
          body: 'World',
          isRead: false,
          createdAt: new Date('2024-01-01'),
          updatedAt: new Date('2024-01-01'),
          senderDisplayName: 'Bob',
        },
      ];
      mockDb._setSelectResult(inboxMessages);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/inbox',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.messages).toBeDefined();
      expect(Array.isArray(body.messages)).toBe(true);
      expect(body).toHaveProperty('nextCursor');
    });

    it('should return empty inbox when user has no plates', async () => {
      mockDb.query.licensePlates.findMany.mockResolvedValue([]);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/inbox',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.messages).toEqual([]);
      expect(body.nextCursor).toBeNull();
    });

    it('should support limit query parameter', async () => {
      mockDb.query.licensePlates.findMany.mockResolvedValue([{ id: fakeUuid2() }]);
      mockDb._setSelectResult([]);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/inbox?limit=5',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
    });

    it('should return 400 for limit exceeding max (50)', async () => {
      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/inbox?limit=100',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(400);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/messages/sent — Paginated sent messages
  // ──────────────────────────────────────────────────────────────────────────
  describe('GET /api/messages/sent', () => {
    it('should return sent messages for the user', async () => {
      const sentMessages = [
        {
          id: 'msg-1',
          senderId: userId,
          recipientPlateId: fakeUuid2(),
          subject: 'Greetings',
          body: 'Your tire is flat',
          isRead: true,
          createdAt: new Date('2024-01-01'),
          updatedAt: new Date('2024-01-01'),
          recipientPlateNumber: 'XYZ789',
        },
      ];
      mockDb._setSelectResult(sentMessages);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/sent',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.messages).toBeDefined();
      expect(Array.isArray(body.messages)).toBe(true);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/messages/unread-count
  // ──────────────────────────────────────────────────────────────────────────
  describe('GET /api/messages/unread-count', () => {
    it('should return unread count for the user', async () => {
      mockDb.query.licensePlates.findMany.mockResolvedValue([{ id: fakeUuid2() }]);
      mockDb._setSelectResult([{ value: 5 }]);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/unread-count',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.count).toBeDefined();
      expect(typeof body.count).toBe('number');
    });

    it('should return 0 when user has no plates', async () => {
      mockDb.query.licensePlates.findMany.mockResolvedValue([]);

      const response = await app.inject({
        method: 'GET',
        url: '/api/messages/unread-count',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.count).toBe(0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/messages/:id — Message detail
  // ──────────────────────────────────────────────────────────────────────────
  describe('GET /api/messages/:id', () => {
    const messageId = '22222222-3333-4444-5555-666666666666';

    it('should return message detail when user is the sender', async () => {
      const messageDetail = {
        id: messageId,
        senderId: userId,
        recipientPlateId: fakeUuid2(),
        subject: 'Hello',
        body: 'World',
        isRead: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        sender: { id: userId, displayName: 'Alice' },
        recipientPlate: { id: fakeUuid2(), plateNumber: 'XYZ789', userId: 'other-user' },
        replies: [],
      };

      mockDb.query.messages.findFirst.mockResolvedValue(messageDetail);

      const response = await app.inject({
        method: 'GET',
        url: `/api/messages/${messageId}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.message).toBeDefined();
      expect(body.message.id).toBe(messageId);
      expect(body.message.replies).toEqual([]);
    });

    it('should return message detail when user is the plate owner', async () => {
      const messageDetail = {
        id: messageId,
        senderId: 'other-sender',
        recipientPlateId: fakeUuid2(),
        subject: 'Hi',
        body: 'Check your car',
        isRead: false,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
        sender: { id: 'other-sender', displayName: 'Bob' },
        recipientPlate: { id: fakeUuid2(), plateNumber: 'ABC123', userId },
        replies: [],
      };

      mockDb.query.messages.findFirst.mockResolvedValue(messageDetail);

      const response = await app.inject({
        method: 'GET',
        url: `/api/messages/${messageId}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.message.id).toBe(messageId);
    });

    it('should return 404 when message does not exist', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue(null);

      const response = await app.inject({
        method: 'GET',
        url: `/api/messages/${messageId}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(404);
    });

    it('should return 403 when user is neither sender nor plate owner', async () => {
      const messageDetail = {
        id: messageId,
        senderId: 'some-other-sender',
        recipientPlateId: fakeUuid2(),
        subject: 'Hello',
        body: 'World',
        createdAt: new Date().toISOString(),
        sender: { id: 'some-other-sender', displayName: 'Charlie' },
        recipientPlate: { id: fakeUuid2(), plateNumber: 'ZZZ999', userId: 'yet-another-user' },
        replies: [],
      };

      mockDb.query.messages.findFirst.mockResolvedValue(messageDetail);

      const response = await app.inject({
        method: 'GET',
        url: `/api/messages/${messageId}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(403);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // PATCH /api/messages/:id/read — Mark as read
  // ──────────────────────────────────────────────────────────────────────────
  describe('PATCH /api/messages/:id/read', () => {
    const messageId = '22222222-3333-4444-5555-666666666666';

    it('should mark a message as read for the plate owner', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue({
        id: messageId,
        senderId: 'other-sender',
        recipientPlateId: fakeUuid2(),
        isRead: false,
        recipientPlate: { userId },
      });

      mockDb._setUpdateResult([]);

      const response = await app.inject({
        method: 'PATCH',
        url: `/api/messages/${messageId}/read`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.success).toBe(true);
    });

    it('should return 404 when message does not exist', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue(null);

      const response = await app.inject({
        method: 'PATCH',
        url: `/api/messages/${messageId}/read`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(404);
    });

    it('should return 403 when user is not the plate owner', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue({
        id: messageId,
        senderId: userId, // user is sender, not recipient
        recipientPlateId: fakeUuid2(),
        recipientPlate: { userId: 'other-owner' },
      });

      const response = await app.inject({
        method: 'PATCH',
        url: `/api/messages/${messageId}/read`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(403);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // POST /api/messages/:id/replies — Add a reply
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/messages/:id/replies', () => {
    const messageId = '22222222-3333-4444-5555-666666666666';
    const replyId = '33333333-4444-5555-6666-777777777777';

    it('should add a reply as the sender', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue({
        id: messageId,
        senderId: userId, // current user is sender
        recipientPlateId: fakeUuid2(),
        recipientPlate: { userId: 'plate-owner-id' },
      });

      const replyData = {
        id: replyId,
        messageId,
        senderId: userId,
        body: 'Thanks for letting me know!',
        createdAt: new Date().toISOString(),
      };
      mockDb._setInsertResult([replyData]);
      mockDb._setUpdateResult([]);

      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: 'Thanks for letting me know!',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.reply).toBeDefined();
      expect(body.reply.id).toBe(replyId);
      expect(body.reply.body).toBe('Thanks for letting me know!');
    });

    it('should add a reply as the plate owner', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue({
        id: messageId,
        senderId: 'other-sender',
        recipientPlateId: fakeUuid2(),
        recipientPlate: { userId }, // current user is plate owner
      });

      const replyData = {
        id: replyId,
        messageId,
        senderId: userId,
        body: 'Will do!',
        createdAt: new Date().toISOString(),
      };
      mockDb._setInsertResult([replyData]);
      mockDb._setUpdateResult([]);

      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: 'Will do!',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.reply).toBeDefined();
      expect(body.reply.body).toBe('Will do!');
    });

    it('should return 404 when message does not exist', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue(null);

      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: 'Reply text',
        },
      });

      expect(response.statusCode).toBe(404);
    });

    it('should return 403 when user has no access to the thread', async () => {
      mockDb.query.messages.findFirst.mockResolvedValue({
        id: messageId,
        senderId: 'someone-else',
        recipientPlateId: fakeUuid2(),
        recipientPlate: { userId: 'another-owner' },
      });

      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: 'I should not be able to reply',
        },
      });

      expect(response.statusCode).toBe(403);
    });

    it('should return 400 for empty reply body', async () => {
      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          body: '',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing reply body', async () => {
      const response = await app.inject({
        method: 'POST',
        url: `/api/messages/${messageId}/replies`,
        headers: { authorization: `Bearer ${authToken}` },
        payload: {},
      });

      expect(response.statusCode).toBe(400);
    });
  });
});
