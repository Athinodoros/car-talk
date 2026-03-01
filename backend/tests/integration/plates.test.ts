import { describe, it, expect, beforeAll, beforeEach, afterAll, vi } from 'vitest';
import { buildApp, getMockDb, resetDbMocks, signTestToken, fakeUuid, fakeUuid2, type MockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('Plates routes', () => {
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
  // POST /api/plates — Claim a plate
  // ──────────────────────────────────────────────────────────────────────────
  describe('POST /api/plates', () => {
    it('should claim a new plate and return 201', async () => {
      const plateId = fakeUuid2();
      const plateData = {
        id: plateId,
        userId,
        plateNumber: 'XYZ789',
        stateOrRegion: 'California',
        claimedAt: new Date().toISOString(),
        isActive: true,
        createdAt: new Date().toISOString(),
      };

      // No existing plate with this number
      mockDb.query.licensePlates.findFirst.mockResolvedValue(null);

      // insert().values(...).returning() returns the plate
      mockDb._setInsertResult([plateData]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'XYZ 789',
          stateOrRegion: 'California',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.plateNumber).toBe('XYZ789');
    });

    it('should return 409 if plate is already claimed by another user', async () => {
      mockDb.query.licensePlates.findFirst.mockResolvedValue({
        id: fakeUuid2(),
        userId: 'other-user-id',
        plateNumber: 'XYZ789',
      });

      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'XYZ789',
        },
      });

      expect(response.statusCode).toBe(409);
    });

    it('should claim an existing unclaimed plate', async () => {
      const plateId = fakeUuid2();
      const existingPlate = {
        id: plateId,
        userId: null, // unclaimed
        plateNumber: 'XYZ789',
      };

      mockDb.query.licensePlates.findFirst.mockResolvedValue(existingPlate);

      const updatedPlate = {
        ...existingPlate,
        userId,
        claimedAt: new Date().toISOString(),
        stateOrRegion: 'Texas',
      };
      mockDb._setUpdateResult([updatedPlate]);

      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: 'XYZ789',
          stateOrRegion: 'Texas',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = response.json();
      expect(body.userId).toBe(userId);
    });

    it('should return 400 for empty plateNumber', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {
          plateNumber: '',
        },
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 400 for missing plateNumber', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
        payload: {},
      });

      expect(response.statusCode).toBe(400);
    });

    it('should return 401 without auth token', async () => {
      const response = await app.inject({
        method: 'POST',
        url: '/api/plates',
        payload: { plateNumber: 'ABC123' },
      });

      expect(response.statusCode).toBe(401);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GET /api/plates — List user's plates
  // ──────────────────────────────────────────────────────────────────────────
  describe('GET /api/plates', () => {
    it('should return a list of plates for the authenticated user', async () => {
      const plates = [
        {
          id: fakeUuid(),
          userId,
          plateNumber: 'ABC123',
          stateOrRegion: 'CA',
          isActive: true,
          createdAt: new Date().toISOString(),
        },
        {
          id: fakeUuid2(),
          userId,
          plateNumber: 'XYZ789',
          stateOrRegion: 'TX',
          isActive: true,
          createdAt: new Date().toISOString(),
        },
      ];

      mockDb.query.licensePlates.findMany.mockResolvedValue(plates);

      const response = await app.inject({
        method: 'GET',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(Array.isArray(body)).toBe(true);
      expect(body).toHaveLength(2);
      expect(body[0].plateNumber).toBe('ABC123');
      expect(body[1].plateNumber).toBe('XYZ789');
    });

    it('should return an empty array if user has no plates', async () => {
      mockDb.query.licensePlates.findMany.mockResolvedValue([]);

      const response = await app.inject({
        method: 'GET',
        url: '/api/plates',
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body).toEqual([]);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE /api/plates/:id — Release a plate
  // ──────────────────────────────────────────────────────────────────────────
  describe('DELETE /api/plates/:id', () => {
    it('should release an owned plate and return the updated plate', async () => {
      const plateId = fakeUuid2();

      mockDb.query.licensePlates.findFirst.mockResolvedValue({
        id: plateId,
        userId,
        plateNumber: 'ABC123',
        isActive: true,
      });

      const releasedPlate = {
        id: plateId,
        userId: null,
        plateNumber: 'ABC123',
        isActive: false,
        claimedAt: null,
      };
      mockDb._setUpdateResult([releasedPlate]);

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/plates/${plateId}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(200);
      const body = response.json();
      expect(body.userId).toBeNull();
      expect(body.isActive).toBe(false);
    });

    it('should return 404 when plate does not exist', async () => {
      mockDb.query.licensePlates.findFirst.mockResolvedValue(null);

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/plates/${fakeUuid2()}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(404);
    });

    it('should return 403 when trying to release a plate owned by another user', async () => {
      mockDb.query.licensePlates.findFirst.mockResolvedValue({
        id: fakeUuid2(),
        userId: 'other-user-id',
        plateNumber: 'ABC123',
      });

      const response = await app.inject({
        method: 'DELETE',
        url: `/api/plates/${fakeUuid2()}`,
        headers: { authorization: `Bearer ${authToken}` },
      });

      expect(response.statusCode).toBe(403);
    });
  });
});
