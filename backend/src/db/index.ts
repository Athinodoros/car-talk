import { drizzle } from 'drizzle-orm/postgres-js';
import postgres from 'postgres';
import { env } from '../config/env.js';
import * as schema from './schema.js';

const isProduction = env.NODE_ENV === 'production';

const client = postgres(env.DATABASE_URL, {
  max: isProduction ? 20 : 5,
  idle_timeout: isProduction ? 30 : 20,
  connect_timeout: 10,
  max_lifetime: isProduction ? 60 * 30 : undefined, // 30 min max lifetime in production
});

export const db = drizzle(client, { schema });

export type Database = typeof db;
