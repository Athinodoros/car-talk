import admin from 'firebase-admin';
import { env } from './env.js';

let firebaseApp: admin.app.App | null = null;

export function initializeFirebase(): admin.app.App | null {
  if (!env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    console.warn('Firebase service account key not provided. Push notifications disabled.');
    return null;
  }

  try {
    const serviceAccount = JSON.parse(env.FIREBASE_SERVICE_ACCOUNT_KEY);
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    return firebaseApp;
  } catch (error) {
    console.error('Failed to initialize Firebase:', error);
    return null;
  }
}

export function getFirebaseApp(): admin.app.App | null {
  return firebaseApp;
}
