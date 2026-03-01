import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/auth.js';
import { createReportHandler } from './reports.handlers.js';

export default async function reportsRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', authenticate);

  fastify.post('/api/reports', createReportHandler);
}
