# CLAUDE.md — Car Post All

This file provides guidance to Claude Code when working in the `car-post-all` project.

## Project Overview

A mobile app that lets users leave and read messages attached to cars using the license plate as the key. Monolith backend with a Flutter frontend.

## Architecture

- **Backend**: Fastify monolith (TypeScript) — single deployable container
- **Frontend**: Flutter (Dart) — iOS & Android
- **Database**: PostgreSQL with Drizzle ORM
- **Real-Time**: Socket.IO (WebSockets)
- **Auth**: JWT (access + refresh tokens)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **Monetization**: Ads only (Google AdMob)
- **CI/CD**: GitHub Actions
- **Containerization**: Docker + Docker Compose (remote Docker host at `192.168.1.164`)

## Project Structure

```
car-post-all/
├── backend/                    # Fastify monolith (TypeScript)
│   ├── src/
│   │   ├── index.ts            # App entry point
│   │   ├── config/             # Environment config
│   │   ├── modules/
│   │   │   ├── auth/           # Registration, login, JWT
│   │   │   ├── plates/         # License plate CRUD
│   │   │   ├── messages/       # Send, inbox, sent, replies
│   │   │   ├── reports/        # Report/flag system
│   │   │   └── notifications/  # FCM push logic
│   │   ├── socket/             # Socket.IO server + handlers
│   │   ├── db/
│   │   │   ├── schema.ts       # Drizzle schema definitions
│   │   │   ├── migrations/     # SQL migrations
│   │   │   └── seed.ts         # Development seed data
│   │   ├── middleware/         # JWT auth, rate limiting
│   │   └── utils/              # Shared utilities
│   ├── tests/
│   │   ├── unit/
│   │   └── integration/
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
├── mobile/                     # Flutter app (Dart)
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── app.dart            # MaterialApp + GoRouter setup
│   │   ├── config/             # Environment config, constants
│   │   ├── models/             # Data models (freezed)
│   │   ├── providers/          # Riverpod providers
│   │   ├── repositories/       # API client, socket client
│   │   ├── screens/            # Screen widgets
│   │   ├── widgets/            # Reusable UI widgets
│   │   ├── router/             # GoRouter configuration
│   │   └── utils/              # Helpers, extensions
│   ├── test/                   # Widget tests
│   ├── integration_test/       # E2E integration tests
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── docs/                       # Planning documents
│   ├── 01-phased-roadmap.md
│   ├── 02-architectural-layers.md
│   └── 03-feature-breakdown.md
├── docker-compose.yml
├── docker-compose.prod.yml
├── .github/workflows/ci.yml
├── README.md
└── CLAUDE.md                   # This file
```

## Working Rules

### General

- **This is a monolith.** All backend code lives in a single Fastify application. Do NOT create separate services or microservices.
- **Keep it slim.** Minimize dependencies. Prefer built-in Fastify features (backend) and Flutter SDK features (mobile) over external libraries when possible.
- **Strict typing.** Backend uses TypeScript (no `any`). Mobile uses Dart with strict analysis options (`strict-casts`, `strict-raw-types`).
- **Ask when unclear.** If there is any ambiguity about which approach to take, ask the user before acting.

### Backend Rules

- **Module pattern.** Each feature is a Fastify plugin in `src/modules/<name>/`. Each module has: `routes.ts`, `handlers.ts`, `service.ts`, `schemas.ts`.
- **Validation.** Use Zod for all request/response validation. Schemas live in `<module>.schemas.ts`.
- **ORM.** Use Drizzle ORM for all database access. Schema defined in `src/db/schema.ts`. Never write raw SQL outside of migrations.
- **Auth.** JWT via `@fastify/jwt`. Access tokens (15 min) + refresh tokens (7 days). Auth middleware in `src/middleware/`.
- **Error handling.** Use Fastify's built-in error handling. Throw `httpErrors` from `@fastify/sensible`. Never swallow errors silently.
- **Logging.** Use Fastify's built-in Pino logger. Structured JSON logs. Include request IDs. Never log passwords, tokens, or PII.
- **Rate limiting.** Use `@fastify/rate-limit` on sensitive endpoints (auth, message sending).
- **Socket events.** Emit via the shared socket service (`socketService.emitToUser()`). Never import Socket.IO directly in module handlers.

### Frontend / Mobile Rules (Flutter / Dart)

- **GoRouter** for all navigation. Typed routes with path parameters and redirect guards.
- **Riverpod** for state management. Use `@riverpod` code generation where possible. One provider family per domain: auth, inbox, sent, thread.
- **Freezed** for data models. All API response models use `@freezed` with `fromJson`/`toJson`.
- **Dio** for HTTP requests. Single Dio instance with interceptors for JWT auth and token refresh.
- **Secure storage.** Tokens stored in `flutter_secure_storage`. Never use `SharedPreferences` for sensitive data.
- **socket_io_client** for WebSocket connection. Connects on login, disconnects on logout. Events update Riverpod state.
- **google_mobile_ads** for AdMob. Test ad units in development. Production ad unit IDs in environment config only.
- **Theming.** Use `ThemeData` and `Theme.of(context)`. All colors and text styles from theme. Support dark mode via system setting.
- **No magic strings.** Use constants for route paths, API endpoints, socket event names, and asset paths.
- **Widget composition.** Prefer small, composable widgets. Extract reusable widgets into `lib/widgets/`.

