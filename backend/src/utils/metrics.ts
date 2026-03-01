import client, { Registry } from 'prom-client';
import type { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

// ---------------------------------------------------------------------------
// Registry & default metrics
// ---------------------------------------------------------------------------

export const register = new Registry();

register.setDefaultLabels({ app: 'car-post-all-backend' });

client.collectDefaultMetrics({ register });

// ---------------------------------------------------------------------------
// Custom metrics
// ---------------------------------------------------------------------------

export const httpRequestDurationSeconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'] as const,
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

export const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'] as const,
  registers: [register],
});

export const websocketConnectionsActive = new client.Gauge({
  name: 'websocket_connections_active',
  help: 'Number of active WebSocket connections',
  registers: [register],
});

export const messagesSentTotal = new client.Counter({
  name: 'messages_sent_total',
  help: 'Total number of messages sent',
  registers: [register],
});

export const errorsTotal = new client.Counter({
  name: 'errors_total',
  help: 'Total number of errors',
  labelNames: ['type'] as const,
  registers: [register],
});

// ---------------------------------------------------------------------------
// Helper to normalise Fastify route patterns
// ---------------------------------------------------------------------------

/**
 * Extract the route pattern (e.g. `/api/messages/:id`) from a Fastify request.
 * Falls back to the raw URL path if no route context is available.
 */
function getRouteLabel(request: FastifyRequest): string {
  // Fastify attaches the matched route schema as routeOptions (v5) or routerPath (v4)
  const routeOptions = request.routeOptions;
  if (routeOptions && routeOptions.url) {
    return routeOptions.url;
  }
  // Fallback: strip query string and use the raw path
  return request.url.split('?')[0];
}

// ---------------------------------------------------------------------------
// Fastify plugin — registers onRequest / onResponse hooks
// ---------------------------------------------------------------------------

export async function metricsPlugin(fastify: FastifyInstance): Promise<void> {
  // Stash the high-resolution start time on each request
  fastify.addHook('onRequest', async (request: FastifyRequest) => {
    (request as unknown as Record<string, unknown>).__metricsStart = process.hrtime.bigint();
  });

  // Record duration + count once the response has been sent
  fastify.addHook('onResponse', async (request: FastifyRequest, reply: FastifyReply) => {
    const startBigInt = (request as unknown as Record<string, unknown>).__metricsStart as
      | bigint
      | undefined;
    if (startBigInt === undefined) return;

    const durationNs = Number(process.hrtime.bigint() - startBigInt);
    const durationSec = durationNs / 1e9;

    const route = getRouteLabel(request);
    const method = request.method;
    const statusCode = String(reply.statusCode);

    httpRequestDurationSeconds.observe({ method, route, status_code: statusCode }, durationSec);
    httpRequestsTotal.inc({ method, route, status_code: statusCode });

    // Track 5xx as errors
    if (reply.statusCode >= 500) {
      errorsTotal.inc({ type: 'http_5xx' });
    }
  });
}
