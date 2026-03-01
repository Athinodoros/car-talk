import { Server as HttpServer } from 'node:http';
import { Server as SocketIOServer } from 'socket.io';
import { FastifyInstance } from 'fastify';
import { socketService } from './socket-service.js';

export function setupSocketIO(fastify: FastifyInstance, httpServer: HttpServer) {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  socketService.setServer(io);

  // JWT authentication middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token as string | undefined;
    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const payload = fastify.jwt.verify<{ id: string; email: string }>(token);
      socket.data.userId = payload.id;
      socket.data.email = payload.email;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId as string;
    fastify.log.info({ userId }, 'Socket connected');

    // Join user-specific room
    socket.join(`user:${userId}`);
    socketService.addUser(userId);

    socket.on('disconnect', () => {
      fastify.log.info({ userId }, 'Socket disconnected');
      socketService.removeUser(userId);
    });
  });

  return io;
}
