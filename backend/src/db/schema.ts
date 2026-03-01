import { pgTable, uuid, varchar, text, boolean, timestamp, index, uniqueIndex } from 'drizzle-orm/pg-core';
import { relations } from 'drizzle-orm';

export const users = pgTable('users', {
  id: uuid('id').primaryKey().defaultRandom(),
  email: varchar('email', { length: 255 }).unique().notNull(),
  passwordHash: varchar('password_hash', { length: 255 }).notNull(),
  displayName: varchar('display_name', { length: 100 }).notNull(),
  refreshTokenHash: varchar('refresh_token_hash', { length: 255 }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
});

export const licensePlates = pgTable('license_plates', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'set null' }),
  plateNumber: varchar('plate_number', { length: 20 }).unique().notNull(),
  stateOrRegion: varchar('state_or_region', { length: 50 }),
  claimedAt: timestamp('claimed_at', { withTimezone: true }),
  isActive: boolean('is_active').default(true).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_plates_user_id').on(table.userId),
  index('idx_plates_plate_number').on(table.plateNumber),
]);

export const messages = pgTable('messages', {
  id: uuid('id').primaryKey().defaultRandom(),
  senderId: uuid('sender_id').notNull().references(() => users.id),
  recipientPlateId: uuid('recipient_plate_id').notNull().references(() => licensePlates.id),
  subject: varchar('subject', { length: 100 }),
  body: text('body').notNull(),
  isRead: boolean('is_read').default(false).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_messages_recipient').on(table.recipientPlateId, table.createdAt),
  index('idx_messages_sender').on(table.senderId, table.createdAt),
]);

export const replies = pgTable('replies', {
  id: uuid('id').primaryKey().defaultRandom(),
  messageId: uuid('message_id').notNull().references(() => messages.id, { onDelete: 'cascade' }),
  senderId: uuid('sender_id').notNull().references(() => users.id),
  body: text('body').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_replies_message').on(table.messageId, table.createdAt),
]);

export const reports = pgTable('reports', {
  id: uuid('id').primaryKey().defaultRandom(),
  reporterId: uuid('reporter_id').notNull().references(() => users.id),
  reportedUserId: uuid('reported_user_id').references(() => users.id),
  reportedMessageId: uuid('reported_message_id').references(() => messages.id),
  reason: varchar('reason', { length: 50 }).notNull(),
  description: text('description'),
  status: varchar('status', { length: 20 }).default('pending').notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  uniqueIndex('idx_reports_unique').on(table.reporterId, table.reportedMessageId),
]);

export const deviceTokens = pgTable('device_tokens', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull().references(() => users.id, { onDelete: 'cascade' }),
  token: varchar('token', { length: 500 }).unique().notNull(),
  platform: varchar('platform', { length: 10 }).notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull(),
}, (table) => [
  index('idx_device_tokens_user').on(table.userId),
]);

// Relations
export const usersRelations = relations(users, ({ many }) => ({
  plates: many(licensePlates),
  sentMessages: many(messages),
  replies: many(replies),
  reports: many(reports),
  deviceTokens: many(deviceTokens),
}));

export const licensePlatesRelations = relations(licensePlates, ({ one, many }) => ({
  user: one(users, { fields: [licensePlates.userId], references: [users.id] }),
  messages: many(messages),
}));

export const messagesRelations = relations(messages, ({ one, many }) => ({
  sender: one(users, { fields: [messages.senderId], references: [users.id] }),
  recipientPlate: one(licensePlates, { fields: [messages.recipientPlateId], references: [licensePlates.id] }),
  replies: many(replies),
}));

export const repliesRelations = relations(replies, ({ one }) => ({
  message: one(messages, { fields: [replies.messageId], references: [messages.id] }),
  sender: one(users, { fields: [replies.senderId], references: [users.id] }),
}));

export const reportsRelations = relations(reports, ({ one }) => ({
  reporter: one(users, { fields: [reports.reporterId], references: [users.id], relationName: 'reporter' }),
  reportedUser: one(users, { fields: [reports.reportedUserId], references: [users.id], relationName: 'reportedUser' }),
  reportedMessage: one(messages, { fields: [reports.reportedMessageId], references: [messages.id] }),
}));

export const deviceTokensRelations = relations(deviceTokens, ({ one }) => ({
  user: one(users, { fields: [deviceTokens.userId], references: [users.id] }),
}));
