import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { FastifyInstance } from 'fastify';

// -------------------------------------------------------------------
// vi.hoisted() returns values available inside vi.mock factories
// -------------------------------------------------------------------
const { mockDbQuery, mockDbInsert } = vi.hoisted(() => ({
  mockDbQuery: {
    reports: { findFirst: vi.fn() },
  },
  mockDbInsert: vi.fn(),
}));

vi.mock('../../../../src/db/index.js', () => ({
  db: {
    query: mockDbQuery,
    insert: mockDbInsert,
  },
}));

import { createReport } from '../../../../src/modules/reports/reports.service.js';

// ---- Helpers ----

function createMockFastify(): FastifyInstance {
  return {
    httpErrors: {
      conflict: (msg: string) => {
        const err = new Error(msg) as Error & { statusCode: number };
        err.statusCode = 409;
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

describe('createReport', () => {
  let fastify: FastifyInstance;

  beforeEach(() => {
    vi.clearAllMocks();
    fastify = createMockFastify();
  });

  it('should create a report for a message (happy path)', async () => {
    mockDbQuery.reports.findFirst.mockResolvedValue(undefined);

    const newReport = {
      id: 'report-1',
      reporterId: 'user-1',
      reportedUserId: 'user-2',
      reportedMessageId: 'msg-1',
      reason: 'spam',
      description: 'This is spam',
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-1', {
      reportedUserId: 'user-2',
      reportedMessageId: 'msg-1',
      reason: 'spam',
      description: 'This is spam',
    });

    expect(result.id).toBe('report-1');
    expect(result.reporterId).toBe('user-1');
    expect(result.reason).toBe('spam');
    expect(mockDbQuery.reports.findFirst).toHaveBeenCalled();
    expect(mockDbInsert).toHaveBeenCalled();
  });

  it('should create a report for a user only (no message)', async () => {
    const newReport = {
      id: 'report-2',
      reporterId: 'user-1',
      reportedUserId: 'user-2',
      reportedMessageId: undefined,
      reason: 'harassment',
      description: null,
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-1', {
      reportedUserId: 'user-2',
      reason: 'harassment',
    });

    expect(result.id).toBe('report-2');
    expect(result.reason).toBe('harassment');
    // Should NOT check for duplicates when no reportedMessageId
    expect(mockDbQuery.reports.findFirst).not.toHaveBeenCalled();
  });

  it('should throw conflict for duplicate report on same message', async () => {
    const existingReport = {
      id: 'report-existing',
      reporterId: 'user-1',
      reportedMessageId: 'msg-1',
    };
    mockDbQuery.reports.findFirst.mockResolvedValue(existingReport);

    await expect(
      createReport(fastify, 'user-1', {
        reportedMessageId: 'msg-1',
        reason: 'spam',
      }),
    ).rejects.toThrow('You have already reported this message');
  });

  it('should allow same user to report different messages', async () => {
    mockDbQuery.reports.findFirst.mockResolvedValue(undefined);

    const newReport = {
      id: 'report-3',
      reporterId: 'user-1',
      reportedMessageId: 'msg-2',
      reason: 'other',
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-1', {
      reportedMessageId: 'msg-2',
      reason: 'other',
      description: 'Something else',
    });

    expect(result.id).toBe('report-3');
  });

  it('should allow different users to report the same message', async () => {
    mockDbQuery.reports.findFirst.mockResolvedValue(undefined);

    const newReport = {
      id: 'report-4',
      reporterId: 'user-2',
      reportedMessageId: 'msg-1',
      reason: 'spam',
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-2', {
      reportedMessageId: 'msg-1',
      reason: 'spam',
    });

    expect(result.id).toBe('report-4');
  });

  it('should include optional description in the report', async () => {
    mockDbQuery.reports.findFirst.mockResolvedValue(undefined);

    const newReport = {
      id: 'report-5',
      reporterId: 'user-1',
      reportedMessageId: 'msg-1',
      reason: 'other',
      description: 'Detailed description of the issue',
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-1', {
      reportedMessageId: 'msg-1',
      reason: 'other',
      description: 'Detailed description of the issue',
    });

    expect(result.description).toBe('Detailed description of the issue');
  });

  it('should handle report without description', async () => {
    mockDbQuery.reports.findFirst.mockResolvedValue(undefined);

    const newReport = {
      id: 'report-6',
      reporterId: 'user-1',
      reportedMessageId: 'msg-1',
      reason: 'fraudulent_plate',
      description: null,
      status: 'pending',
      createdAt: new Date(),
    };
    mockDbInsert.mockReturnValue(chainValuesReturning([newReport]));

    const result = await createReport(fastify, 'user-1', {
      reportedMessageId: 'msg-1',
      reason: 'fraudulent_plate',
    });

    expect(result.id).toBe('report-6');
    expect(result.description).toBeNull();
  });
});
