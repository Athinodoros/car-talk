import { FastifyRequest, FastifyReply } from 'fastify';
import {
  sendMessageBodySchema,
  inboxQuerySchema,
  replyBodySchema,
} from './messages.schemas.js';
import {
  sendMessage,
  getInbox,
  getSent,
  getUnreadCount,
  getMessageDetail,
  markAsRead,
  addReply,
} from './messages.service.js';

export async function sendMessageHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = sendMessageBodySchema.parse(request.body);
  const message = await sendMessage(request.server, request.user.id, body);
  return reply.code(201).send({ message });
}

export async function getInboxHandler(request: FastifyRequest, reply: FastifyReply) {
  const query = inboxQuerySchema.parse(request.query);
  const result = await getInbox(request.user.id, query.cursor, query.limit);
  return reply.send(result);
}

export async function getSentHandler(request: FastifyRequest, reply: FastifyReply) {
  const query = inboxQuerySchema.parse(request.query);
  const result = await getSent(request.user.id, query.cursor, query.limit);
  return reply.send(result);
}

export async function getUnreadCountHandler(request: FastifyRequest, reply: FastifyReply) {
  const unreadCount = await getUnreadCount(request.user.id);
  return reply.send({ count: unreadCount });
}

export async function getMessageDetailHandler(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const message = await getMessageDetail(request.server, request.user.id, request.params.id);
  return reply.send({ message });
}

export async function markAsReadHandler(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const result = await markAsRead(request.server, request.user.id, request.params.id);
  return reply.send(result);
}

export async function addReplyHandler(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const body = replyBodySchema.parse(request.body);
  const result = await addReply(request.server, request.user.id, request.params.id, body);
  return reply.code(201).send({ reply: result });
}
