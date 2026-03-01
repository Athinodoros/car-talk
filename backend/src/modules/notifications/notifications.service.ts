import { eq, and } from 'drizzle-orm';
import admin from 'firebase-admin';
import { db } from '../../db/index.js';
import { deviceTokens } from '../../db/schema.js';
import { socketService } from '../../socket/socket-service.js';
import { getFirebaseApp } from '../../config/firebase.js';
import type { FastifyInstance } from 'fastify';

export async function registerToken(userId: string, token: string, platform: string) {
  // Upsert: if token exists, update user; otherwise insert
  const existing = await db.query.deviceTokens.findFirst({
    where: eq(deviceTokens.token, token),
  });

  if (existing) {
    if (existing.userId !== userId) {
      await db
        .update(deviceTokens)
        .set({ userId, platform })
        .where(eq(deviceTokens.id, existing.id));
    }
    return existing;
  }

  const [deviceToken] = await db
    .insert(deviceTokens)
    .values({ userId, token, platform })
    .returning();

  return deviceToken;
}

export async function removeToken(userId: string, token: string) {
  await db
    .delete(deviceTokens)
    .where(and(eq(deviceTokens.userId, userId), eq(deviceTokens.token, token)));
}

export async function sendPushNotification(
  userId: string,
  notification: { title: string; body: string },
  data?: Record<string, string>,
) {
  // Only send push if user is NOT connected via socket
  if (socketService.isUserConnected(userId)) {
    return;
  }

  const app = getFirebaseApp();
  if (!app) {
    return;
  }

  const tokens = await db.query.deviceTokens.findMany({
    where: eq(deviceTokens.userId, userId),
    columns: { token: true },
  });

  if (tokens.length === 0) return;

  const messaging = admin.messaging(app);

  for (const { token } of tokens) {
    try {
      await messaging.send({
        token,
        notification,
        data,
      });
    } catch (error: unknown) {
      const fbError = error as { code?: string };
      // Remove invalid tokens
      if (
        fbError.code === 'messaging/invalid-registration-token' ||
        fbError.code === 'messaging/registration-token-not-registered'
      ) {
        await db.delete(deviceTokens).where(eq(deviceTokens.token, token));
      }
    }
  }
}
