import { Server as SocketIOServer } from 'socket.io';

export class SocketService {
  private io: SocketIOServer | null = null;
  private connectedUsers = new Set<string>();

  setServer(io: SocketIOServer) {
    this.io = io;
  }

  addUser(userId: string) {
    this.connectedUsers.add(userId);
  }

  removeUser(userId: string) {
    this.connectedUsers.delete(userId);
  }

  isUserConnected(userId: string): boolean {
    return this.connectedUsers.has(userId);
  }

  emitToUser(userId: string, event: string, data: unknown) {
    if (this.io) {
      this.io.to(`user:${userId}`).emit(event, data);
    }
  }
}

export const socketService = new SocketService();
