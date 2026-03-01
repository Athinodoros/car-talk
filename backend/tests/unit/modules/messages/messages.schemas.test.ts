import { describe, it, expect } from 'vitest';
import {
  sendMessageBodySchema,
  inboxQuerySchema,
  replyBodySchema,
} from '../../../../src/modules/messages/messages.schemas.js';

describe('sendMessageBodySchema', () => {
  const validBody = {
    plateNumber: 'ABC1234',
    body: 'Hello, your car lights are on!',
  };

  it('should accept valid message without subject', () => {
    const result = sendMessageBodySchema.safeParse(validBody);
    expect(result.success).toBe(true);
  });

  it('should accept valid message with subject', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, subject: 'Lights on' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.subject).toBe('Lights on');
    }
  });

  it('should reject empty plateNumber', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, plateNumber: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Plate number is required');
    }
  });

  it('should reject plateNumber longer than 20 chars', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, plateNumber: 'A'.repeat(21) });
    expect(result.success).toBe(false);
  });

  it('should reject empty body', () => {
    const result = sendMessageBodySchema.safeParse({ plateNumber: 'ABC1234', body: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Message body is required');
    }
  });

  it('should reject body longer than 2000 chars', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, body: 'a'.repeat(2001) });
    expect(result.success).toBe(false);
  });

  it('should accept body exactly 2000 chars', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, body: 'a'.repeat(2000) });
    expect(result.success).toBe(true);
  });

  it('should reject subject longer than 100 chars', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, subject: 'a'.repeat(101) });
    expect(result.success).toBe(false);
  });

  it('should accept subject exactly 100 chars', () => {
    const result = sendMessageBodySchema.safeParse({ ...validBody, subject: 'a'.repeat(100) });
    expect(result.success).toBe(true);
  });

  it('should reject missing plateNumber', () => {
    const result = sendMessageBodySchema.safeParse({ body: 'some text' });
    expect(result.success).toBe(false);
  });

  it('should reject missing body', () => {
    const result = sendMessageBodySchema.safeParse({ plateNumber: 'ABC1234' });
    expect(result.success).toBe(false);
  });
});

describe('inboxQuerySchema', () => {
  it('should accept empty object and apply defaults', () => {
    const result = inboxQuerySchema.safeParse({});
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.limit).toBe(20);
      expect(result.data.cursor).toBeUndefined();
    }
  });

  it('should accept valid cursor and limit', () => {
    const result = inboxQuerySchema.safeParse({ cursor: '2024-01-01T00:00:00.000Z', limit: 10 });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.limit).toBe(10);
      expect(result.data.cursor).toBe('2024-01-01T00:00:00.000Z');
    }
  });

  it('should coerce string limit to number', () => {
    const result = inboxQuerySchema.safeParse({ limit: '15' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.limit).toBe(15);
    }
  });

  it('should reject limit less than 1', () => {
    const result = inboxQuerySchema.safeParse({ limit: 0 });
    expect(result.success).toBe(false);
  });

  it('should reject limit greater than 50', () => {
    const result = inboxQuerySchema.safeParse({ limit: 51 });
    expect(result.success).toBe(false);
  });

  it('should accept limit of 1', () => {
    const result = inboxQuerySchema.safeParse({ limit: 1 });
    expect(result.success).toBe(true);
  });

  it('should accept limit of 50', () => {
    const result = inboxQuerySchema.safeParse({ limit: 50 });
    expect(result.success).toBe(true);
  });
});

describe('replyBodySchema', () => {
  it('should accept valid reply body', () => {
    const result = replyBodySchema.safeParse({ body: 'Thanks for the heads up!' });
    expect(result.success).toBe(true);
  });

  it('should reject empty body', () => {
    const result = replyBodySchema.safeParse({ body: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Reply body is required');
    }
  });

  it('should reject body longer than 2000 chars', () => {
    const result = replyBodySchema.safeParse({ body: 'a'.repeat(2001) });
    expect(result.success).toBe(false);
  });

  it('should accept body exactly 2000 chars', () => {
    const result = replyBodySchema.safeParse({ body: 'a'.repeat(2000) });
    expect(result.success).toBe(true);
  });

  it('should reject missing body', () => {
    const result = replyBodySchema.safeParse({});
    expect(result.success).toBe(false);
  });
});
