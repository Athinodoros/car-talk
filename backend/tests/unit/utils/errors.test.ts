import { describe, it, expect, vi } from 'vitest';
import { createHttpError } from '../../../src/utils/errors.js';

describe('createHttpError', () => {
  it('should call fastify.httpErrors.createError with statusCode and message', () => {
    const mockError = new Error('Not Found');
    const mockFastify = {
      httpErrors: {
        createError: vi.fn().mockReturnValue(mockError),
      },
    } as any;

    const result = createHttpError(mockFastify, 404, 'Not Found');

    expect(mockFastify.httpErrors.createError).toHaveBeenCalledWith(404, 'Not Found');
    expect(result).toBe(mockError);
  });
});
