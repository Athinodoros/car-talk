import { describe, it, expect, vi } from 'vitest';

vi.mock('../../../../src/middleware/auth.js', () => ({
  authenticate: vi.fn(),
}));

vi.mock('../../../../src/modules/reports/reports.handlers.js', () => ({
  createReportHandler: vi.fn(),
}));

import reportsRoutes from '../../../../src/modules/reports/reports.routes.js';

describe('reportsRoutes', () => {
  it('should register POST /api/reports with auth hook', async () => {
    const mockFastify = {
      post: vi.fn(),
      addHook: vi.fn(),
    };

    await reportsRoutes(mockFastify as any);

    expect(mockFastify.addHook).toHaveBeenCalledWith('onRequest', expect.any(Function));
    expect(mockFastify.post).toHaveBeenCalledWith('/api/reports', expect.any(Function));
  });
});
