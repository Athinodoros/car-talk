import { eq, and } from 'drizzle-orm';
import { db } from '../../db/index.js';
import { reports } from '../../db/schema.js';
import type { FastifyInstance } from 'fastify';
import type { CreateReportBody } from './reports.schemas.js';

export async function createReport(
  fastify: FastifyInstance,
  reporterId: string,
  body: CreateReportBody,
) {
  // Check for duplicate report on the same message
  if (body.reportedMessageId) {
    const existing = await db.query.reports.findFirst({
      where: and(
        eq(reports.reporterId, reporterId),
        eq(reports.reportedMessageId, body.reportedMessageId),
      ),
    });
    if (existing) {
      throw fastify.httpErrors.conflict('You have already reported this message');
    }
  }

  const [report] = await db
    .insert(reports)
    .values({
      reporterId,
      reportedUserId: body.reportedUserId,
      reportedMessageId: body.reportedMessageId,
      reason: body.reason,
      description: body.description,
    })
    .returning();

  return report;
}
