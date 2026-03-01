/**
 * Integration test helper — builds a real Fastify instance with all plugins
 * registered but with a mocked database layer.
 *
 * The db mock is exposed so individual tests can configure return values
 * for `db.query.*`, `db.insert()`, `db.update()`, `db.delete()`,
 * `db.select()`, and `db.transaction()`.
 */
import { vi } from 'vitest';

// ─── Environment variables (must be set BEFORE any app code is imported) ─────
process.env.DATABASE_URL = 'postgres://mock:mock@localhost:5432/mock';
process.env.JWT_SECRET = 'test-jwt-secret-for-integration-tests';
process.env.JWT_REFRESH_SECRET = 'test-jwt-refresh-secret-for-integration-tests';
process.env.NODE_ENV = 'test';

// ─── Use vi.hoisted to make mock helpers available in vi.mock factories ──────
const { createMockDb: _createMockDb, mockDbHolder } = vi.hoisted(() => {
  // This code is hoisted above all vi.mock calls and import statements.
  // We cannot use vi.fn() here, so we use plain functions and objects.
  // The actual vi.fn() calls happen inside createMockDb.

  interface MockFn {
    (...args: unknown[]): unknown;
    mockReturnValue(val: unknown): MockFn;
    mockReturnThis(): MockFn;
    mockResolvedValue(val: unknown): MockFn;
    mockImplementation(fn: (...args: unknown[]) => unknown): MockFn;
    mockReset(): MockFn;
    mockClear(): MockFn;
    mock: { calls: unknown[][] };
  }

  // Minimal mock function implementation for hoisted context
  function createFn(): MockFn {
    let impl: ((...args: unknown[]) => unknown) | null = null;
    const calls: unknown[][] = [];

    const fn = ((...args: unknown[]) => {
      calls.push(args);
      if (impl) return impl(...args);
      return undefined;
    }) as MockFn;

    fn.mock = { calls };

    fn.mockReturnValue = (val: unknown) => {
      impl = () => val;
      return fn;
    };

    fn.mockReturnThis = () => {
      impl = function (this: unknown) {
        return fn;
      };
      return fn;
    };

    fn.mockResolvedValue = (val: unknown) => {
      impl = () => Promise.resolve(val);
      return fn;
    };

    fn.mockImplementation = (newImpl: (...args: unknown[]) => unknown) => {
      impl = newImpl;
      return fn;
    };

    fn.mockReset = () => {
      impl = null;
      calls.length = 0;
      return fn;
    };

    fn.mockClear = () => {
      calls.length = 0;
      return fn;
    };

    return fn;
  }

  function createChainableMock(terminal: () => unknown) {
    const chainMethods = [
      'values', 'set', 'where', 'returning', 'from',
      'innerJoin', 'leftJoin', 'orderBy', 'limit', 'offset',
    ];
    const chain: Record<string, MockFn> = {};

    for (const method of chainMethods) {
      chain[method] = createFn().mockReturnValue(chain);
    }

    // Make the chain thenable so it can be awaited
    (chain as Record<string, unknown>).then = (
      resolve: (v: unknown) => void,
      reject: (e: unknown) => void,
    ) => {
      try {
        resolve(terminal());
      } catch (err) {
        reject(err);
      }
    };

    return chain;
  }

  function createMockDb() {
    let insertResult: unknown[] = [];
    let updateResult: unknown[] = [];
    let selectResult: unknown[] = [];
    let deleteResult: unknown = undefined;

    const insertChain = () => createChainableMock(() => insertResult);
    const updateChain = () => createChainableMock(() => updateResult);
    const selectChain = () => createChainableMock(() => selectResult);
    const deleteChain = () => createChainableMock(() => deleteResult);

    const db = {
      insert: createFn().mockImplementation(() => insertChain()),
      update: createFn().mockImplementation(() => updateChain()),
      delete: createFn().mockImplementation(() => deleteChain()),
      select: createFn().mockImplementation(() => selectChain()),
      execute: createFn().mockResolvedValue([{ '?column?': 1 }]),
      transaction: createFn().mockImplementation(async (fn: (tx: unknown) => Promise<unknown>) => {
        const txInsertResult: unknown[] = [];
        const txInsertChain = () => createChainableMock(() => txInsertResult);
        const txUpdateChain = () => createChainableMock(() => []);

        const tx = {
          insert: createFn().mockImplementation(() => txInsertChain()),
          update: createFn().mockImplementation(() => txUpdateChain()),
          select: createFn().mockImplementation(() => selectChain()),
          delete: createFn().mockImplementation(() => deleteChain()),
          _setInsertResult: (val: unknown[]) => {
            txInsertResult.splice(0, txInsertResult.length, ...val);
          },
        };
        return fn(tx);
      }),
      query: {
        users: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
        licensePlates: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
        messages: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
        replies: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
        reports: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
        deviceTokens: {
          findFirst: createFn().mockResolvedValue(null),
          findMany: createFn().mockResolvedValue([]),
        },
      },
      _createFn: createFn,
      _createChainableMock: createChainableMock,
      _setInsertResult: (val: unknown[]) => { insertResult = val; },
      _setUpdateResult: (val: unknown[]) => { updateResult = val; },
      _setSelectResult: (val: unknown[]) => { selectResult = val; },
      _setDeleteResult: (val: unknown) => { deleteResult = val; },
    };

    return db;
  }

  // Holder object so we can share the mock db instance between
  // the vi.mock factory and the rest of the module
  const mockDbHolder: { db: ReturnType<typeof createMockDb> | null } = { db: null };

  return { createMockDb, mockDbHolder };
});

