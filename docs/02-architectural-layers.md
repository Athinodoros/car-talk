# Car Post All — Architectural Layers

> Tasks organized by architectural concern. Maintains clean separation of concerns within the monolith.
> Cross-references Phase IDs from [01-phased-roadmap.md](01-phased-roadmap.md).

---

## Layer Overview

```
┌─────────────────────────────────────────────────────────┐
│                    MOBILE APP (Flutter / Dart)            │
│  ┌──────────┬──────────┬──────────┬──────────┐          │
│  │  Auth    │  Inbox   │  Send    │ Profile  │  Screens │
│  └──────────┴──────────┴──────────┴──────────┘          │
│  ┌──────────────────────────────────────────────┐       │
│  │  State Management (Riverpod)                 │       │
│  ├──────────────────────────────────────────────┤       │
│  │  API Client (Dio) + socket_io_client          │       │
│  ├──────────────────────────────────────────────┤       │
│  │  google_mobile_ads · firebase_messaging       │       │
│  │  flutter_secure_storage                       │       │
│  └──────────────────────────────────────────────┘       │
├─────────────────────────────────────────────────────────┤
│                BACKEND MONOLITH (Fastify)                │
│  ┌──────────────────────────────────────────────┐       │
│  │  HTTP Routes + Middleware (JWT, Rate Limit)   │       │
│  ├──────────┬──────────┬──────────┬──────────┐  │       │
│  │  Auth    │ Messages │  Plates  │ Reports  │  │ Mods  │
│  │  Module  │ Module   │  Module  │ Module   │  │       │
│  ├──────────┴──────────┴──────────┴──────────┤  │       │
│  │  Socket.IO Server (real-time events)       │  │       │
│  ├────────────────────────────────────────────┤  │       │
│  │  Notification Service (FCM push)           │  │       │
│  ├────────────────────────────────────────────┤  │       │
│  │  Drizzle ORM (data access layer)           │  │       │
│  └────────────────────────────────────────────┘  │       │
├─────────────────────────────────────────────────────────┤
│                    PostgreSQL                            │
│  users · license_plates · messages · replies · reports   │
│  device_tokens                                           │
├─────────────────────────────────────────────────────────┤
│               INFRASTRUCTURE                             │
│  Docker · Docker Compose · GitHub Actions · Sentry       │
└─────────────────────────────────────────────────────────┘
```

---

## 1. Infrastructure & Platform Layer

Tasks that set up the development environment, containers, CI/CD, and deployment infrastructure.

| Task ID | Responsibility | Phase | Depends On |
|---------|---------------|-------|------------|
| INFRA-INF-001 | Initialize project structure | 0 | — |
| INFRA-INF-002 | Docker & Docker Compose setup | 0 | INFRA-INF-001 |
| INFRA-INF-003 | CI/CD pipeline (GitHub Actions) | 0 | INFRA-INF-001 |
| DEPLOY-INF-001 | Production Docker & deployment | 6 | All prior |
| DEPLOY-INF-002 | Database backup & recovery | 6 | DEPLOY-INF-001 |
| DEPLOY-INF-003 | App store preparation | 6 | ADS-FE-001, UI-FE-009 |

### Key Decisions

- **Single container** for the backend monolith — no service mesh, no orchestrator.
- **Docker Compose** for local dev (backend + postgres) and optionally for production (backend + postgres + monitoring).
- **Flutter runs natively** on device/emulator — NOT containerized. CI uses `subosito/flutter-action`.
- **GitHub Actions** for CI: lint → typecheck/analyze → test → build. Separate jobs for backend and mobile.
- **Production hosting**: lightweight VPS (Fly.io, Railway, or bare Docker on a VPS). No Kubernetes.

### Directory Structure

