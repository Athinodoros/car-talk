import { z } from 'zod';

export const registerDeviceBodySchema = z.object({
  token: z.string().min(1, 'Device token is required'),
  platform: z.enum(['ios', 'android']),
});

export type RegisterDeviceBody = z.infer<typeof registerDeviceBodySchema>;
