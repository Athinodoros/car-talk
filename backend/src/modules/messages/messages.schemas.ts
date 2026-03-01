import { z } from 'zod';

export const sendMessageBodySchema = z.object({
  plateNumber: z.string().min(1, 'Plate number is required').max(20),
  subject: z.string().max(100).optional(),
  body: z.string().min(1, 'Message body is required').max(2000),
});

export const inboxQuerySchema = z.object({
  cursor: z.string().optional(),
  limit: z.coerce.number().min(1).max(50).default(20),
});

export const replyBodySchema = z.object({
  body: z.string().min(1, 'Reply body is required').max(2000),
});

export type SendMessageBody = z.infer<typeof sendMessageBodySchema>;
export type InboxQuery = z.infer<typeof inboxQuerySchema>;
export type ReplyBody = z.infer<typeof replyBodySchema>;
