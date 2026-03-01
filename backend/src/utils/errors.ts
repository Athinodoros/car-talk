import { FastifyInstance } from 'fastify';

export function createHttpError(fastify: FastifyInstance, statusCode: number, message: string) {
  return fastify.httpErrors.createError(statusCode, message);
}
