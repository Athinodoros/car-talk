import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/auth.js';
import { claimPlateHandler, listPlatesHandler, releasePlateHandler } from './plates.handlers.js';

export default async function platesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', authenticate);

  fastify.post('/api/plates', claimPlateHandler);
  fastify.get('/api/plates', listPlatesHandler);
  fastify.delete('/api/plates/:id', releasePlateHandler);
}
