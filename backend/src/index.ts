import Fastify from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import rateLimit from '@fastify/rate-limit';
import sensible from '@fastify/sensible';
import { env } from './config/env.js';
import { initializeFirebase } from './config/firebase.js';
import { setupSocketIO } from './socket/socket.js';
import { socketService } from './socket/socket-service.js';
import authRoutes from './modules/auth/auth.routes.js';
import platesRoutes from './modules/plates/plates.routes.js';
import messagesRoutes from './modules/messages/messages.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import reportsRoutes from './modules/reports/reports.routes.js';
import { ZodError } from 'zod';

const fastify = Fastify({
  logger: {
    level: env.NODE_ENV === 'production' ? 'info' : 'debug',
    transport:
      env.NODE_ENV !== 'production'
        ? { target: 'pino-pretty', options: { translateTime: 'HH:MM:ss Z', ignore: 'pid,hostname' } }
        : undefined,
  },
});

async function start() {
  // Register plugins
  await fastify.register(cors, { origin: true });
  await fastify.register(sensible);
  await fastify.register(jwt, { secret: env.JWT_SECRET });
  await fastify.register(rateLimit, {
    max: 100,
    timeWindow: '1 minute',
  });

  // Global error handler for Zod validation errors
  fastify.setErrorHandler((error, _request, reply) => {
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: 'Validation Error',
        message: error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      });
    }

    // Let Fastify handle all other errors
    reply.send(error);
  });

  // Health check
  fastify.get('/health', async () => {
    return { status: 'ok', timestamp: new Date().toISOString() };
  });

  // Register modules
  await fastify.register(authRoutes);
  await fastify.register(platesRoutes);
  await fastify.register(messagesRoutes);
  await fastify.register(notificationsRoutes);
  await fastify.register(reportsRoutes);

  // Initialize Firebase (optional)
  initializeFirebase();

  // Setup Socket.IO before listen (fastify.server is available immediately)
  setupSocketIO(fastify, fastify.server);
  fastify.decorate('socketService', socketService);

  // Start server
  await fastify.listen({ port: env.PORT, host: '0.0.0.0' });

  fastify.log.info(`Server running on port ${env.PORT}`);
}

start().catch((err) => {
  fastify.log.error(err);
  process.exit(1);
});
