import { z } from 'zod';

export const createReportBodySchema = z
  .object({
    reportedMessageId: z.string().uuid().optional(),
    reportedUserId: z.string().uuid().optional(),
    reason: z.enum(['spam', 'harassment', 'fraudulent_plate', 'other']),
    description: z.string().max(1000).optional(),
  })
  .refine((data) => data.reportedMessageId || data.reportedUserId, {
    message: 'Must provide either reportedMessageId or reportedUserId',
  });

export type CreateReportBody = z.infer<typeof createReportBodySchema>;
