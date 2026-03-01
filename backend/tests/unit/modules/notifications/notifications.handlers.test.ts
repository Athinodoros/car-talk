import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockRegisterToken, mockRemoveToken } = vi.hoisted(() => ({
  mockRegisterToken: vi.fn(),
  mockRemoveToken: vi.fn(),
}));

vi.mock('../../../../src/modules/notifications/notifications.service.js', () => ({
  registerToken: mockRegisterToken,
  removeToken: mockRemoveToken,
  sendPushNotification: vi.fn(),
}));

import {
  registerDeviceHandler,
  removeDeviceHandler,
} from '../../../../src/modules/notifications/notifications.handlers.js';

function createMockReply() {
  return {
    code: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
}

describe('registerDeviceHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should parse body and call registerToken, returning 201', async () => {
    const body = { token: 'fcm-token-123', platform: 'ios' };
    const device = { id: 'dev-1', token: 'fcm-token-123', platform: 'ios' };
    mockRegisterToken.mockResolvedValue(device);

    const request = { body, user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await registerDeviceHandler(request, reply as any);

    expect(mockRegisterToken).toHaveBeenCalledWith('u1', 'fcm-token-123', 'ios');
    expect(reply.code).toHaveBeenCalledWith(201);
    expect(reply.send).toHaveBeenCalledWith({ success: true, device });
  });
});

describe('removeDeviceHandler', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should call removeToken with params.token', async () => {
    mockRemoveToken.mockResolvedValue(undefined);

    const request = { params: { token: 'fcm-token-123' }, user: { id: 'u1' } } as any;
    const reply = createMockReply();

    await removeDeviceHandler(request, reply as any);

    expect(mockRemoveToken).toHaveBeenCalledWith('u1', 'fcm-token-123');
    expect(reply.send).toHaveBeenCalledWith({ success: true });
  });
});
