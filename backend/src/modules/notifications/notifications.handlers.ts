import { FastifyRequest, FastifyReply } from 'fastify';
import { registerDeviceBodySchema } from './notifications.schemas.js';
import { registerToken, removeToken } from './notifications.service.js';

export async function registerDeviceHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = registerDeviceBodySchema.parse(request.body);
  const result = await registerToken(request.user.id, body.token, body.platform);
  return reply.code(201).send({ success: true, device: result });
}

export async function removeDeviceHandler(
  request: FastifyRequest<{ Params: { token: string } }>,
  reply: FastifyReply,
) {
  await removeToken(request.user.id, request.params.token);
  return reply.send({ success: true });
}
