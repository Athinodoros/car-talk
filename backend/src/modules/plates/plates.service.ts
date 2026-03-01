import { eq, and } from 'drizzle-orm';
import { db } from '../../db/index.js';
import { licensePlates } from '../../db/schema.js';
import { normalizePlate } from '../../utils/plate.js';
import type { FastifyInstance } from 'fastify';
import type { ClaimPlateBody } from './plates.schemas.js';

export async function claimPlate(fastify: FastifyInstance, userId: string, body: ClaimPlateBody) {
  const normalizedPlate = normalizePlate(body.plateNumber);

  const existing = await db.query.licensePlates.findFirst({
    where: eq(licensePlates.plateNumber, normalizedPlate),
  });

  if (existing?.userId) {
    throw fastify.httpErrors.conflict('License plate already claimed');
  }

  if (existing) {
    // Unclaimed plate exists — claim it
    const [plate] = await db
      .update(licensePlates)
      .set({ userId, claimedAt: new Date(), stateOrRegion: body.stateOrRegion })
      .where(eq(licensePlates.id, existing.id))
      .returning();
    return plate;
  }

  // Create new plate
  const [plate] = await db
    .insert(licensePlates)
    .values({
      userId,
      plateNumber: normalizedPlate,
      stateOrRegion: body.stateOrRegion,
      claimedAt: new Date(),
    })
    .returning();

  return plate;
}

export async function listPlates(userId: string) {
  return db.query.licensePlates.findMany({
    where: and(eq(licensePlates.userId, userId), eq(licensePlates.isActive, true)),
  });
}

export async function releasePlate(fastify: FastifyInstance, userId: string, plateId: string) {
  const plate = await db.query.licensePlates.findFirst({
    where: eq(licensePlates.id, plateId),
  });

  if (!plate) {
    throw fastify.httpErrors.notFound('Plate not found');
  }

  if (plate.userId !== userId) {
    throw fastify.httpErrors.forbidden('You do not own this plate');
  }

  const [released] = await db
    .update(licensePlates)
    .set({ userId: null, claimedAt: null, isActive: false })
    .where(eq(licensePlates.id, plateId))
    .returning();

  return released;
}
