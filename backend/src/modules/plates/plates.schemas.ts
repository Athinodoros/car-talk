import { z } from 'zod';

export const claimPlateBodySchema = z.object({
  plateNumber: z.string().min(1, 'Plate number is required').max(20),
  stateOrRegion: z.string().max(50).optional(),
});

export type ClaimPlateBody = z.infer<typeof claimPlateBodySchema>;
