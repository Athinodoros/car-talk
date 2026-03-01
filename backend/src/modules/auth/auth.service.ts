import bcrypt from 'bcryptjs';
import crypto from 'node:crypto';
import { eq } from 'drizzle-orm';
import { db } from '../../db/index.js';
import { users, licensePlates } from '../../db/schema.js';
import { normalizePlate } from '../../utils/plate.js';
import type { FastifyInstance } from 'fastify';
import type { RegisterBody, LoginBody } from './auth.schemas.js';

const BCRYPT_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, BCRYPT_ROUNDS);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateTokens(fastify: FastifyInstance, payload: { id: string; email: string }) {
  const accessToken = fastify.jwt.sign(payload, { expiresIn: '15m' });
  const refreshToken = fastify.jwt.sign(payload, {
    expiresIn: '7d',
    jti: crypto.randomUUID(),
  });
  return { accessToken, refreshToken };
}

export async function registerUser(
  fastify: FastifyInstance,
  body: RegisterBody,
) {
  const normalizedPlate = normalizePlate(body.plateNumber);

  // Check for existing email
  const existingUser = await db.query.users.findFirst({
    where: eq(users.email, body.email),
  });
  if (existingUser) {
    throw fastify.httpErrors.conflict('Email already registered');
  }

  // Check for existing claimed plate
  const existingPlate = await db.query.licensePlates.findFirst({
    where: eq(licensePlates.plateNumber, normalizedPlate),
  });
  if (existingPlate?.userId) {
    throw fastify.httpErrors.conflict('License plate already claimed');
  }

  const passwordHash = await hashPassword(body.password);

  // Atomic transaction: create user + claim plate
  const result = await db.transaction(async (tx) => {
    const [newUser] = await tx
      .insert(users)
      .values({
        email: body.email,
        passwordHash,
        displayName: body.displayName,
      })
      .returning();

    if (existingPlate) {
      // Plate exists but unclaimed — claim it
      await tx
        .update(licensePlates)
        .set({ userId: newUser.id, claimedAt: new Date(), stateOrRegion: body.stateOrRegion })
        .where(eq(licensePlates.id, existingPlate.id));
    } else {
      // Create new plate
      await tx.insert(licensePlates).values({
        userId: newUser.id,
        plateNumber: normalizedPlate,
        stateOrRegion: body.stateOrRegion,
        claimedAt: new Date(),
      });
    }

    return newUser;
  });

  const tokens = generateTokens(fastify, { id: result.id, email: result.email });

  // Store refresh token hash
  await db
    .update(users)
    .set({ refreshTokenHash: hashToken(tokens.refreshToken) })
    .where(eq(users.id, result.id));

  return {
    user: { id: result.id, email: result.email, displayName: result.displayName },
    tokens,
  };
}

export async function loginUser(fastify: FastifyInstance, body: LoginBody) {
  const user = await db.query.users.findFirst({
    where: eq(users.email, body.email),
  });

  if (!user) {
    throw fastify.httpErrors.unauthorized('Invalid email or password');
  }

  const validPassword = await verifyPassword(body.password, user.passwordHash);
  if (!validPassword) {
    throw fastify.httpErrors.unauthorized('Invalid email or password');
  }

  const tokens = generateTokens(fastify, { id: user.id, email: user.email });

  // Store refresh token hash
  await db
    .update(users)
    .set({ refreshTokenHash: hashToken(tokens.refreshToken) })
    .where(eq(users.id, user.id));

  return {
    user: { id: user.id, email: user.email, displayName: user.displayName },
    tokens,
  };
}

export async function refreshTokens(fastify: FastifyInstance, refreshToken: string) {
  let payload: { id: string; email: string };
  try {
    payload = fastify.jwt.verify<{ id: string; email: string }>(refreshToken);
  } catch {
    throw fastify.httpErrors.unauthorized('Invalid or expired refresh token');
  }

  const user = await db.query.users.findFirst({
    where: eq(users.id, payload.id),
  });

  if (!user || user.refreshTokenHash !== hashToken(refreshToken)) {
    throw fastify.httpErrors.unauthorized('Invalid or expired refresh token');
  }

  const tokens = generateTokens(fastify, { id: user.id, email: user.email });

  // Rotate: store new refresh token hash
  await db
    .update(users)
    .set({ refreshTokenHash: hashToken(tokens.refreshToken) })
    .where(eq(users.id, user.id));

  return { tokens };
}
