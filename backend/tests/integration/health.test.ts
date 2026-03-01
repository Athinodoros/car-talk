import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { buildApp } from './helpers/setup.js';
import type { FastifyInstance } from 'fastify';

describe('GET /health', () => {
  let app: FastifyInstance;

  beforeAll(async () => {
    app = await buildApp();
  });

  afterAll(async () => {
    await app.close();
  });

  it('should return 200 with status ok', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/health',
    });

    expect(response.statusCode).toBe(200);
    const body = response.json();
    expect(body.status).toBe('ok');
    expect(body.timestamp).toBeDefined();
    expect(typeof body.timestamp).toBe('string');
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
});
