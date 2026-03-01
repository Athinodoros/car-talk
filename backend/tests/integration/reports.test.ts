import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { buildApp, getMockDb, resetDbMocks, signTestToken, fakeUuid, fakeUuid2, type MockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('Reports routes', () => {
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
  // POST /api/reports — Create a report
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/reports', () => {
    const reportId = '44444444-5555-6666-7777-888888888888';

    it('should create a report for a message and return 201', async () => {
      const reportedMessageId = fakeUuid2();

      // No existing report for this message
      mockDb.query.reports.findFirst.mockResolvedValue(null);

      const reportData = {
        id: reportId,
        reporterId: userId,
        reportedUserId: null,
        reportedMessageId,
        reason: 'spam',
        description: 'This is a spam message',
        status: 'pending',
        createdAt: new Date().toISOString(),
      };
      mockDb._setInsertResult([reportData]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reportedMessageId,
          reason: 'spam',
          description: 'This is a spam message',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.report).toBeDefined();
      expect(body.report.id).toBe(reportId);
      expect(body.report.reason).toBe('spam');
      expect(body.report.status).toBe('pending');
    });

    it('should create a report for a user', async () => {
      const reportedUserId = fakeUuid2();

      const reportData = {
        id: reportId,
        reporterId: userId,
        reportedUserId,
        reportedMessageId: null,
        reason: 'harassment',
        description: null,
        status: 'pending',
        createdAt: new Date().toISOString(),
      };
      mockDb._setInsertResult([reportData]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reportedUserId,
          reason: 'harassment',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.report).toBeDefined();
      expect(body.report.reason).toBe('harassment');
    });

    it('should return 409 when duplicate report on same message', async () => {
      const reportedMessageId = fakeUuid2();

      mockDb.query.reports.findFirst.mockResolvedValue({
        id: reportId,
        reporterId: userId,
        reportedMessageId,
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reportedMessageId,
          reason: 'spam',
        },
      });

      expect(response.statusCode).toBe(409);
    });

    it('should return 400 when neither reportedMessageId nor reportedUserId is provided', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reason: 'spam',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for invalid reason', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reportedUserId: fakeUuid2(),
          reason: 'invalid_reason_type',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing reason', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          reportedUserId: fakeUuid2(),
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should accept all valid reason types', async () => {
      const reasons = ['spam', 'harassment', 'fraudulent_plate', 'other'];

      for (const reason of reasons) {
        resetDbMocks();
        mockDb.query.reports.findFirst.mockResolvedValue(null);

        const reportData = {
          id: reportId,
          reporterId: userId,
          reportedUserId: fakeUuid2(),
          reason,
          status: 'pending',
          createdAt: new Date().toISOString(),
        };
        mockDb._setInsertResult([reportData]);

        const response = await app.inject({
          method: 'POST',
          url: '/api/reports',
          headers: { authorization: `Bearer ${authToken}` },
          payload: {
            reportedUserId: fakeUuid2(),
            reason,
          },
        });

        expect(response.statusCode).toBe(201);
      }
    });

    it('should return 401 without auth token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/reports',
        payload: {
          reportedUserId: fakeUuid2(),
          reason: 'spam',
        },
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
