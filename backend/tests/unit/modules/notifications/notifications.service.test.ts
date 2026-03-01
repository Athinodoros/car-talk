import { describe, it, expect, vi, beforeEach } from 'vitest';

const { mockDbQuery, mockDbInsert, mockDbUpdate, mockDbDelete, mockSocketService, mockGetFirebaseApp, mockSend } = vi.hoisted(() => ({
  mockDbQuery: {
    deviceTokens: { findFirst: vi.fn(), findMany: vi.fn() },
  },
  mockDbInsert: vi.fn(),
  mockDbUpdate: vi.fn(),
  mockDbDelete: vi.fn(),
  mockSocketService: {
    isUserConnected: vi.fn(),
    emitToUser: vi.fn(),
  },
  mockGetFirebaseApp: vi.fn(),
  mockSend: vi.fn(),
}));

vi.mock('../../../../src/db/index.js', () => ({
  db: {
    query: mockDbQuery,
    insert: mockDbInsert,
    update: mockDbUpdate,
    delete: mockDbDelete,
  },
}));

vi.mock('../../../../src/socket/socket-service.js', () => ({
  socketService: mockSocketService,
}));

vi.mock('../../../../src/config/firebase.js', () => ({
  getFirebaseApp: mockGetFirebaseApp,
}));

vi.mock('firebase-admin', () => ({
  default: {
    messaging: vi.fn().mockReturnValue({
      send: mockSend,
    }),
  },
}));

import { registerToken, removeToken, sendPushNotification } from '../../../../src/modules/notifications/notifications.service.js';

function chainReturning(data: unknown[]) {
  return { returning: vi.fn().mockResolvedValue(data) };
}

function chainValuesReturning(data: unknown[]) {
  return { values: vi.fn().mockReturnValue(chainReturning(data)) };
}

describe('registerToken', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should insert a new device token when it does not exist', async () => {
    mockDbQuery.deviceTokens.findFirst.mockResolvedValue(undefined);

    const deviceToken = { id: 'dev-1', userId: 'u1', token: 'tok-1', platform: 'ios' };
    mockDbInsert.mockReturnValue(chainValuesReturning([deviceToken]));

    const result = await registerToken('u1', 'tok-1', 'ios');
    expect(result).toEqual(deviceToken);
    expect(mockDbInsert).toHaveBeenCalled();
  });

  it('should return existing token if userId matches', async () => {
    const existing = { id: 'dev-1', userId: 'u1', token: 'tok-1', platform: 'ios' };
    mockDbQuery.deviceTokens.findFirst.mockResolvedValue(existing);

    const result = await registerToken('u1', 'tok-1', 'ios');
    expect(result).toEqual(existing);
    expect(mockDbUpdate).not.toHaveBeenCalled();
  });

  it('should update userId if token exists but belongs to different user', async () => {
    const existing = { id: 'dev-1', userId: 'other-user', token: 'tok-1', platform: 'ios' };
    mockDbQuery.deviceTokens.findFirst.mockResolvedValue(existing);

    mockDbUpdate.mockReturnValue({
      set: vi.fn().mockReturnValue({
        where: vi.fn(),
      }),
    });

    const result = await registerToken('u1', 'tok-1', 'ios');
    expect(result).toEqual(existing);
    expect(mockDbUpdate).toHaveBeenCalled();
  });
});

describe('removeToken', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should delete the device token', async () => {
    mockDbDelete.mockReturnValue({
      where: vi.fn(),
    });

    await removeToken('u1', 'tok-1');
    expect(mockDbDelete).toHaveBeenCalled();
  });
});

describe('sendPushNotification', () => {
  beforeEach(() => vi.clearAllMocks());

  it('should not send if user is connected via socket', async () => {
    mockSocketService.isUserConnected.mockReturnValue(true);

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockGetFirebaseApp).not.toHaveBeenCalled();
  });

  it('should not send if firebase app is not configured', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue(null);

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockDbQuery.deviceTokens.findMany).not.toHaveBeenCalled();
  });

  it('should not send if user has no device tokens', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue({});
    mockDbQuery.deviceTokens.findMany.mockResolvedValue([]);

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockSend).not.toHaveBeenCalled();
  });

  it('should send notification to all device tokens', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue({});
    mockDbQuery.deviceTokens.findMany.mockResolvedValue([
      { token: 'tok-1' },
      { token: 'tok-2' },
    ]);
    mockSend.mockResolvedValue('msg-id');

    await sendPushNotification('u1', { title: 'Test', body: 'Body' }, { key: 'val' });

    expect(mockSend).toHaveBeenCalledTimes(2);
    expect(mockSend).toHaveBeenCalledWith({
      token: 'tok-1',
      notification: { title: 'Test', body: 'Body' },
      data: { key: 'val' },
    });
    expect(mockSend).toHaveBeenCalledWith({
      token: 'tok-2',
      notification: { title: 'Test', body: 'Body' },
      data: { key: 'val' },
    });
  });

  it('should remove invalid tokens on messaging error', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue({});
    mockDbQuery.deviceTokens.findMany.mockResolvedValue([{ token: 'bad-tok' }]);
    mockSend.mockRejectedValue({ code: 'messaging/invalid-registration-token' });
    mockDbDelete.mockReturnValue({ where: vi.fn() });

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockDbDelete).toHaveBeenCalled();
  });

  it('should remove unregistered tokens', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue({});
    mockDbQuery.deviceTokens.findMany.mockResolvedValue([{ token: 'expired-tok' }]);
    mockSend.mockRejectedValue({ code: 'messaging/registration-token-not-registered' });
    mockDbDelete.mockReturnValue({ where: vi.fn() });

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockDbDelete).toHaveBeenCalled();
  });

  it('should not delete token for other firebase errors', async () => {
    mockSocketService.isUserConnected.mockReturnValue(false);
    mockGetFirebaseApp.mockReturnValue({});
    mockDbQuery.deviceTokens.findMany.mockResolvedValue([{ token: 'tok-1' }]);
    mockSend.mockRejectedValue({ code: 'messaging/internal-error' });

    await sendPushNotification('u1', { title: 'Test', body: 'Body' });

    expect(mockDbDelete).not.toHaveBeenCalled();
  });
});