```
car-post-all/
├── backend/                        # Fastify monolith (TypeScript)
│   ├── Dockerfile
│   ├── src/
│   │   ├── index.ts                # Fastify app entry
│   │   ├── config/                 # Environment config
│   │   ├── modules/
│   │   │   ├── auth/               # Auth routes, handlers, utils
│   │   │   ├── messages/           # Message routes, handlers
│   │   │   ├── plates/             # Plate management
│   │   │   ├── reports/            # Report system
│   │   │   └── notifications/      # FCM push logic
│   │   ├── socket/                 # Socket.IO setup and handlers
│   │   ├── db/
│   │   │   ├── schema.ts           # Drizzle schema definitions
│   │   │   ├── migrations/         # SQL migrations
│   │   │   └── seed.ts             # Dev seed data
│   │   ├── middleware/             # JWT auth, rate limiting
│   │   └── utils/                  # Shared utilities
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   ├── package.json
│   └── tsconfig.json
├── mobile/                         # Flutter app (Dart)
│   ├── lib/
│   │   ├── main.dart               # App entry, ProviderScope, init
│   │   ├── app.dart                # MaterialApp.router + GoRouter
│   │   ├── config/                 # Constants, environment config
│   │   ├── models/                 # Freezed data models
│   │   ├── providers/              # Riverpod providers (auth, inbox, etc.)
│   │   ├── repositories/           # API client (Dio), socket client
│   │   ├── screens/                # Full-page screen widgets
│   │   ├── widgets/                # Reusable UI widgets
│   │   ├── router/                 # GoRouter configuration
│   │   └── utils/                  # Helpers, extensions, formatters
│   ├── test/                       # Widget tests
│   ├── integration_test/           # E2E integration tests
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── docker-compose.yml
├── docker-compose.prod.yml
├── .github/workflows/ci.yml
└── README.md
```

---

## 2. Database Layer

Tasks related to schema design, migrations, and data access.

| Task ID | Responsibility | Phase | Depends On |
|---------|---------------|-------|------------|
| INFRA-DB-001 | PostgreSQL schema & migrations | 0 | INFRA-INF-002 |

### Schema Design

```sql
-- Users table
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- License plates (separate for future multi-plate support)
CREATE TABLE license_plates (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    plate_number VARCHAR(20) UNIQUE NOT NULL,  -- normalized: uppercase, no spaces
    state_or_region VARCHAR(50),
    claimed_at  TIMESTAMPTZ,
    is_active   BOOLEAN DEFAULT true,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_plates_plate_number ON license_plates(plate_number);
CREATE INDEX idx_plates_user_id ON license_plates(user_id);

-- Messages
CREATE TABLE messages (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id         UUID NOT NULL REFERENCES users(id),
    recipient_plate_id UUID NOT NULL REFERENCES license_plates(id),
    subject           VARCHAR(100),
    body              TEXT NOT NULL,
    is_read           BOOLEAN DEFAULT false,
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_recipient ON messages(recipient_plate_id, created_at DESC);
CREATE INDEX idx_messages_sender ON messages(sender_id, created_at DESC);

-- Replies (flat, not nested)
CREATE TABLE replies (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id  UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    sender_id   UUID NOT NULL REFERENCES users(id),
    body        TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_replies_message ON replies(message_id, created_at);

-- Reports
CREATE TABLE reports (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id       UUID NOT NULL REFERENCES users(id),
    reported_user_id  UUID REFERENCES users(id),
    reported_message_id UUID REFERENCES messages(id),
    reason            VARCHAR(50) NOT NULL,  -- spam, harassment, fraudulent_plate, other
    description       TEXT,
    status            VARCHAR(20) DEFAULT 'pending',  -- pending, reviewed, resolved
    created_at        TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_reports_unique ON reports(reporter_id, reported_message_id)
    WHERE reported_message_id IS NOT NULL;

-- Device tokens for push notifications
CREATE TABLE device_tokens (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       VARCHAR(500) UNIQUE NOT NULL,
    platform    VARCHAR(10) NOT NULL,  -- ios, android
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_device_tokens_user ON device_tokens(user_id);
```

### Data Access Patterns

| Query | Index Used | Frequency |
|-------|-----------|-----------|
| Get inbox (messages by plate) | `idx_messages_recipient` | Very High |
| Get sent messages | `idx_messages_sender` | High |
| Get replies for message | `idx_replies_message` | High |
| Look up plate by number | `idx_plates_plate_number` | High |
| Get device tokens for push | `idx_device_tokens_user` | Medium |

---

## 3. Backend Modules Layer

All backend logic lives in the monolith, organized as feature modules with clean boundaries.

| Task ID | Responsibility | Phase | Module |
|---------|---------------|-------|--------|
| AUTH-BE-001 | Registration & login | 1 | `auth` |
| AUTH-BE-002 | License plate management | 1 | `plates` |
| MSG-BE-001 | Message sending | 1 | `messages` |
| MSG-BE-002 | Inbox & sent retrieval | 1 | `messages` |
| MSG-BE-003 | Reply system | 1 | `messages` |
| RT-BE-001 | WebSocket real-time | 1 | `socket` |
| RT-BE-002 | Push notifications | 1 | `notifications` |
| RPT-BE-001 | Report system | 5 | `reports` |

### Module Boundaries

Each module is a Fastify plugin that:
1. Registers its own routes under a prefix
2. Contains its own handlers and business logic
3. Accesses the DB through the shared Drizzle instance
4. Emits socket events through a shared socket service

