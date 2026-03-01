import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockClaimPlate, mockListPlates, mockReleasePlate } = vi.hoisted(() => ({
  mockClaimPlate: vi.fn(),
  mockListPlates: vi.fn(),
  mockReleasePlate: vi.fn(),
}));

vi.mock('../../../../src/modules/plates/plates.service.js', () => ({
  claimPlate: mockClaimPlate,
  listPlates: mockListPlates,
  releasePlate: mockReleasePlate,
}));

import {
  claimPlateHandler,
  listPlatesHandler,
  releasePlateHandler,
} from '../../../../src/modules/plates/plates.handlers.js';

function createMockReply() {
  return {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
}

describe('claimPlateHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse body and call claimPlate, returning 201', async () => {
    const body = { plateNumber: 'ABC1234' };
    const plate = { id: 'plate-1', plateNumber: 'ABC1234' };
    mockClaimPlate.mockResolvedValue(plate);

    const request = { body, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await claimPlateHandler(request, reply as any);

    expect(mockClaimPlate).toHaveBeenCalledWith(request.server, 'u1', body);
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith(plate);
  });
});

describe('listPlatesHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call listPlates and send result', async () => {
    const plates = [{ id: 'plate-1' }];
    mockListPlates.mockResolvedValue(plates);

    const request = { user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await listPlatesHandler(request, reply as any);

    expect(mockListPlates).toHaveBeenCalledWith('u1');
    expect(reply.send).toHaveBeenCalledWith(plates);
  });
});

describe('releasePlateHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call releasePlate with params.id', async () => {
    const plate = { id: 'plate-1', userId: null };
    mockReleasePlate.mockResolvedValue(plate);

    const request = { params: { id: 'plate-1' }, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await releasePlateHandler(request, reply as any);

    expect(mockReleasePlate).toHaveBeenCalledWith(request.server, 'u1', 'plate-1');
    expect(reply.send).toHaveBeenCalledWith(plate);
  });
});
