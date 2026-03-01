import { FastifyRequest, FastifyReply } from 'fastify';
import { claimPlateBodySchema } from './plates.schemas.js';
import { claimPlate, listPlates, releasePlate } from './plates.service.js';

export async function claimPlateHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = claimPlateBodySchema.parse(request.body);
  const plate = await claimPlate(request.server, request.user.id, body);
  return reply.code(201).send(plate);
}

export async function listPlatesHandler(request: FastifyRequest, reply: FastifyReply) {
  const plates = await listPlates(request.user.id);
  return reply.send(plates);
}

export async function releasePlateHandler(
  request: FastifyRequest<{ Params: { id: string } }>,
  reply: FastifyReply,
) {
  const plate = await releasePlate(request.server, request.user.id, request.params.id);
  return reply.send(plate);
}
