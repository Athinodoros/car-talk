import { describe, it, expect } from 'vitest';
import { createReportBodySchema } from '../../../../src/modules/reports/reports.schemas.js';

describe('createReportBodySchema', () => {
  it('should accept valid report with reportedMessageId', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
    });
    expect(result.success).toBe(true);
  });

  it('should accept valid report with reportedUserId', () => {
    const result = createReportBodySchema.safeParse({
      reportedUserId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'harassment',
    });
    expect(result.success).toBe(true);
  });

  it('should accept report with both reportedMessageId and reportedUserId', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reportedUserId: '660e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
      description: 'This is spam content',
    });
    expect(result.success).toBe(true);
  });

  it('should reject when neither reportedMessageId nor reportedUserId is provided', () => {
    const result = createReportBodySchema.safeParse({
      reason: 'spam',
    });
    expect(result.success).toBe(false);
    if (!result.success) {
      const messages = result.error.issues.map((i) => i.message);
      expect(messages).toContain('Must provide either reportedMessageId or reportedUserId');
    }
  });

  it('should reject invalid reason', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'invalid_reason',
    });
    expect(result.success).toBe(false);
  });

  it('should accept all valid reason values', () => {
    const validReasons = ['spam', 'harassment', 'fraudulent_plate', 'other'];
    for (const reason of validReasons) {
      const result = createReportBodySchema.safeParse({
        reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
        reason,
      });
      expect(result.success).toBe(true);
    }
  });

  it('should accept optional description', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
      description: 'Detailed description',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.description).toBe('Detailed description');
    }
  });

  it('should reject description longer than 1000 chars', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
      description: 'a'.repeat(1001),
    });
    expect(result.success).toBe(false);
  });

  it('should accept description exactly 1000 chars', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
      reason: 'spam',
      description: 'a'.repeat(1000),
    });
    expect(result.success).toBe(true);
  });

  it('should reject invalid UUID for reportedMessageId', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: 'not-a-uuid',
      reason: 'spam',
    });
    expect(result.success).toBe(false);
  });

  it('should reject invalid UUID for reportedUserId', () => {
    const result = createReportBodySchema.safeParse({
      reportedUserId: 'not-a-uuid',
      reason: 'spam',
    });
    expect(result.success).toBe(false);
  });

  it('should reject missing reason', () => {
    const result = createReportBodySchema.safeParse({
      reportedMessageId: '550e8400-e29b-41d4-a716-446655440000',
    });
    expect(result.success).toBe(false);
  });
});
