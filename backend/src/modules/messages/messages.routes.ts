import { FastifyInstance } from 'fastify';
import { authenticate } from '../../middleware/auth.js';
import {
  sendMessageHandler,
  getInboxHandler,
  getSentHandler,
  getUnreadCountHandler,
  getMessageDetailHandler,
  markAsReadHandler,
  addReplyHandler,
} from './messages.handlers.js';

export default async function messagesRoutes(fastify: FastifyInstance) {
  fastify.addHook('onRequest', authenticate);

  fastify.post('/api/messages', {
    config: {
      rateLimit: {
        max: 20,
        timeWindow: '1 hour',
      },
    },
    handler: sendMessageHandler,
  });

  fastify.get('/api/messages/inbox', getInboxHandler);
  fastify.get('/api/messages/sent', getSentHandler);
  fastify.get('/api/messages/unread-count', getUnreadCountHandler);
  fastify.get('/api/messages/:id', getMessageDetailHandler);
  fastify.patch('/api/messages/:id/read', markAsReadHandler);
  fastify.post('/api/messages/:id/replies', addReplyHandler);
}
