import pino from 'pino';
import type { FastifyRequest, FastifyReply } from 'fastify';
import { env } from '../config/env.js';
import { randomUUID } from 'node:crypto';

/**
 * Shared Pino logger configuration.
 *
 * Used by both the Fastify instance (via `logger` option) and the standalone
 * `appLogger` export for code that runs outside of a request context
 * (e.g. firebase init, startup tasks).
 */

// ---------------------------------------------------------------------------
// Sensitive-data redaction paths
// ---------------------------------------------------------------------------
const redactPaths = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.body.password',
  'req.body.refreshToken',
  'req.body.token',
  'req.body.secret',
  'req.body.currentPassword',
  'req.body.newPassword',
  // response bodies that might echo tokens
  'res.body.accessToken',
  'res.body.refreshToken',
  'res.body.token',
];

// ---------------------------------------------------------------------------
// Custom serializers
// ---------------------------------------------------------------------------
function reqSerializer(req: FastifyRequest) {
  return {
    method: req.method,
    url: req.url,
    hostname: req.hostname,
    remoteAddress: req.ip,
    // Only safe headers — authorization is handled by redact
    headers: {
      'user-agent': req.headers['user-agent'],
      'content-type': req.headers['content-type'],
      host: req.headers.host,
    },
  };
}

function resSerializer(res: FastifyReply) {
  return {
    statusCode: res.statusCode,
  };
}

// ---------------------------------------------------------------------------
// Shared logger options (compatible with Fastify's `logger` option)
// ---------------------------------------------------------------------------
export const loggerOptions: pino.LoggerOptions = {
  level: env.NODE_ENV === 'production' ? 'info' : 'debug',
  redact: {
    paths: redactPaths,
    censor: '[REDACTED]',
  },
  serializers: {
    req: reqSerializer as unknown as pino.SerializerFn,
    res: resSerializer as unknown as pino.SerializerFn,
  },
  // pino-pretty transport for local development only
  ...(env.NODE_ENV !== 'production'
    ? {
        transport: {
          target: 'pino-pretty',
          options: {
            translateTime: 'HH:MM:ss Z',
            ignore: 'pid,hostname',
          },
        },
      }
    : {}),
};

// ---------------------------------------------------------------------------
// Request-ID generation (used in Fastify constructor options)
// ---------------------------------------------------------------------------

/** Generate a unique request ID (UUIDv4, good enough for tracing). */
export function genReqId(): string {
  return randomUUID();
}

// ---------------------------------------------------------------------------
// Standalone application logger
// ---------------------------------------------------------------------------

/**
 * App-level logger for code that runs outside of a Fastify request context.
 * e.g. Firebase initialization, startup tasks, background jobs.
 *
 * Inside request handlers, prefer `request.log` which automatically includes
 * the request ID.
 */
export const appLogger: pino.Logger = pino(loggerOptions);
