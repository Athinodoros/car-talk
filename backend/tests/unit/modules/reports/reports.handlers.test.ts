import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockCreateReport } = vi.hoisted(() => ({
  mockCreateReport: vi.fn(),
}));

vi.mock('../../../../src/modules/reports/reports.service.js', () => ({
  createReport: mockCreateReport,
}));

import { createReportHandler } from '../../../../src/modules/reports/reports.handlers.js';

function createMockReply() {
  return {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
}

describe('createReportHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse body and call createReport, returning 201', async () => {
    const body = {
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
    };
    const report = { id: 'report-1', reason: 'spam' };
    mockCreateReport.mockResolvedValue(report);

    const request = { body, user: { id: 'u1' }, server: {} } as any;
    const reply = createMockReply();

    await createReportHandler(request, reply as any);

    expect(mockCreateReport).toHaveBeenCalledWith(request.server, 'u1', body);
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith({ report });
  });
});
