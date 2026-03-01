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
import { loggerOptions, genReqId } from './utils/logger.js';
import { initSentry, captureException, setSentryUser } from './utils/sentry.js';
import { metricsPlugin, register, websocketConnectionsActive } from './utils/metrics.js';
import { db } from './db/index.js';
import { sql } from 'drizzle-orm';

// Initialize Sentry BEFORE creating the Fastify instance so that it can
// instrument modules loaded afterwards.  This is a no-op when SENTRY_DSN
// is not set.
initSentry();

const fastify = Fastify({
  logger: loggerOptions,
  // Use X-Request-Id from upstream proxies, or generate a new UUID
  requestIdHeader: 'x-request-id',
  genReqId,
  // Expose the request ID in every child-logger entry automatically
  requestIdLogLabel: 'reqId',
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

  // Global error handler for Zod validation errors + Sentry capture
  fastify.setErrorHandler((error, request, reply) => {
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: 'Validation Error',
        message: error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      });
    }

    // Determine the status code Fastify will use
    const statusCode = (error as { statusCode?: number }).statusCode ?? 500;

    // Capture only 5xx / unhandled errors in Sentry — skip 4xx client errors
    if (statusCode >= 500) {
      const user = request.user as { id: string; email: string } | undefined;
      captureException(error, {
        method: request.method,
        url: request.url,
        query: request.query,
        userId: user?.id,
        requestId: request.id,
      });
    }

    // Let Fastify handle the actual response
    reply.send(error);
  });

  // Set Sentry user context when a JWT-authenticated user is identified
  fastify.addHook('onRequest', async (request) => {
    // request.user is only populated after jwtVerify() runs in route
    // preHandlers, so we use onResponse/onSend instead? No — we hook into
    // onRequest only to silently decode (without rejecting).  The real user
    // context is set here after jwt decorates the request.  However, the
    // most reliable spot is a preHandler-level hook.  We use a lightweight
    // try/catch decode: if the token is present and valid, set Sentry
    // context early.
    try {
      const authHeader = request.headers.authorization;
      if (authHeader?.startsWith('Bearer ')) {
        // Decode without throwing — just for Sentry context enrichment
        await request.jwtVerify();
        const user = request.user as { id: string; email: string };
        if (user?.id) {
          setSentryUser({ id: user.id, email: user.email });
        }
      }
    } catch {
      // Token invalid or expired — that's fine, Sentry just won't have
      // user context for this request.  Auth enforcement happens in the
      // route-level preHandler (authenticate middleware).
    }
  });

  // Register metrics hooks (request duration, count)
  await fastify.register(metricsPlugin);

  // Health check — enhanced with DB connectivity and system info
  fastify.get('/health', async (_request, reply) => {
    let dbStatus: 'ok' | 'error' = 'ok';

    try {
      await db.execute(sql`SELECT 1`);
    } catch {
      dbStatus = 'error';
    }

    const status = dbStatus === 'ok' ? 'ok' : 'degraded';
    const statusCode = dbStatus === 'ok' ? 200 : 503;

    return reply.code(statusCode).send({
      status,
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      db: dbStatus,
    });
  });

  // Prometheus metrics endpoint
  fastify.get('/metrics', async (_request, reply) => {
    // Update the WebSocket gauge with the current count before scraping
    websocketConnectionsActive.set(socketService.getActiveConnectionCount());

    const metricsOutput = await register.metrics();
    return reply.type(register.contentType).send(metricsOutput);
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