```
src/modules/
├── auth/
│   ├── auth.routes.ts      # POST /api/auth/register, /login, /refresh
│   ├── auth.handlers.ts    # Request handlers
│   ├── auth.service.ts     # Business logic (hash, verify, JWT)
│   └── auth.schemas.ts     # Zod validation schemas
├── plates/
│   ├── plates.routes.ts    # POST/GET/DELETE /api/plates
│   ├── plates.handlers.ts
│   ├── plates.service.ts
│   └── plates.schemas.ts
├── messages/
│   ├── messages.routes.ts  # /api/messages/*
│   ├── messages.handlers.ts
│   ├── messages.service.ts # Send, inbox, sent, reply logic
│   └── messages.schemas.ts
├── reports/
│   ├── reports.routes.ts   # POST /api/reports
│   ├── reports.handlers.ts
│   ├── reports.service.ts
│   └── reports.schemas.ts
└── notifications/
    ├── notifications.service.ts  # FCM send logic
    └── notifications.types.ts
```

### API Route Summary

| Method | Path | Module | Auth | Description |
|--------|------|--------|------|-------------|
| POST | `/api/auth/register` | auth | No | Register + claim plate |
| POST | `/api/auth/login` | auth | No | Login → JWT pair |
| POST | `/api/auth/refresh` | auth | Refresh | Rotate tokens |
| GET | `/api/plates` | plates | Yes | List user's plates |
| POST | `/api/plates` | plates | Yes | Claim a plate |
| DELETE | `/api/plates/:id` | plates | Yes | Release a plate |
| POST | `/api/messages` | messages | Yes | Send message to plate |
| GET | `/api/messages/inbox` | messages | Yes | Paginated inbox |
| GET | `/api/messages/sent` | messages | Yes | Paginated sent |
| GET | `/api/messages/unread-count` | messages | Yes | Unread message count |
| GET | `/api/messages/:id` | messages | Yes | Message detail + replies |
| PATCH | `/api/messages/:id/read` | messages | Yes | Mark as read |
| POST | `/api/messages/:id/replies` | messages | Yes | Add reply |
| POST | `/api/reports` | reports | Yes | Submit report |
| POST | `/api/devices` | notifications | Yes | Register device token |
| DELETE | `/api/devices/:token` | notifications | Yes | Remove device token |
| GET | `/health` | — | No | Health check |
| GET | `/metrics` | — | No | Prometheus metrics |

### Shared Services

These are not separate modules but shared utilities injected via Fastify's decorator pattern:

- **SocketService**: Wraps Socket.IO server; provides `emitToUser(userId, event, data)` method
- **NotificationService**: Wraps FCM; provides `sendPush(userId, notification)` method
- **DB**: Drizzle ORM instance, available as `fastify.db`

---

## 4. Frontend Layer

Flutter screens, widgets, and client-side infrastructure.

| Task ID | Responsibility | Phase | Area |
|---------|---------------|-------|------|
| UI-FE-001 | Navigation & app shell | 2 | Navigation |
| UI-FE-002 | Auth screens | 2 | Screens |
| UI-FE-003 | Inbox screen | 2 | Screens |
| UI-FE-004 | Send message screen | 2 | Screens |
| UI-FE-005 | Message detail & thread | 2 | Screens |
| UI-FE-006 | Sent messages screen | 2 | Screens |
| UI-FE-007 | Profile screen | 2 | Screens |
| UI-FE-008 | Socket.IO & push integration | 2 | Infrastructure |
| ADS-FE-001 | AdMob integration | 5 | Monetization |
| RPT-FE-001 | Report UI | 5 | Screens |
| UI-FE-009 | UX polish & animations | 5 | Polish |

### State Management Strategy

Use **Riverpod** (with code generation `@riverpod`) for reactive state management:

| Provider | State | Updated By |
|----------|-------|-----------|
| `authProvider` | user, tokens, isAuthenticated | Login, register, logout, token refresh |
| `inboxProvider` | AsyncValue<List<Message>>, unreadCount, cursor | API fetch, socket `new_message` event |
| `sentProvider` | AsyncValue<List<Message>>, cursor | API fetch |
| `threadProvider(messageId)` | AsyncValue<MessageThread> (message + replies) | API fetch, socket `new_reply` event |

### Screen Navigation Map (GoRouter)

```
GoRouter
├── /login           → LoginScreen
├── /register        → RegisterScreen
└── / (ShellRoute with BottomNavigationBar)
    ├── /inbox                → InboxScreen
    │   └── /inbox/:id        → MessageDetailScreen
    ├── /send                 → SendMessageScreen
    ├── /sent                 → SentScreen
    │   └── /sent/:id         → MessageDetailScreen (reused)
    └── /profile              → ProfileScreen
```

