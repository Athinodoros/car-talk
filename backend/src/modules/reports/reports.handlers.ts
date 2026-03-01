import { FastifyRequest, FastifyReply } from 'fastify';
import { createReportBodySchema } from './reports.schemas.js';
import { createReport } from './reports.service.js';

export async function createReportHandler(request: FastifyRequest, reply: FastifyReply) {
  const body = createReportBodySchema.parse(request.body);
  const report = await createReport(request.server, request.user.id, body);
  return reply.code(201).send({ report });
}
