import admin from 'firebase-admin';
import { env } from './env.js';
import { appLogger } from '../utils/logger.js';

const log = appLogger.child({ module: 'firebase' });

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App | null {
  if (!env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    log.warn('Firebase service account key not provided. Push notifications disabled.');
    return null;
  }

  try {
    const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_KEY);
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    log.info('Firebase initialized successfully');
    return firebaseApp;
  } catch (error) {
    log.error({ err: error }, 'Failed to initialize Firebase');
    return null;
  }
}

export function getFirebaseApp(): admin.app.App | null {
  return firebaseApp;
}
