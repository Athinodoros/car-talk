import { eq, and, inArray, lt, desc, sql, count } from 'drizzle-orm';
import { db } from '../../db/index.js';
import { messages, replies, licensePlates, users } from '../../db/schema.js';
import { normalizePlate } from '../../utils/plate.js';
import { socketService } from '../../socket/socket-service.js';
import { sendPushNotification } from '../notifications/notifications.service.js';
import type { FastifyInstance } from 'fastify';
import type { SendMessageBody, ReplyBody } from './messages.schemas.js';

export async function sendMessage(
  fastify: FastifyInstance,
  senderId: string,
  body: SendMessageBody,
) {
  const normalizedPlate = normalizePlate(body.plateNumber);

  // Find or create plate
  let plate = await db.query.licensePlates.findFirst({
    where: eq(licensePlates.plateNumber, normalizedPlate),
  });

  if (!plate) {
    const [newPlate] = await db
      .insert(licensePlates)
      .values({ plateNumber: normalizedPlate })
      .returning();
    plate = newPlate;
  }

  // Create message
  const [message] = await db
    .insert(messages)
    .values({
      senderId,
      recipientPlateId: plate.id,
      subject: body.subject,
      body: body.body,
    })
    .returning();

  // Real-time: emit to recipient if plate is claimed
  if (plate.userId) {
    socketService.emitToUser(plate.userId, 'new_message', { message });

    // Fire-and-forget push notification to plate owner
    const pushBody = body.body.length > 100 ? body.body.slice(0, 100) + '...' : body.body;
    sendPushNotification(
      plate.userId,
      { title: 'New Message', body: pushBody },
      { messageId: message.id },
    ).catch(() => {});

    // Update unread count
    const userPlateIds = await getUserPlateIds(plate.userId);
    const unreadCount = await getUnreadCountByPlateIds(userPlateIds);
    socketService.emitToUser(plate.userId, 'unread_count', { count: unreadCount });
  }

  return message;
}

export async function getInbox(userId: string, cursor?: string, limit = 20) {
  const userPlateIds = await getUserPlateIds(userId);

  if (userPlateIds.length === 0) {
    return { messages: [], nextCursor: null };
  }

  const conditions = [inArray(messages.recipientPlateId, userPlateIds)];
  if (cursor) {
    conditions.push(lt(messages.createdAt, new Date(cursor)));
  }

  const result = await db
    .select({
      id: messages.id,
      senderId: messages.senderId,
      recipientPlateId: messages.recipientPlateId,
      subject: messages.subject,
      body: messages.body,
      isRead: messages.isRead,
      createdAt: messages.createdAt,
      updatedAt: messages.updatedAt,
      senderDisplayName: users.displayName,
    })
    .from(messages)
    .innerJoin(users, eq(messages.senderId, users.id))
    .where(and(...conditions))
    .orderBy(desc(messages.createdAt))
    .limit(limit + 1);

  const hasMore = result.length > limit;
  const items = hasMore ? result.slice(0, limit) : result;
  const nextCursor = hasMore ? items[items.length - 1].createdAt.toISOString() : null;

  return { messages: items, nextCursor };
}

export async function getSent(userId: string, cursor?: string, limit = 20) {
  const conditions = [eq(messages.senderId, userId)];
  if (cursor) {
    conditions.push(lt(messages.createdAt, new Date(cursor)));
  }

  const result = await db
    .select({
      id: messages.id,
      senderId: messages.senderId,
      recipientPlateId: messages.recipientPlateId,
      subject: messages.subject,
      body: messages.body,
      isRead: messages.isRead,
      createdAt: messages.createdAt,
      updatedAt: messages.updatedAt,
      recipientPlateNumber: licensePlates.plateNumber,
    })
    .from(messages)
    .innerJoin(licensePlates, eq(messages.recipientPlateId, licensePlates.id))
    .where(and(...conditions))
    .orderBy(desc(messages.createdAt))
    .limit(limit + 1);

  const hasMore = result.length > limit;
  const items = hasMore ? result.slice(0, limit) : result;
  const nextCursor = hasMore ? items[items.length - 1].createdAt.toISOString() : null;

  return { messages: items, nextCursor };
}

