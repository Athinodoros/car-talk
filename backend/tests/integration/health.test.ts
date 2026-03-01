import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildApp, getMockDb } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('GET /health', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should return 200 with status ok when db is reachable', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.status).toBe('ok');
    expect(body.timestamp).toBeDefined();
    expect(typeof body.timestamp).toBe('string');
    expect(body.db).toBe('ok');
    expect(typeof body.uptime).toBe('number');
    expect(body.memory).toBeDefined();
    expect(typeof body.memory.rss).toBe('number');
    expect(typeof body.memory.heapTotal).toBe('number');
    expect(typeof body.memory.heapUsed).toBe('number');
  });

  it('should return a valid ISO timestamp', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    const body = response.json();
    const parsed = new Date(body.timestamp);
    expect(parsed.toISOString()).toBe(body.timestamp);
  });

  it('should return 503 with status degraded when db is unreachable', async () => {
    const mockDb = getMockDb();
    // Make the execute mock reject to simulate DB failure
    mockDb.execute.mockImplementation(() => Promise.reject(new Error('connection refused')));

    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(503);
    const body = response.json();
    expect(body.status).toBe('degraded');
    expect(body.db).toBe('error');
    expect(body.timestamp).toBeDefined();
    expect(typeof body.uptime).toBe('number');
    expect(body.memory).toBeDefined();

    // Restore the mock for subsequent tests
    mockDb.execute.mockResolvedValue([{ '?column?': 1 }]);
  });
});

describe('GET /metrics', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should return 200 with Prometheus text format', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/metrics',
    });

    expect(response.statusCode).toBe(200);
    expect(response.headers['content-type']).toContain('text/plain');
    // Should contain default Node.js metrics and our custom ones
    expect(response.body).toContain('http_request_duration_seconds');
    expect(response.body).toContain('http_requests_total');
    expect(response.body).toContain('websocket_connections_active');
    expect(response.body).toContain('messages_sent_total');
    expect(response.body).toContain('errors_total');
  });
});
