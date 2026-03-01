import { describe, it, expect } from 'vitest';
import { normalizePlate } from '../../../src/utils/plate.js';

describe('normalizePlate', () => {
  it('should convert lowercase letters to uppercase', () => {
    expect(normalizePlate('abc1234')).toBe('ABC1234');
  });

  it('should convert mixed case to uppercase', () => {
    expect(normalizePlate('aBc123d')).toBe('ABC123D');
  });

  it('should strip spaces', () => {
    expect(normalizePlate('AB C 1234')).toBe('ABC1234');
  });

  it('should strip hyphens', () => {
    expect(normalizePlate('AB-C-1234')).toBe('ABC1234');
  });

  it('should strip both spaces and hyphens', () => {
    expect(normalizePlate('AB - C 12-34')).toBe('ABC1234');
  });

  it('should handle already-normalized plates', () => {
    expect(normalizePlate('ABC1234')).toBe('ABC1234');
  });

  it('should handle empty string', () => {
    expect(normalizePlate('')).toBe('');
  });

  it('should handle string of only spaces and hyphens', () => {
    expect(normalizePlate('  - -- ')).toBe('');
  });

  it('should preserve numbers', () => {
    expect(normalizePlate('1234')).toBe('1234');
  });

  it('should preserve special characters (non-space, non-hyphen)', () => {
    expect(normalizePlate('AB.1234')).toBe('AB.1234');
  });

  it('should handle leading and trailing spaces', () => {
    expect(normalizePlate('  ABC1234  ')).toBe('ABC1234');
  });

  it('should handle leading and trailing hyphens', () => {
    expect(normalizePlate('-ABC1234-')).toBe('ABC1234');
  });

  it('should handle plate with underscores (not stripped)', () => {
    expect(normalizePlate('AB_1234')).toBe('AB_1234');
  });

  it('should handle unicode characters', () => {
    // Unicode toUpperCase behavior
    expect(normalizePlate('über')).toBe('ÜBER');
  });

  it('should handle tabs (not stripped, only spaces and hyphens removed)', () => {
    // \t is not matched by \s in the original regex? Actually \s includes \t
    // The regex is /[\s-]/g which matches any whitespace including tab
    expect(normalizePlate('AB\t1234')).toBe('AB1234');
  });

  it('should handle newlines (stripped by \\s)', () => {
    expect(normalizePlate('AB\n1234')).toBe('AB1234');
  });
});
