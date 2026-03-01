import { describe, it, expect } from 'vitest';
import { registerBodySchema, loginBodySchema, refreshBodySchema } from '../../../../src/modules/auth/auth.schemas.js';

describe('registerBodySchema', () => {
  const validBody = {
    email: 'test@example.com',
    password: 'password123',
    displayName: 'Test User',
    plateNumber: 'ABC1234',
  };

  it('should accept valid registration data', () => {
    const result = registerBodySchema.safeParse(validBody);
    expect(result.success).toBe(true);
  });

  it('should accept valid data with optional stateOrRegion', () => {
    const result = registerBodySchema.safeParse({ ...validBody, stateOrRegion: 'CA' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.stateOrRegion).toBe('CA');
    }
  });

  it('should reject invalid email', () => {
    const result = registerBodySchema.safeParse({ ...validBody, email: 'not-an-email' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Invalid email address');
    }
  });

  it('should reject empty email', () => {
    const result = registerBodySchema.safeParse({ ...validBody, email: '' });
    expect(result.success).toBe(false);
  });

  it('should reject password shorter than 8 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, password: 'short' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Password must be at least 8 characters');
    }
  });

  it('should accept password exactly 8 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, password: '12345678' });
    expect(result.success).toBe(true);
  });

  it('should reject empty displayName', () => {
    const result = registerBodySchema.safeParse({ ...validBody, displayName: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Display name is required');
    }
  });

  it('should reject displayName longer than 100 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, displayName: 'a'.repeat(101) });
    expect(result.success).toBe(false);
  });

  it('should accept displayName exactly 100 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, displayName: 'a'.repeat(100) });
    expect(result.success).toBe(true);
  });

  it('should reject empty plateNumber', () => {
    const result = registerBodySchema.safeParse({ ...validBody, plateNumber: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Plate number is required');
    }
  });

  it('should reject plateNumber longer than 20 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, plateNumber: 'A'.repeat(21) });
    expect(result.success).toBe(false);
  });

  it('should reject missing required fields', () => {
    const result = registerBodySchema.safeParse({});
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.length).toBeGreaterThanOrEqual(4);
    }
  });

  it('should reject stateOrRegion longer than 50 characters', () => {
    const result = registerBodySchema.safeParse({ ...validBody, stateOrRegion: 'a'.repeat(51) });
    expect(result.success).toBe(false);
  });

  it('should strip extra properties', () => {
    const result = registerBodySchema.safeParse({ ...validBody, extra: 'field' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect((result.data as Record<string, unknown>)['extra']).toBeUndefined();
    }
  });
});

describe('loginBodySchema', () => {
  const validBody = {
    email: 'test@example.com',
    password: 'anypassword',
  };

  it('should accept valid login data', () => {
    const result = loginBodySchema.safeParse(validBody);
    expect(result.success).toBe(true);
  });

  it('should reject invalid email', () => {
    const result = loginBodySchema.safeParse({ ...validBody, email: 'bad-email' });
    expect(result.success).toBe(false);
  });

  it('should reject empty password', () => {
    const result = loginBodySchema.safeParse({ ...validBody, password: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Password is required');
    }
  });

  it('should reject missing email', () => {
    const result = loginBodySchema.safeParse({ password: 'password123' });
    expect(result.success).toBe(false);
  });

  it('should reject missing password', () => {
    const result = loginBodySchema.safeParse({ email: 'test@example.com' });
    expect(result.success).toBe(false);
  });

  it('should accept any length password (no min length beyond 1)', () => {
    const result = loginBodySchema.safeParse({ ...validBody, password: 'a' });
    expect(result.success).toBe(true);
  });
});

describe('refreshBodySchema', () => {
  it('should accept valid refresh token', () => {
    const result = refreshBodySchema.safeParse({ refreshToken: 'some.jwt.token' });
    expect(result.success).toBe(true);
  });

  it('should reject empty refresh token', () => {
    const result = refreshBodySchema.safeParse({ refreshToken: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Refresh token is required');
    }
  });

  it('should reject missing refresh token', () => {
    const result = refreshBodySchema.safeParse({});
    expect(result.success).toBe(false);
  });
});