export type MockDb = ReturnType<typeof _createMockDb>;

// ─── Mock the database module ────────────────────────────────────────────────
vi.mock('../../../src/db/index.js', () => {
  mockDbHolder.db = _createMockDb();
  return { db: mockDbHolder.db };
});

// ─── Mock firebase (we don't want real firebase calls) ───────────────────────
vi.mock('../../../src/config/firebase.js', () => ({
  initializeFirebase: () => null,
  getFirebaseApp: () => null,
}));

// ─── Mock socket service ─────────────────────────────────────────────────────
vi.mock('../../../src/socket/socket-service.js', () => {
  const emitToUser = () => {};
  const isUserConnected = () => false;
  const addUser = () => {};
  const removeUser = () => {};
  const setServer = () => {};
  const getActiveConnectionCount = () => 0;
  return {
    socketService: { emitToUser, isUserConnected, addUser, removeUser, setServer, getActiveConnectionCount },
  };
});

// ─── Mock socket setup ──────────────────────────────────────────────────────
vi.mock('../../../src/socket/socket.js', () => ({
  setupSocketIO: () => {},
}));

// ─── Build a real Fastify app with all plugins ──────────────────────────────
import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import jwt from '@fastify/jwt';
import sensible from '@fastify/sensible';
import { ZodError } from 'zod';
import authRoutes from '../../../src/modules/auth/auth.routes.js';
import platesRoutes from '../../../src/modules/plates/plates.routes.js';
import messagesRoutes from '../../../src/modules/messages/messages.routes.js';
import notificationsRoutes from '../../../src/modules/notifications/notifications.routes.js';
import reportsRoutes from '../../../src/modules/reports/reports.routes.js';
import { metricsPlugin, register, websocketConnectionsActive } from '../../../src/utils/metrics.js';
import { db } from '../../../src/db/index.js';
import { sql } from 'drizzle-orm';
import { socketService } from '../../../src/socket/socket-service.js';

/**
 * Access the mock db object. Must be called after imports have been resolved
 * (i.e., inside a test or beforeAll/beforeEach block, NOT at module top level).
 */
export function getMockDb(): MockDb {
  if (!mockDbHolder.db) {
    throw new Error('mockDb is not initialized — call buildApp() first');
  }
  return mockDbHolder.db;
}

export async function buildApp(): Promise<FastifyInstance> {
  const app = Fastify({ logger: false });

  await app.register(cors, { origin: true });
  await app.register(sensible);
  await app.register(jwt, { secret: process.env.JWT_SECRET! });

  // Zod error handler (mirrors production)
  app.setErrorHandler((error, _request, reply) => {
    if (error instanceof ZodError) {
      return reply.code(400).send({
        error: 'Validation Error',
        message: error.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; '),
      });
    }
    reply.send(error);
  });

  // Register metrics hooks
  await app.register(metricsPlugin);

  // Health check — enhanced (mirrors production)
  app.get('/health', async (_request, reply) => {
    let dbStatus: 'ok' | 'error' = 'ok';

    try {
      await (db as unknown as { execute: (q: unknown) => Promise<unknown> }).execute(sql`SELECT 1`);
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

  // Prometheus metrics endpoint (mirrors production)
  app.get('/metrics', async (_request, reply) => {
    websocketConnectionsActive.set(socketService.getActiveConnectionCount());
    const metricsOutput = await register.metrics();
    return reply.type(register.contentType).send(metricsOutput);
  });

  // Register all route modules
  await app.register(authRoutes);
  await app.register(platesRoutes);
  await app.register(messagesRoutes);
  await app.register(notificationsRoutes);
  await app.register(reportsRoutes);

  await app.ready();

  return app;
}

/**
 * Generate a valid JWT access token for a test user.
 */
export function signTestToken(
  app: FastifyInstance,
  payload: { id: string; email: string },
  expiresIn = '15m',
): string {
  return app.jwt.sign(payload, { expiresIn });
}

/**
 * Helper to generate a UUID-like string for tests.
 */
export function fakeUuid(): string {
  return 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';
}

export function fakeUuid2(): string {
  return '11111111-2222-3333-4444-555555555555';
}

/**
 * Fully reset all mock function calls and implementations between tests.
 * Re-creates the mock db object so each test starts with a clean state.
 */
export function resetDbMocks() {
  // Replace the entire mock db with a fresh instance.
  // Because the source modules hold a reference to `db` which was resolved
  // to `mockDbHolder.db` via the vi.mock factory, we need to mutate the
  // existing object rather than replacing the reference.
  const fresh = _createMockDb();
  const current = mockDbHolder.db;
  if (!current) return;

  // Copy over all properties from fresh to current
  current.insert = fresh.insert;
  current.update = fresh.update;
  current.delete = fresh.delete;
  current.select = fresh.select;
  current.execute = fresh.execute;
  current.transaction = fresh.transaction;
  current._setInsertResult = fresh._setInsertResult;
  current._setUpdateResult = fresh._setUpdateResult;
  current._setSelectResult = fresh._setSelectResult;
  current._setDeleteResult = fresh._setDeleteResult;

  // Reset query mocks
  for (const tableName of Object.keys(current.query) as Array<keyof typeof current.query>) {
    const freshTable = fresh.query[tableName];
    const currentTable = current.query[tableName];
    for (const methodName of Object.keys(currentTable) as Array<keyof typeof currentTable>) {
      (currentTable as Record<string, unknown>)[methodName] = (freshTable as Record<string, unknown>)[methodName];
    }
  }
}
