import { FastifyRequest, FastifyReply } from 'fastify';
import { registerBodySchema, loginBodySchema, refreshBodySchema } from './auth.schemas.js';
import { registerUser, loginUser, refreshTokens } from './auth.service.js';

export async function registerHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = registerBodySchema.parse(request.body);
  const result = await registerUser(request.server, body);
  return reply.code(201).send(result);
}

export async function loginHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = loginBodySchema.parse(request.body);
  const result = await loginUser(request.server, body);
  return reply.send(result);
}

export async function refreshHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = refreshBodySchema.parse(request.body);
  const result = await refreshTokens(request.server, body.refreshToken);
  return reply.send(result);
}
