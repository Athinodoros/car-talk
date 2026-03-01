import { describe, it, expect } from 'vitest';
import { claimPlateBodySchema } from '../../../../src/modules/plates/plates.schemas.js';

describe('claimPlateBodySchema', () => {
  it('should accept valid plate number', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'ABC1234' });
    expect(result.success).toBe(true);
  });

  it('should accept valid plate number with stateOrRegion', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'ABC1234', stateOrRegion: 'CA' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.stateOrRegion).toBe('CA');
    }
  });

  it('should reject empty plateNumber', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: '' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Plate number is required');
    }
  });

  it('should reject plateNumber longer than 20 characters', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'A'.repeat(21) });
    expect(result.success).toBe(false);
  });

  it('should accept plateNumber exactly 20 characters', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'A'.repeat(20) });
    expect(result.success).toBe(true);
  });

  it('should accept plateNumber exactly 1 character', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'A' });
    expect(result.success).toBe(true);
  });

  it('should reject missing plateNumber', () => {
    const result = claimPlateBodySchema.safeParse({});
    expect(result.success).toBe(false);
  });

  it('should reject stateOrRegion longer than 50 characters', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'ABC1234', stateOrRegion: 'a'.repeat(51) });
    expect(result.success).toBe(false);
  });

  it('should accept stateOrRegion exactly 50 characters', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'ABC1234', stateOrRegion: 'a'.repeat(50) });
    expect(result.success).toBe(true);
  });

  it('should accept absent stateOrRegion', () => {
    const result = claimPlateBodySchema.safeParse({ plateNumber: 'ABC1234' });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.stateOrRegion).toBeUndefined();
    }
  });
});
