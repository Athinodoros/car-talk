import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { buildApp, getMockDb, resetDbMocks, signTestToken, fakeUuid, fakeUuid2, type MockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('Devices / Notifications routes', () => {
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
  // POST /api/devices — Register FCM token
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/devices', () => {
    const deviceId = fakeUuid2();
    const fcmToken = 'fcm-token-abc123xyz';

    it('should register a new device token and return 201', async () => {
      // No existing token
      mockDb.query.deviceTokens.findFirst.mockResolvedValue(null);

      const deviceData = {
        id: deviceId,
        userId,
        token: fcmToken,
        platform: 'android',
        createdAt: new Date().toISOString(),
      };
      mockDb._setInsertResult([deviceData]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: fcmToken,
          platform: 'android',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.success).toBe(true);
      expect(body.device).toBeDefined();
      expect(body.device.token).toBe(fcmToken);
    });

    it('should return existing token if already registered', async () => {
      const existingDevice = {
        id: deviceId,
        userId,
        token: fcmToken,
        platform: 'ios',
        createdAt: new Date().toISOString(),
      };
      mockDb.query.deviceTokens.findFirst.mockResolvedValue(existingDevice);

      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: fcmToken,
          platform: 'ios',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.success).toBe(true);
      expect(body.device).toBeDefined();
    });

    it('should re-assign token to new user if token exists for different user', async () => {
      const existingDevice = {
        id: deviceId,
        userId: 'old-user-id',
        token: fcmToken,
        platform: 'android',
        createdAt: new Date().toISOString(),
      };
      mockDb.query.deviceTokens.findFirst.mockResolvedValue(existingDevice);

      mockDb.update.mockReturnValue({
        set: vi.fn().mockReturnValue({
          where: vi.fn().mockResolvedValue(undefined),
        }),
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: fcmToken,
          platform: 'android',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.success).toBe(true);
    });

    it('should return 400 for missing token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          platform: 'android',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing platform', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: fcmToken,
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for invalid platform value', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: fcmToken,
          platform: 'windows',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for empty token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          token: '',
          platform: 'ios',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 401 without auth token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/devices',
        payload: {
          token: fcmToken,
          platform: 'android',
        },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE /api/devices/:token — Remove FCM token
  // ──────────────────────────────────────────────────────────────────────────
  describe('DELETE /api/devices/:token', () => {
    const fcmToken = 'fcm-token-abc123xyz';

    it('should remove a device token and return success', async () => {
      mockDb.delete.mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      });

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/devices/${fcmToken}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.success).toBe(true);
    });

    it('should return 200 even if token did not exist (idempotent delete)', async () => {
      mockDb.delete.mockReturnValue({
        where: vi.fn().mockResolvedValue(undefined),
      });

      const response = await app.inject({
        method: 'DELETE',
        url: '/api/devices/nonexistent-token',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.success).toBe(true);
    });

    it('should return 401 without auth token', async () => {
      const response = await app.inject({
        method: 'DELETE',
        url: `/api/devices/${fcmToken}`,
      });

      expect(response.statusCode).toBe(401);
    });
  });
});
