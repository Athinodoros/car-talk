# Car Post All

## Project Overview

**Project Name**: Car Post All
**Description**: A mobile app that lets users leave and read messages attached to cars using the license plate as the key. Think of it as a digital note on someone's windshield — anyone can message any car, and if the owner is registered, they receive it in real time.

**Business Context**: End users are any car owner or driver. The app solves the problem of needing to communicate with a car's owner when you can't find them — parking issues, compliments, warnings about lights left on, community coordination, etc.

**Success Metrics**:
- User registration growth (plate claims)
- Messages sent per day
- Reply rate (engagement)
- Daily active users
- Ad impression revenue

---

## Project Parameters

| Parameter | Value |
|---|---|
| **Frontend** | Flutter (Dart) — iOS & Android |
| **Backend** | Node.js monolith (TypeScript, Fastify) |
| **Database** | PostgreSQL |
| **Real-Time** | Socket.IO (WebSockets) |
| **Auth** | JWT (access + refresh tokens) |
| **Monetization** | Ads only (Google AdMob) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **License Plate Verification** | None for MVP (claim-based + report system) |
| **Architecture** | Monolith — as slim as possible |
| **CI/CD** | GitHub Actions |
| **Containerization** | Docker + Docker Compose |
| **Team** | Solo developer (AI-assisted) |
| **Timeline** | No hard deadline |

---

## Core Features

1. **Auth & Registration** — Sign up with email + license plate claim. JWT-based sessions.
2. **Messaging** — Send a message to any license plate. Recipient sees it if registered.
3. **Inbox & Sent** — View received and sent messages.
4. **Message Threads & Replies** — Open a message, read it, reply. Thread-based conversation.
5. **Real-Time Updates** — WebSocket-driven live updates for new messages and replies.
6. **Push Notifications** — FCM notifications when a new message or reply arrives.
7. **Ad Integration** — AdMob banner and interstitial ads.
8. **Report System** — Flag inappropriate messages or fraudulent plate claims.

---

## Data Model (High-Level)

```
users
├── id (UUID, PK)
├── email (unique)
├── password_hash
├── display_name
├── created_at
└── updated_at

license_plates
├── id (UUID, PK)
├── user_id (FK → users)
├── plate_number (unique, normalized uppercase, no spaces)
├── state_or_region (optional, for disambiguation)
├── claimed_at
└── is_active

messages
├── id (UUID, PK)
├── sender_id (FK → users)
├── recipient_plate_id (FK → license_plates)
├── subject
├── body
├── is_read
├── created_at
└── updated_at

replies
├── id (UUID, PK)
├── message_id (FK → messages)
├── sender_id (FK → users)
├── body
├── created_at

reports
├── id (UUID, PK)
├── reporter_id (FK → users)
├── reported_user_id (FK → users, nullable)
├── reported_message_id (FK → messages, nullable)
├── reason
├── status (pending, reviewed, resolved)
├── created_at
```

---

## User Roles & Permissions

| Role | Capabilities |
|---|---|
| **Registered User** | Claim plates, send/receive messages, reply, report |
| **Unregistered Visitor** | Can only see the app store listing / onboarding. Must register to use. |
| **Admin** (future) | Review reports, manage users, moderate content |

---

## Tech Stack Summary

```
┌─────────────────────────────────────────────┐
│                 MOBILE APP                   │
│              Flutter (Dart)                  │
│    GoRouter · Riverpod · socket_io_client    │
│    google_mobile_ads · firebase_messaging    │
├─────────────────────────────────────────────┤
│              BACKEND MONOLITH                │
│          Fastify (TypeScript)                │
│   ┌───────────┬──────────┬──────────┐       │
│   │  Auth     │ Messages │ Reports  │       │
│   │  Module   │ Module   │ Module   │       │
│   └───────────┴──────────┴──────────┘       │
│   Socket.IO Server · JWT · Bcrypt            │
│   Drizzle ORM · Zod Validation               │
├─────────────────────────────────────────────┤
│              PostgreSQL                       │
│   Users · License Plates · Messages          │
│   Replies · Reports                          │
└─────────────────────────────────────────────┘
```

---

## Documentation

All planning documents live in `docs/`:

| Document | Description |
|---|---|
| [01-phased-roadmap.md](docs/01-phased-roadmap.md) | What to build, in what order |
| [02-architectural-layers.md](docs/02-architectural-layers.md) | Tasks organized by architectural concern |
| [03-feature-breakdown.md](docs/03-feature-breakdown.md) | Feature-by-feature implementation details |