export async function getUnreadCount(userId: string) {
  const userPlateIds = await getUserPlateIds(userId);
  if (userPlateIds.length === 0) return 0;
  return getUnreadCountByPlateIds(userPlateIds);
}

async function getUnreadCountByPlateIds(plateIds: string[]): Promise<number> {
  if (plateIds.length === 0) return 0;
  const [result] = await db
    .select({ value: count() })
    .from(messages)
    .where(and(inArray(messages.recipientPlateId, plateIds), eq(messages.isRead, false)));
  return result.value;
}

export async function getMessageDetail(fastify: FastifyInstance, userId: string, messageId: string) {
  const message = await db.query.messages.findFirst({
    where: eq(messages.id, messageId),
    with: {
      sender: { columns: { id: true, displayName: true } },
      recipientPlate: { columns: { id: true, plateNumber: true, userId: true } },
      replies: {
        orderBy: [replies.createdAt],
        with: {
          sender: { columns: { id: true, displayName: true } },
        },
      },
    },
  });

  if (!message) {
    throw fastify.httpErrors.notFound('Message not found');
  }

  // Authorization: must be sender or plate owner
  const isRecipient = message.recipientPlate.userId === userId;
  const isSender = message.senderId === userId;
  if (!isRecipient && !isSender) {
    throw fastify.httpErrors.forbidden('You do not have access to this message');
  }

  return message;
}

export async function markAsRead(fastify: FastifyInstance, userId: string, messageId: string) {
  const message = await db.query.messages.findFirst({
    where: eq(messages.id, messageId),
    with: {
      recipientPlate: { columns: { userId: true } },
    },
  });

  if (!message) {
    throw fastify.httpErrors.notFound('Message not found');
  }

  if (message.recipientPlate.userId !== userId) {
    throw fastify.httpErrors.forbidden('Only the recipient can mark as read');
  }

  await db
    .update(messages)
    .set({ isRead: true, updatedAt: new Date() })
    .where(eq(messages.id, messageId));

  // Notify sender that message was read
  socketService.emitToUser(message.senderId, 'message_read', { messageId });

  return { success: true };
}

export async function addReply(
  fastify: FastifyInstance,
  userId: string,
  messageId: string,
  body: ReplyBody,
) {
  const message = await db.query.messages.findFirst({
    where: eq(messages.id, messageId),
    with: {
      recipientPlate: { columns: { userId: true } },
    },
  });

  if (!message) {
    throw fastify.httpErrors.notFound('Message not found');
  }

  // Authorization: must be sender or plate owner
  const isRecipient = message.recipientPlate.userId === userId;
  const isSender = message.senderId === userId;
  if (!isRecipient && !isSender) {
    throw fastify.httpErrors.forbidden('You do not have access to this thread');
  }

  const [reply] = await db
    .insert(replies)
    .values({
      messageId,
      senderId: userId,
      body: body.body,
    })
    .returning();

  // Update message.updated_at
  await db
    .update(messages)
    .set({ updatedAt: new Date() })
    .where(eq(messages.id, messageId));

  // Notify the other party
  const otherUserId = isSender ? message.recipientPlate.userId : message.senderId;
  if (otherUserId) {
    socketService.emitToUser(otherUserId, 'new_reply', { messageId, reply });

    // Fire-and-forget push notification to the other participant
    const pushBody = body.body.length > 100 ? body.body.slice(0, 100) + '...' : body.body;
    sendPushNotification(
      otherUserId,
      { title: 'New Reply', body: pushBody },
      { messageId },
    ).catch(() => {});
  }

  return reply;
}

async function getUserPlateIds(userId: string): Promise<string[]> {
  const plates = await db.query.licensePlates.findMany({
    where: and(eq(licensePlates.userId, userId), eq(licensePlates.isActive, true)),
    columns: { id: true },
  });
  return plates.map((p) => p.id);
}