### Database Rules

- **Migrations only.** Schema changes go through Drizzle migrations. Never modify the DB manually.
- **UUIDs.** All primary keys are UUID (v7 preferred for time-sortable IDs).
- **License plates.** Always normalized: uppercase, stripped of spaces and hyphens. Use the `normalizePlate()` utility.
- **Indexes.** Every foreign key and frequent query column must be indexed. Check `02-architectural-layers.md` for the index plan.

### Testing Rules

- **Backend unit tests**: Vitest. Test business logic in `service.ts` files.
- **Backend integration tests**: Vitest with a real test database. Test full HTTP request → response cycles.
- **Frontend widget tests**: `flutter_test`. Test screen widgets with mocked providers.
- **Frontend E2E tests**: `integration_test` package (Flutter built-in).
- **Minimum coverage**: 80% on backend `src/modules/` business logic.

### Git & CI Rules

- **Conventional commits.** Format: `type(scope): description`. Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `ci`.
- **Branch naming.** Format: `type/short-description` (e.g., `feat/inbox-screen`, `fix/auth-refresh`).
- **CI must pass.** Lint, typecheck/analyze, and tests must all pass before merging.

### Docker (Remote Host)

- **Docker runs on a remote machine** at `192.168.1.164`. It is NOT local.
- All `docker` and `docker-compose` commands must target the remote host using `DOCKER_HOST`.
- Set the environment variable: `export DOCKER_HOST=tcp://192.168.1.164:2375` or pass `-H tcp://192.168.1.164:2375` per command.
- The backend API and Postgres will be reachable at `192.168.1.164:<port>` from the dev machine.
- The Flutter app should use `192.168.1.164` as the API base URL during development.

## Common Commands

```bash
# Backend (local development without Docker)
cd backend && npm run dev          # Start dev server with hot-reload
cd backend && npm run build        # TypeScript build
cd backend && npm run test         # Run unit tests
cd backend && npm run test:int     # Run integration tests
cd backend && npm run db:migrate   # Run Drizzle migrations
cd backend && npm run db:seed      # Seed development data

# Mobile (Flutter)
cd mobile && flutter run              # Run app on connected device/emulator
cd mobile && flutter run --debug      # Run in debug mode
cd mobile && flutter test             # Run widget tests
cd mobile && flutter test integration_test  # Run E2E integration tests
cd mobile && flutter analyze          # Run Dart static analysis
cd mobile && flutter pub get          # Install dependencies
cd mobile && dart run build_runner build --delete-conflicting-outputs  # Generate freezed/riverpod code

# Docker (remote host at 192.168.1.164)
DOCKER_HOST=tcp://192.168.1.164:2375 docker compose up -d    # Start backend + Postgres
DOCKER_HOST=tcp://192.168.1.164:2375 docker compose down      # Stop all services
DOCKER_HOST=tcp://192.168.1.164:2375 docker compose logs -f   # Follow logs
```

## Key API Endpoints

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| POST | `/api/auth/register` | No | Register + claim plate |
| POST | `/api/auth/login` | No | Login → JWT pair |
| POST | `/api/auth/refresh` | Refresh | Rotate tokens |
| GET | `/api/plates` | Yes | List user's plates |
| POST | `/api/plates` | Yes | Claim a plate |
| DELETE | `/api/plates/:id` | Yes | Release a plate |
| POST | `/api/messages` | Yes | Send message to plate |
| GET | `/api/messages/inbox` | Yes | Paginated inbox |
| GET | `/api/messages/sent` | Yes | Paginated sent |
| GET | `/api/messages/unread-count` | Yes | Unread count |
| GET | `/api/messages/:id` | Yes | Message + replies |
| PATCH | `/api/messages/:id/read` | Yes | Mark as read |
| POST | `/api/messages/:id/replies` | Yes | Add reply |
| POST | `/api/reports` | Yes | Submit report |
| POST | `/api/devices` | Yes | Register FCM token |
| DELETE | `/api/devices/:token` | Yes | Remove FCM token |
| GET | `/health` | No | Health check |

## Socket.IO Events

| Event | Direction | When |
|-------|-----------|------|
| `new_message` | Server → Client | Message sent to user's plate |
| `new_reply` | Server → Client | Reply on user's thread |
| `message_read` | Server → Client | Recipient read user's message |
| `unread_count` | Server → Client | Unread count changed |

## Planning Documents

Detailed task breakdowns with RALF loops, acceptance criteria, and cross-references:

- `docs/01-phased-roadmap.md` — 33 tasks across 7 phases
- `docs/02-architectural-layers.md` — Layer-by-layer architecture with DB schema and API routes
- `docs/03-feature-breakdown.md` — Feature-by-feature implementation with API contracts and business rules
