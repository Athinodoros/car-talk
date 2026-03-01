import { FastifyInstance } from 'fastify';
import { registerHandler, loginHandler, refreshHandler } from './auth.handlers.js';

export default async function authRoutes(fastify: FastifyInstance) {
  fastify.post('/api/auth/register', registerHandler);
  fastify.post('/api/auth/login', loginHandler);
  fastify.post('/api/auth/refresh', refreshHandler);
}