### Key Flutter Packages

| Package | Purpose |
|---------|---------|
| `go_router` | Declarative, typed navigation |
| `flutter_riverpod` + `riverpod_annotation` | State management + code generation |
| `freezed` + `json_serializable` | Immutable data models with JSON serialization |
| `dio` | HTTP client with interceptors |
| `socket_io_client` | Real-time WebSocket connection |
| `firebase_messaging` + `firebase_core` | Push notifications (FCM) |
| `google_mobile_ads` | AdMob banner + interstitial ads |
| `flutter_secure_storage` | Secure token persistence |
| `connectivity_plus` | Network state monitoring for reconnection |
| `package_info_plus` | App version info for profile screen |
| `shimmer` | Skeleton loading effects |
| `mocktail` | Mocking for widget tests |

---

## 5. Testing Infrastructure Layer

| Task ID | Responsibility | Phase | Scope |
|---------|---------------|-------|-------|
| TEST-BE-001 | Backend unit tests | 3 | Backend |
| TEST-BE-002 | Backend integration tests | 3 | Backend + DB |
| TEST-FE-001 | Frontend widget tests | 3 | Mobile |
| TEST-E2E-001 | End-to-end tests | 3 | Full stack |

### Testing Strategy

```
                    ┌───────────────┐
                    │  E2E Tests    │  Flutter integration_test
                    │  (few, slow)  │  Full user flows
                    ├───────────────┤
                    │  Integration  │  Vitest + real DB
                    │  (moderate)   │  API endpoint tests
                    ├───────────────┤
                    │  Unit/Widget  │  Vitest / flutter_test
                    │  (many, fast) │  Business logic + widgets
                    └───────────────┘
```

| Layer | Framework | What It Tests |
|-------|-----------|---------------|
| Unit (backend) | Vitest | Hashing, JWT, validation, normalization, rate limit logic |
| Integration (backend) | Vitest + testcontainers or test DB | Full request → DB → response cycle |
| Widget (frontend) | flutter_test + mocktail | Screen rendering, form validation, state updates |
| E2E | Flutter integration_test | Register → send → receive → reply → notification |

---

## 6. Observability Layer

| Task ID | Responsibility | Phase | Area |
|---------|---------------|-------|------|
| OBS-BE-001 | Structured logging | 4 | Logging |
| OBS-BE-002 | Health checks & metrics | 4 | Monitoring |
| OBS-BE-003 | Error tracking | 4 | Error capture |

### Observability Stack

| Concern | Tool | Notes |
|---------|------|-------|
| Logging | Pino (built into Fastify) | JSON structured logs, request IDs |
| Metrics | prom-client → Prometheus | Request counts, latencies, socket connections |
| Dashboards | Grafana (optional, Docker Compose) | Visualize Prometheus metrics |
| Error Tracking | Sentry (free tier) | Uncaught exceptions, request context |

### Key Metrics to Track

| Metric | Type | Description |
|--------|------|-------------|
| `http_requests_total` | Counter | Total HTTP requests by method, path, status |
| `http_request_duration_seconds` | Histogram | Request latency distribution |
| `ws_connections_active` | Gauge | Current WebSocket connections |
| `messages_sent_total` | Counter | Messages sent |
| `push_notifications_sent_total` | Counter | Push notifications delivered |
| `push_notifications_failed_total` | Counter | Push notification failures |

---

## 7. Documentation Layer

Follows the project structure standard from the master prompt. READMEs maintained in every significant directory.

| Location | Purpose |
|----------|---------|
| `/README.md` | Project overview, setup instructions |
| `/docs/` | Planning documents (this file, roadmap, feature breakdown) |
| `/backend/README.md` | Backend architecture, how to run, module guide |
| `/backend/src/modules/*/README.md` | Per-module documentation (created as modules are built) |
| `/mobile/README.md` | Flutter app setup, screen guide, conventions |

### API Documentation

- Fastify Swagger plugin auto-generates OpenAPI spec from Zod schemas
- Available at `/api/docs` in development
- Exported as `openapi.json` for CI validation

---

## Cross-Layer Dependencies

```
Infrastructure ──→ Database ──→ Backend Modules ──→ Frontend (Flutter)
     │                              │                  │
     │                              ▼                  ▼
     │                        Socket.IO ◄──── socket_io_client (Dart)
     │                              │
     │                              ▼
     │                        FCM Push ──────────→ firebase_messaging
     │
     ▼
   CI/CD ──→ Tests ──→ Deploy
```
