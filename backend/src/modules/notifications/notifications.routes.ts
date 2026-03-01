import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/auth.js';
import { registerDeviceHandler, removeDeviceHandler } from './notifications.handlers.js';

export default async function notificationsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', authenticate);

  fastify.post('/api/devices', registerDeviceHandler);
  fastify.delete('/api/devices/:token', removeDeviceHandler);
}
