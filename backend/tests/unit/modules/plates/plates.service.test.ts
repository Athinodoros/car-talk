import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';

// -------------------------------------------------------------------
// vi.hoisted() returns values available inside vi.mock factories
// -------------------------------------------------------------------
const { mockDbQuery, mockDbInsert, mockDbUpdate } = vi.hoisted(() => ({
  mockDbQuery: {
    licensePlates: { findFirst: vi.fn(), findMany: vi.fn() },
  },
  mockDbInsert: vi.fn(),
  mockDbUpdate: vi.fn(),
}));

vi.mock('../../../../src/db/index.js', () => ({
  db: {
    query: mockDbQuery,
    insert: mockDbInsert,
    update: mockDbUpdate,
  },
}));

import { claimPlate, listPlates, releasePlate } from '../../../../src/modules/plates/plates.service.js';

// ---- Helpers ----

function createMockFastify(): FastifyInstance {
  return {
    httpErrors: {
      conflict: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 409;
        return err;
      },
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

function chainSetWhereReturning(data: unknown[] = []) {
  return {
    set: vi.fn().mockReturnValue({
      where: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue(data),
      }),
    }),
  };
}

describe('claimPlate', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should create and claim a new plate (happy path)', async () => {
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    const newPlate = {
      id: 'plate-1',
      userId: 'user-1',
      plateNumber: 'ABC1234',
      stateOrRegion: 'CA',
      claimedAt: new Date(),
      isActive: true,
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newPlate]));

    const result = await claimPlate(fastify, 'user-1', { plateNumber: 'ABC-1234', stateOrRegion: 'CA' });

    expect(result.id).toBe('plate-1');
    expect(result.userId).toBe('user-1');
    expect(result.plateNumber).toBe('ABC1234');
    expect(mockDbInsert).toHaveBeenCalled();
  });

  it('should claim an existing unclaimed plate', async () => {
    const existingPlate = {
      id: 'plate-1',
      userId: null,
      plateNumber: 'ABC1234',
      isActive: true,
    };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(existingPlate);

    const updatedPlate = {
      ...existingPlate,
      userId: 'user-1',
      stateOrRegion: 'NY',
      claimedAt: new Date(),
    };
    mockDbUpdate.mockReturnValue(chainSetWhereReturning([updatedPlate]));

    const result = await claimPlate(fastify, 'user-1', { plateNumber: 'ABC1234', stateOrRegion: 'NY' });

    expect(result.userId).toBe('user-1');
    expect(mockDbUpdate).toHaveBeenCalled();
    expect(mockDbInsert).not.toHaveBeenCalled();
  });

  it('should throw conflict when plate is already claimed by another user', async () => {
    const existingPlate = {
      id: 'plate-1',
      userId: 'other-user',
      plateNumber: 'ABC1234',
      isActive: true,
    };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(existingPlate);

    await expect(
      claimPlate(fastify, 'user-1', { plateNumber: 'ABC1234' }),
    ).rejects.toThrow('License plate already claimed');
  });

  it('should normalize plate number before lookup', async () => {
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    const newPlate = {
      id: 'plate-1',
      userId: 'user-1',
      plateNumber: 'ABC1234',
      claimedAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newPlate]));

    await claimPlate(fastify, 'user-1', { plateNumber: 'abc - 1234' });

    expect(mockDbInsert).toHaveBeenCalled();
  });

  it('should handle claiming without stateOrRegion', async () => {
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    const newPlate = {
      id: 'plate-1',
      userId: 'user-1',
      plateNumber: 'XYZ9999',
      claimedAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newPlate]));

    const result = await claimPlate(fastify, 'user-1', { plateNumber: 'XYZ9999' });
    expect(result.id).toBe('plate-1');
  });
});

describe('listPlates', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('should return plates belonging to the user', async () => {
    const plates = [
      { id: 'plate-1', userId: 'user-1', plateNumber: 'ABC1234', isActive: true },
      { id: 'plate-2', userId: 'user-1', plateNumber: 'XYZ5678', isActive: true },
    ];
    mockDbQuery.licensePlates.findMany.mockResolvedValue(plates);

    const result = await listPlates('user-1');
    expect(result).toHaveLength(2);
    expect(result[0].plateNumber).toBe('ABC1234');
    expect(result[1].plateNumber).toBe('XYZ5678');
  });

  it('should return empty array when user has no plates', async () => {
    mockDbQuery.licensePlates.findMany.mockResolvedValue([]);

    const result = await listPlates('user-1');
    expect(result).toEqual([]);
  });
});

describe('releasePlate', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should release own plate (happy path)', async () => {
    const plate = { id: 'plate-1', userId: 'user-1', plateNumber: 'ABC1234', isActive: true };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(plate);

    const releasedPlate = { ...plate, userId: null, claimedAt: null, isActive: false };
    mockDbUpdate.mockReturnValue(chainSetWhereReturning([releasedPlate]));

    const result = await releasePlate(fastify, 'user-1', 'plate-1');

    expect(result.userId).toBeNull();
    expect(result.isActive).toBe(false);
    expect(mockDbUpdate).toHaveBeenCalled();
  });

  it('should throw notFound when plate does not exist', async () => {
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(undefined);

    await expect(releasePlate(fastify, 'user-1', 'nonexistent')).rejects.toThrow('Plate not found');
  });

  it('should throw forbidden when trying to release another user\'s plate', async () => {
    const plate = { id: 'plate-1', userId: 'other-user', plateNumber: 'ABC1234', isActive: true };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(plate);

    await expect(releasePlate(fastify, 'user-1', 'plate-1')).rejects.toThrow('You do not own this plate');
  });

  it('should set userId to null, claimedAt to null, and isActive to false', async () => {
    const plate = { id: 'plate-1', userId: 'user-1', plateNumber: 'ABC1234', isActive: true };
    mockDbQuery.licensePlates.findFirst.mockResolvedValue(plate);

    const mockSet = vi.fn().mockReturnValue({
      where: vi.fn().mockReturnValue({
        returning: vi.fn().mockResolvedValue([{ ...plate, userId: null, claimedAt: null, isActive: false }]),
      }),
    });
    mockDbUpdate.mockReturnValue({ set: mockSet });

    await releasePlate(fastify, 'user-1', 'plate-1');

    expect(mockSet).toHaveBeenCalledWith({ userId: null, claimedAt: null, isActive: false });
  });
});
