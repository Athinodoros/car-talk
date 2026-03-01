import * as Sentry from '@sentry/node';
import { env } from '../config/env.js';
import { appLogger } from './logger.js';
import { join } from 'node:path';
import { readFileSync } from 'node:fs';

// Read version from package.json (located at project root, one level above src/)
const pkgPath = join(__dirname, '..', '..', 'package.json');
const { version } = JSON.parse(readFileSync(pkgPath, 'utf-8')) as { version: string };

let sentryInitialized = false;

/**
 * Initialize Sentry error tracking.
 *
 * If SENTRY_DSN is not configured, this is a no-op and the app runs
 * without Sentry entirely.
 */
export function initSentry(): void {
  if (!env.SENTRY_DSN) {
    appLogger.info('Sentry DSN not configured — error tracking disabled');
    return;
  }

  Sentry.init({
    dsn: env.SENTRY_DSN,
    environment: env.NODE_ENV,
    release: `car-post-all-backend@${version}`,
    tracesSampleRate: env.NODE_ENV === 'production' ? 0.1 : 1.0,
    // Do not send default PII (cookies, headers with auth, etc.)
    sendDefaultPii: false,
  });

  sentryInitialized = true;
  appLogger.info('Sentry initialized for environment: %s', env.NODE_ENV);
}

/**
 * Capture an exception in Sentry with optional extra context.
 *
 * If Sentry is not initialized (no DSN), the error is logged via the
 * application logger instead.
 */
export function captureException(
  error: unknown,
  context?: Record<string, unknown>,
): void {
  if (!sentryInitialized) {
    appLogger.error({ err: error, ...context }, 'Unhandled error (Sentry disabled)');
    return;
  }

  Sentry.withScope((scope) => {
    if (context) {
      scope.setExtras(context);
    }
    Sentry.captureException(error);
  });
}

/**
 * Set the current Sentry user context.
 *
 * No-op if Sentry is not initialized.
 */
export function setSentryUser(user: { id: string; email?: string }): void {
  if (!sentryInitialized) return;
  Sentry.setUser(user);
}

/**
 * Clear the current Sentry user context (e.g. on logout).
 *
 * No-op if Sentry is not initialized.
 */
export function clearSentryUser(): void {
  if (!sentryInitialized) return;
  Sentry.setUser(null);
}
