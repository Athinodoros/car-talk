import { describe, it, expect } from 'vitest';
import { registerDeviceBodySchema } from '../../../../src/modules/notifications/notifications.schemas.js';

describe('registerDeviceBodySchema', () => {
  it('should accept valid device registration for ios', () => {
    const result = registerDeviceBodySchema.safeParse({ token: 'fcm-token-123', platform: 'ios' });
    expect(result.success).toBe(true);
  });

  it('should accept valid device registration for android', () => {
    const result = registerDeviceBodySchema.safeParse({ token: 'fcm-token-456', platform: 'android' });
    expect(result.success).toBe(true);
  });

  it('should reject empty token', () => {
    const result = registerDeviceBodySchema.safeParse({ token: '', platform: 'ios' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues[0].message).toBe('Device token is required');
    }
  });

  it('should reject missing token', () => {
    const result = registerDeviceBodySchema.safeParse({ platform: 'ios' });
    expect(result.success).toBe(false);
  });

  it('should reject invalid platform', () => {
    const result = registerDeviceBodySchema.safeParse({ token: 'fcm-token', platform: 'web' });
    expect(result.success).toBe(false);
  });

  it('should reject missing platform', () => {
    const result = registerDeviceBodySchema.safeParse({ token: 'fcm-token' });
    expect(result.success).toBe(false);
  });

  it('should reject empty object', () => {
    const result = registerDeviceBodySchema.safeParse({});
    expect(result.success).toBe(false);
  });
});
