# Car Post All — Phased Roadmap

> What to build and in what order. Each phase has clear completion criteria and dependencies.
> Architecture: **Monolith** (adapted from microservices template — all backend modules live in a single deployable).

---

## Phase 0: Project Setup & Infrastructure

**Goal**: Scaffold the project, configure tooling, and get a local dev environment running.
**Depends On**: Nothing — this is the starting point.

---

### INFRA-INF-001: Initialize Project Structure

- **Responsibility**: Set up the project directory structure for the monolith backend and Flutter frontend.
- **Phase**: 0
- **Depends On**: None
- **Skills Needed**: DevOps, TypeScript, Dart/Flutter

**Deliverables**:
1. Root project structure with `backend/` and `mobile/` directories
2. `backend/` directory with Fastify + TypeScript scaffold and `package.json`
3. `mobile/` directory with Flutter project (`flutter create`)
4. `.gitignore`, `.editorconfig`
5. ESLint + Prettier configuration for backend
6. `analysis_options.yaml` with strict Dart linting for mobile

**RALF Loop**:
- **Retrieval**: Review Fastify, Flutter CLI, and project setup docs
- **Analysis**: Determine folder structure that keeps monolith slim; backend is Node/TS, mobile is Dart — no shared workspace needed
- **Logical Reasoning**: Backend uses npm; mobile uses `pub`. No monorepo workspace coupling — they are independent projects in the same repo.
- **Feedback**: `npm install` succeeds in backend; `flutter pub get` succeeds in mobile; linting passes in both

**Acceptance Criteria**:
- [ ] `backend/` builds and starts an empty Fastify server
- [ ] `mobile/` builds and launches on iOS simulator and Android emulator
- [ ] Linting and formatting work in both projects

---

### INFRA-INF-002: Docker & Docker Compose Setup

- **Responsibility**: Containerize the backend and database for local development.
- **Phase**: 0
- **Depends On**: INFRA-INF-001
- **Skills Needed**: DevOps, Docker

**Deliverables**:
1. `Dockerfile` for the backend monolith
2. `docker-compose.yml` with backend + PostgreSQL services
3. Environment variable management (`.env.example`)
4. Volume mounts for hot-reload in development

**RALF Loop**:
- **Retrieval**: Fastify Docker best practices, PostgreSQL Docker image docs
- **Analysis**: Minimal container image (node:alpine base)
- **Logical Reasoning**: Single backend container + Postgres container. No orchestrator needed for monolith. Flutter app runs natively on device/emulator — not containerized.
- **Feedback**: `docker-compose up` starts both services; backend connects to DB

**Acceptance Criteria**:
- [ ] `docker-compose up` brings up backend + Postgres
- [ ] Backend hot-reloads on file changes
- [ ] Database data persists across restarts via volume

---

### INFRA-DB-001: PostgreSQL Schema & Migrations

- **Responsibility**: Design the initial database schema and set up migration tooling.
- **Phase**: 0
- **Depends On**: INFRA-INF-002
- **Skills Needed**: Database Design, TypeScript

**Deliverables**:
1. Drizzle ORM setup and configuration
2. Initial migration: `users`, `license_plates`, `messages`, `replies`, `reports` tables
3. Seed script for development data
4. Database connection pool configuration

**RALF Loop**:
- **Retrieval**: Drizzle ORM docs, PostgreSQL best practices for UUID PKs and indexes
- **Analysis**: Define indexes on `license_plates.plate_number`, `messages.recipient_plate_id`, `messages.sender_id`
- **Logical Reasoning**: Normalize plates (uppercase, strip spaces). Use UUID v7 for time-sortable IDs. Separate `license_plates` from `users` to allow future multi-plate support.
- **Feedback**: Migrations run cleanly; seed data inserts without errors; queries return expected results

**Acceptance Criteria**:
- [ ] All 5 tables created with correct constraints and indexes
- [ ] Drizzle schema types are generated and usable in backend code
- [ ] Seed script populates test data
- [ ] Migration can be rolled back cleanly

---

### INFRA-INF-003: CI/CD Pipeline (GitHub Actions)

- **Responsibility**: Set up continuous integration for linting, testing, and building.
- **Phase**: 0
- **Depends On**: INFRA-INF-001
- **Skills Needed**: DevOps, GitHub Actions

**Deliverables**:
1. `.github/workflows/ci.yml` — lint, typecheck/analyze, test on push/PR
2. Separate jobs for backend and mobile
3. PostgreSQL service container for backend integration tests
4. Cache configuration for `node_modules` (backend) and Flutter SDK + pub cache (mobile)

**RALF Loop**:
- **Retrieval**: GitHub Actions docs, Flutter CI setup guides
- **Analysis**: Keep CI fast — parallelize backend and mobile jobs
- **Logical Reasoning**: Use service containers for Postgres in CI; cache dependencies; use `subosito/flutter-action` for Flutter setup in CI
- **Feedback**: CI runs green on a clean PR

**Acceptance Criteria**:
- [ ] CI triggers on push to `main` and on PRs
- [ ] Backend lint + typecheck + test pass
- [ ] Mobile `flutter analyze` + `flutter test` pass
- [ ] Pipeline completes in under 5 minutes

---

## Phase 1: MVP Backend Core

**Goal**: Implement auth, messaging, and real-time modules in the monolith.
**Depends On**: Phase 0 complete.

---

### AUTH-BE-001: Auth Module — Registration & Login

- **Responsibility**: Implement user registration (email + password + license plate claim) and JWT-based login.
- **Phase**: 1
- **Depends On**: INFRA-DB-001
- **Skills Needed**: Backend TypeScript, Security

**Deliverables**:
1. `POST /api/auth/register` — create user + claim plate
2. `POST /api/auth/login` — return access + refresh token pair
3. `POST /api/auth/refresh` — rotate refresh token
4. Password hashing with bcrypt (cost factor 12)
5. Zod request validation schemas
6. Auth middleware (JWT verification + user injection)

**RALF Loop**:
- **Retrieval**: JWT best practices, Fastify auth plugin docs, bcrypt security recommendations
- **Analysis**: Access token TTL 15 min, refresh token TTL 7 days. Plates normalized to uppercase, no spaces.
- **Logical Reasoning**: Use `@fastify/jwt` plugin. Store refresh tokens in DB for revocation support. Plate claim is atomic with registration (transaction).
- **Feedback**: Register → login → access protected route works end-to-end; invalid tokens rejected

**Testing Requirements**:
- Unit: password hashing, JWT creation/verification, plate normalization
- Integration: full register → login → protected route flow
- Edge cases: duplicate email, duplicate plate, invalid inputs

**Acceptance Criteria**:
- [ ] User can register with email, password, display name, and plate number
- [ ] Login returns valid JWT pair
- [ ] Refresh token rotation works
- [ ] Duplicate email or plate returns 409
- [ ] Auth middleware protects routes

---

### AUTH-BE-002: License Plate Management

- **Responsibility**: CRUD operations for license plates (claim, release, list own plates).
- **Phase**: 1
- **Depends On**: AUTH-BE-001
- **Skills Needed**: Backend TypeScript

**Deliverables**:
1. `POST /api/plates` — claim an additional plate
2. `GET /api/plates` — list user's claimed plates
3. `DELETE /api/plates/:id` — release a plate claim
4. Plate normalization utility (uppercase, strip whitespace/hyphens)

**RALF Loop**:
- **Retrieval**: License plate format patterns by region
- **Analysis**: MVP supports single plate per user (enforced at DB level). Multi-plate is a future feature.
- **Logical Reasoning**: Keep it simple — one user, one plate for now. Release allows re-claiming by someone else.
- **Feedback**: Claim, list, release cycle works; released plates can be claimed by another user

**Acceptance Criteria**:
- [ ] User can claim a plate (one per user in MVP)
- [ ] User can view their claimed plate
- [ ] User can release a plate
- [ ] Released plates become available

---

### MSG-BE-001: Message Sending Module

- **Responsibility**: Send a message to a license plate.
- **Phase**: 1
- **Depends On**: AUTH-BE-001, INFRA-DB-001
- **Skills Needed**: Backend TypeScript

**Deliverables**:
1. `POST /api/messages` — send message to a plate number
2. Lookup recipient plate → resolve to user (if claimed)
3. Handle unclaimed plates gracefully (message stored, delivered when claimed)
4. Input validation (Zod): subject (optional, max 100 chars), body (required, max 2000 chars), plate number
5. Rate limiting: max 20 messages per hour per user

**RALF Loop**:
- **Retrieval**: Review data model for messages and plates
- **Analysis**: Messages always stored regardless of plate claim status. `recipient_plate_id` links to plate record (created on-the-fly for unclaimed plates or stored as "unclaimed plate" entries).
- **Logical Reasoning**: Create a `license_plates` entry even for unclaimed plates (with `user_id = NULL`). When someone later claims that plate, existing messages become visible. This avoids a separate "pending messages" table.
- **Feedback**: Send to claimed plate → recipient sees it. Send to unclaimed plate → message stored. Claim that plate → messages appear.

**Acceptance Criteria**:
- [ ] User can send a message to any plate number
- [ ] Message appears in recipient's inbox (if plate claimed)
- [ ] Messages to unclaimed plates are stored and delivered on claim
- [ ] Rate limiting enforced
- [ ] Input validation rejects malformed requests

---

### MSG-BE-002: Inbox & Sent Messages Module

- **Responsibility**: Retrieve received and sent messages with pagination.
- **Phase**: 1
- **Depends On**: MSG-BE-001
- **Skills Needed**: Backend TypeScript

**Deliverables**:
1. `GET /api/messages/inbox` — paginated inbox (messages to user's plate)
2. `GET /api/messages/sent` — paginated sent messages
3. `GET /api/messages/:id` — single message with replies
4. `PATCH /api/messages/:id/read` — mark as read
5. Cursor-based pagination (by `created_at`)
6. Unread count endpoint: `GET /api/messages/unread-count`

**RALF Loop**:
- **Retrieval**: Cursor pagination patterns, Drizzle query builder
- **Analysis**: Inbox = messages where `recipient_plate_id` belongs to current user. Sent = messages where `sender_id` is current user.
- **Logical Reasoning**: Cursor-based pagination using `created_at` + `id` for stable ordering. Prefetch reply count for list view.
- **Feedback**: Pagination returns correct pages; read status persists; unread count matches

**Acceptance Criteria**:
- [ ] Inbox returns messages addressed to user's plate, newest first
- [ ] Sent returns messages the user sent, newest first
- [ ] Single message endpoint includes all replies
- [ ] Mark-as-read updates `is_read` flag
- [ ] Unread count is accurate
- [ ] Pagination works correctly with 20 items per page

---

### MSG-BE-003: Reply Module

- **Responsibility**: Reply to a message within a thread.
- **Phase**: 1
- **Depends On**: MSG-BE-002
- **Skills Needed**: Backend TypeScript

**Deliverables**:
1. `POST /api/messages/:id/replies` — add a reply to a message
2. Authorization: only sender and recipient can reply
3. Reply validation (body required, max 2000 chars)
4. Update message `updated_at` on new reply (for sorting active threads)

**RALF Loop**:
- **Retrieval**: Review message data model, thread patterns
- **Analysis**: Flat reply model (no nested replies). Both original sender and plate owner can reply.
- **Logical Reasoning**: Keep it flat — replies are a list under a message. No nesting complexity. Updating `messages.updated_at` on reply lets us sort by "most recently active."
- **Feedback**: Both parties can reply; unauthorized users get 403; replies appear in message detail

**Acceptance Criteria**:
- [ ] Sender and recipient can add replies
- [ ] Unauthorized users cannot reply (403)
- [ ] Replies appear in correct order in message detail
- [ ] Message `updated_at` is refreshed on new reply

---

### RT-BE-001: WebSocket Real-Time Module

- **Responsibility**: Set up Socket.IO for real-time message and reply delivery.
- **Phase**: 1
- **Depends On**: AUTH-BE-001, MSG-BE-001
- **Skills Needed**: Backend TypeScript, WebSockets

**Deliverables**:
1. Socket.IO server integrated into Fastify
2. JWT-based socket authentication (handshake)
3. Per-user rooms (user joins room `user:{userId}` on connect)
4. Events emitted:
   - `new_message` — when a message is sent to user's plate
   - `new_reply` — when a reply is added to a user's message/thread
   - `message_read` — when recipient reads a message (sender notified)
5. Connection lifecycle management (join/leave rooms, heartbeat)

**RALF Loop**:
- **Retrieval**: Socket.IO + Fastify integration docs, JWT socket auth patterns
- **Analysis**: One room per user. Backend emits to room when creating messages/replies. No pub/sub needed for monolith (in-process emit).
- **Logical Reasoning**: Since it's a monolith, Socket.IO can emit events directly in the message/reply creation handlers — no message queue needed. If scaling to multiple instances later, add Redis adapter.
- **Feedback**: Connect with valid JWT → join room → send message → recipient receives real-time event

**Acceptance Criteria**:
- [ ] Socket connects with valid JWT; rejects without
- [ ] New messages trigger `new_message` event to recipient in real time
- [ ] New replies trigger `new_reply` event to both parties
- [ ] Disconnection is handled gracefully (no memory leaks)

---

### RT-BE-002: Push Notification Module

- **Responsibility**: Send push notifications via FCM for offline users.
- **Phase**: 1
- **Depends On**: RT-BE-001
- **Skills Needed**: Backend TypeScript, Firebase

**Deliverables**:
1. FCM integration (Firebase Admin SDK)
2. Device token registration endpoint: `POST /api/devices`
3. Device token removal: `DELETE /api/devices/:token`
4. Notification triggers: new message, new reply (only if user is NOT connected via socket)
5. Notification payload formatting (title, body, data for deep linking)

**RALF Loop**:
- **Retrieval**: Firebase Admin SDK docs, FCM payload limits
- **Analysis**: Check socket connection status before sending push. If user is online (socket connected), skip push to avoid double notification.
- **Logical Reasoning**: Store device tokens in a `device_tokens` table (user_id, token, platform, created_at). Send push only when user has no active socket connections.
- **Feedback**: Disconnect socket → send message → push arrives. Connect socket → send message → no push, only socket event.

**Acceptance Criteria**:
- [ ] Device tokens stored and managed per user
- [ ] Push sent for new messages/replies when user is offline
- [ ] No duplicate notifications (push + socket)
- [ ] Deep link data included in push payload

---

## Phase 2: Frontend Core Features

**Goal**: Build the Flutter app with all core screens and real-time integration.
**Depends On**: Phase 1 (backend API endpoints available).

---

### UI-FE-001: Navigation & App Shell

- **Responsibility**: Set up GoRouter with bottom navigation bar and screen structure.
- **Phase**: 2
- **Depends On**: INFRA-INF-001
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. GoRouter setup with typed routes and redirect guards
2. `BottomNavigationBar` with 4 tabs: Inbox, Send, Sent, Profile
3. Auth redirect: unauthenticated users sent to Login/Register screens
4. Splash screen / loading state while checking auth
5. Unread badge on Inbox tab (using Riverpod provider)

**Acceptance Criteria**:
- [ ] Tab navigation works across all 4 main screens
- [ ] Auth redirect works for unauthenticated users
- [ ] Unread badge reflects actual unread count
- [ ] Routes are typed and type-safe

---

### UI-FE-002: Auth Screens (Register & Login)

- **Responsibility**: Build registration and login screens with form validation.
- **Phase**: 2
- **Depends On**: UI-FE-001, AUTH-BE-001
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. Register screen: email, password, display name, license plate input (`TextFormField` with validators)
2. Login screen: email + password
3. Form validation (client-side via `Form` + `GlobalKey<FormState>`, server error display)
4. License plate `TextInputFormatter` for auto-uppercasing and stripping invalid chars
5. Secure token storage (`flutter_secure_storage`)
6. Auto-login on app launch if refresh token valid

**Acceptance Criteria**:
- [ ] User can register and is navigated to main app
- [ ] User can log in and is navigated to main app
- [ ] Validation errors shown inline under fields
- [ ] Tokens stored securely and persist across app restarts

---

### UI-FE-003: Inbox Screen

- **Responsibility**: Display received messages with real-time updates.
- **Phase**: 2
- **Depends On**: UI-FE-001, MSG-BE-002, RT-BE-001
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. `ListView.builder` with message preview tiles (sender name, subject, timestamp, read status)
2. `RefreshIndicator` for pull-to-refresh
3. Infinite scroll via `ScrollController` with cursor pagination
4. Real-time: new messages appear at top without refresh (Riverpod state update from socket)
5. Unread messages visually distinguished (bold text / dot indicator)
6. Tap to navigate to message detail via GoRouter

**Acceptance Criteria**:
- [ ] Messages load with pagination
- [ ] New messages appear in real-time via socket
- [ ] Unread vs read is visually clear
- [ ] Pull-to-refresh works
- [ ] Tapping opens message detail

---

### UI-FE-004: Send Message Screen

- **Responsibility**: Compose and send a message to a license plate.
- **Phase**: 2
- **Depends On**: UI-FE-001, MSG-BE-001
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. License plate `TextFormField` with auto-uppercase `TextInputFormatter`
2. Subject field (optional)
3. Body `TextFormField` (multiline)
4. Send `ElevatedButton` with loading state
5. Success/error feedback (`SnackBar`)
6. Character count indicator for body

**Acceptance Criteria**:
- [ ] User can enter a plate, compose a message, and send it
- [ ] Plate is auto-formatted (uppercase)
- [ ] Validation prevents empty body or over-limit text
- [ ] Success confirmation shown after sending
- [ ] Error states handled (rate limit, network error)

---

### UI-FE-005: Message Detail & Thread Screen

- **Responsibility**: View a single message with its reply thread and compose replies.
- **Phase**: 2
- **Depends On**: UI-FE-003, MSG-BE-003
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. Message header (sender, plate, timestamp)
2. Message body
3. Reply list: flat, chronological (`ListView.builder`)
4. Reply input bar at bottom (`TextField` + send `IconButton`)
5. Real-time: new replies appear without refresh (Riverpod update from socket)
6. Mark message as read on open
7. Keyboard-aware layout (using `Scaffold.resizeToAvoidBottomInset`)

**Acceptance Criteria**:
- [ ] Full message and all replies displayed
- [ ] New replies appear in real-time
- [ ] User can compose and send a reply
- [ ] Message marked as read when opened
- [ ] Keyboard doesn't obscure input

---

### UI-FE-006: Sent Messages Screen

- **Responsibility**: Display messages the user has sent.
- **Phase**: 2
- **Depends On**: UI-FE-001, MSG-BE-002
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. `ListView.builder` with sent message preview tiles (recipient plate, subject, timestamp)
2. Read receipt indicator (has recipient read it?)
3. Pagination (cursor-based, infinite scroll)
4. Tap to navigate to message detail/thread

**Acceptance Criteria**:
- [ ] Sent messages display correctly with pagination
- [ ] Read status shown per message
- [ ] Tap navigates to thread view

---

### UI-FE-007: Profile Screen

- **Responsibility**: Display user profile and app settings.
- **Phase**: 2
- **Depends On**: UI-FE-001, AUTH-BE-002
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. Display name, email, claimed plate
2. Edit display name (inline edit or dialog)
3. Release / change plate
4. Logout button (clears tokens, navigates to auth)
5. App version display (from `package_info_plus`)

**Acceptance Criteria**:
- [ ] Profile info displays correctly
- [ ] User can edit display name
- [ ] User can release and claim a new plate
- [ ] Logout clears tokens and returns to auth screens

---

### UI-FE-008: Socket.IO & Push Notification Integration

- **Responsibility**: Connect Socket.IO client and FCM in the Flutter app.
- **Phase**: 2
- **Depends On**: RT-BE-001, RT-BE-002, UI-FE-002
- **Skills Needed**: Flutter, Dart, Firebase

**Deliverables**:
1. `socket_io_client` connection with JWT auth in extra headers
2. Auto-reconnect on network changes (using `connectivity_plus`)
3. Socket event listeners that update Riverpod providers (inbox, thread)
4. `firebase_messaging` setup for FCM
5. Device token registration on login
6. Push notification tap → deep link to message via GoRouter
7. Foreground notification handling (`firebase_messaging` onMessage)

**Acceptance Criteria**:
- [ ] Socket connects on login, disconnects on logout
- [ ] Real-time events update UI without manual refresh
- [ ] Push notifications arrive when app is backgrounded
- [ ] Tapping push opens the relevant message
- [ ] Reconnection works after network loss

---

## Phase 3: Testing & Quality Assurance

**Goal**: Comprehensive test coverage across backend and frontend.
**Depends On**: Phase 1 + Phase 2 core features.

---

### TEST-BE-001: Backend Unit Tests

- **Responsibility**: Unit tests for all backend modules.
- **Phase**: 3
- **Depends On**: All Phase 1 tasks
- **Skills Needed**: Testing, Backend TypeScript

**Deliverables**:
1. Test framework setup (Vitest)
2. Unit tests for: auth (hashing, JWT, validation), plate normalization, message creation logic, rate limiting logic
3. Minimum 80% code coverage on business logic

**Acceptance Criteria**:
- [ ] All unit tests pass
- [ ] Coverage ≥ 80% on `src/modules/`

---

### TEST-BE-002: Backend Integration Tests

- **Responsibility**: Integration tests against real database for API endpoints.
- **Phase**: 3
- **Depends On**: TEST-BE-001
- **Skills Needed**: Testing, Backend TypeScript

**Deliverables**:
1. Test database setup/teardown (per test suite)
2. Integration tests for: auth flow, message CRUD, reply flow, inbox/sent pagination, WebSocket events
3. Test utilities (authenticated request helper, seed helpers)

**Acceptance Criteria**:
- [ ] All integration tests pass against test Postgres
- [ ] Full auth → send → receive → reply flow tested
- [ ] WebSocket events verified in tests

---

### TEST-FE-001: Frontend Widget Tests

- **Responsibility**: Widget-level tests for Flutter screens.
- **Phase**: 3
- **Depends On**: All Phase 2 tasks
- **Skills Needed**: Testing, Flutter/Dart

**Deliverables**:
1. Test setup with `flutter_test` and `mocktail` for mocking
2. Widget tests for: auth forms, inbox list, message detail, send form
3. Mock Riverpod providers and API responses
4. Golden tests for key screens (optional but recommended)

**Acceptance Criteria**:
- [ ] Core screen widgets render correctly
- [ ] Form validation tested
- [ ] Loading and error states tested

---

### TEST-E2E-001: End-to-End Tests

- **Responsibility**: E2E tests covering critical user flows.
- **Phase**: 3
- **Depends On**: TEST-BE-002, TEST-FE-001
- **Skills Needed**: Testing, Flutter

**Deliverables**:
1. Flutter `integration_test` package setup
2. Test flows: register → send message → receive message → reply → notification
3. CI integration for E2E tests

**Acceptance Criteria**:
- [ ] Critical user journey passes end-to-end
- [ ] Tests run in CI

---

## Phase 4: Logging, Monitoring & DevOps

**Goal**: Production-grade observability and operational tooling.
**Depends On**: Phase 1 backend running.

---

### OBS-BE-001: Structured Logging

- **Responsibility**: Implement structured JSON logging across the backend.
- **Phase**: 4
- **Depends On**: Phase 1 tasks
- **Skills Needed**: Backend TypeScript, DevOps

**Deliverables**:
1. Pino logger (Fastify built-in) configured with structured JSON output
2. Request ID propagation (correlation IDs)
3. Log levels: error, warn, info, debug
4. Sensitive data redaction (passwords, tokens)
5. Log rotation configuration

**Acceptance Criteria**:
- [ ] All endpoints produce structured log output
- [ ] Request IDs trace across a full request lifecycle
- [ ] No sensitive data in logs

---

### OBS-BE-002: Health Checks & Metrics

- **Responsibility**: Health check endpoint and basic Prometheus metrics.
- **Phase**: 4
- **Depends On**: OBS-BE-001
- **Skills Needed**: Backend TypeScript, DevOps

**Deliverables**:
1. `GET /health` — returns DB connectivity, uptime, memory usage
2. Prometheus metrics endpoint (`/metrics`)
3. Key metrics: request count, latency histogram, active WebSocket connections, error rate
4. Grafana dashboard (Docker Compose service, optional for MVP)

**Acceptance Criteria**:
- [ ] Health endpoint returns correct status
- [ ] Metrics endpoint exposes Prometheus-format metrics
- [ ] Key business metrics tracked

---

### OBS-BE-003: Error Tracking

- **Responsibility**: Centralized error capture and alerting.
- **Phase**: 4
- **Depends On**: OBS-BE-001
- **Skills Needed**: Backend TypeScript, DevOps

**Deliverables**:
1. Sentry integration (free tier) or equivalent
2. Uncaught exception handling
3. Request context attached to errors
4. Source maps uploaded for stack trace readability

**Acceptance Criteria**:
- [ ] Errors appear in Sentry with full context
- [ ] Uncaught exceptions captured without crashing the server

---

## Phase 5: Polish, Performance & Optional Features

**Goal**: Ads, reporting, UX polish, and performance optimization.
**Depends On**: Phases 1–3 core functionality working.

---

### ADS-FE-001: AdMob Integration

- **Responsibility**: Integrate Google AdMob ads into the Flutter app.
- **Phase**: 5
- **Depends On**: Phase 2 UI complete
- **Skills Needed**: Flutter, Dart, AdMob

**Deliverables**:
1. `google_mobile_ads` package setup and initialization in `main.dart`
2. `BannerAd` widget on inbox screen (bottom)
3. `InterstitialAd` after sending a message (not every time — every 3rd send)
4. Ad loading states and fallback if ad fails (widget collapses gracefully)
5. Test ad units for development

**Acceptance Criteria**:
- [ ] Banner ads display on inbox
- [ ] Interstitial triggers at correct frequency
- [ ] Ads load gracefully (no blank space on failure)
- [ ] Test ads work in development

---

### RPT-BE-001: Report System

- **Responsibility**: Allow users to report messages or fraudulent plate claims.
- **Phase**: 5
- **Depends On**: MSG-BE-001
- **Skills Needed**: Backend TypeScript

**Deliverables**:
1. `POST /api/reports` — submit a report (message_id or user_id, reason)
2. Report reasons: spam, harassment, fraudulent plate, other
3. Duplicate report prevention (same reporter + same target)
4. Admin endpoints (future): `GET /api/admin/reports`, `PATCH /api/admin/reports/:id`

**Acceptance Criteria**:
- [ ] Users can report a message or user
- [ ] Duplicate reports rejected
- [ ] Reports stored with correct metadata

---

### RPT-FE-001: Report UI

- **Responsibility**: Add report button and flow to message detail screen.
- **Phase**: 5
- **Depends On**: RPT-BE-001, UI-FE-005
- **Skills Needed**: Flutter, Dart

**Deliverables**:
1. Report `IconButton` (flag icon) in message detail `AppBar`
2. Report `BottomSheet` / `AlertDialog`: select reason + optional description
3. Confirmation `SnackBar` after submission
4. Visual indicator on reported messages

**Acceptance Criteria**:
- [ ] Report flow works end-to-end
- [ ] User gets confirmation
- [ ] Cannot report same message twice

---

### UI-FE-009: UX Polish & Animations

- **Responsibility**: Visual refinement, loading states, animations, and accessibility.
- **Phase**: 5
- **Depends On**: All Phase 2 tasks
- **Skills Needed**: Flutter, Dart, UX

**Deliverables**:
1. Shimmer/skeleton loading widgets (using `shimmer` package or custom)
2. Pull-to-refresh animations (built into `RefreshIndicator`)
3. Message send animation / confirmation (Hero animation or custom)
4. Empty state illustrations (no messages yet, etc.)
5. `Semantics` labels on all interactive elements for accessibility
6. Dark mode support (follows system `ThemeMode.system`)

**Acceptance Criteria**:
- [ ] No jarring loading states — skeletons everywhere
- [ ] Animations feel native and smooth (60fps)
- [ ] VoiceOver / TalkBack usable
- [ ] Dark mode works correctly

---

## Phase 6: Deployment & Production Hardening

**Goal**: Deploy to production and prepare for app store submission.
**Depends On**: All previous phases.

---

### DEPLOY-INF-001: Production Docker & Deployment

- **Responsibility**: Production-ready Docker setup and hosting configuration.
- **Phase**: 6
- **Depends On**: All prior phases
- **Skills Needed**: DevOps

**Deliverables**:
1. Multi-stage Dockerfile (build + slim runtime)
2. Production `docker-compose.prod.yml`
3. Environment variable management for production
4. Hosting setup (VPS, Railway, Fly.io, or similar)
5. SSL/TLS configuration
6. Database connection pooling (PgBouncer or Drizzle pool config)

**Acceptance Criteria**:
- [ ] Production container builds and runs
- [ ] HTTPS enabled
- [ ] Database connections pooled efficiently
- [ ] Zero-downtime deploys possible

---

### DEPLOY-INF-002: Database Backup & Recovery

- **Responsibility**: Automated PostgreSQL backups.
- **Phase**: 6
- **Depends On**: DEPLOY-INF-001
- **Skills Needed**: DevOps, Database

**Deliverables**:
1. Automated daily backups (pg_dump cron or managed backup)
2. Backup storage (S3-compatible or host filesystem)
3. Restore procedure documented and tested
4. Backup retention policy (30 days)

**Acceptance Criteria**:
- [ ] Daily backups running
- [ ] Restore tested successfully
- [ ] Backup retention enforced

---

### DEPLOY-INF-003: App Store Preparation

- **Responsibility**: Prepare Flutter app for iOS App Store and Google Play submission.
- **Phase**: 6
- **Depends On**: ADS-FE-001, UI-FE-009
- **Skills Needed**: Flutter, Mobile DevOps

**Deliverables**:
1. App icons and splash screen (all required sizes via `flutter_launcher_icons`)
2. App Store screenshots (iPhone, iPad if applicable)
3. Play Store screenshots (phone, tablet if applicable)
4. Privacy policy and terms of service pages
5. App store listing metadata (description, keywords, category)
6. Production AdMob ad unit IDs configured
7. Production FCM project configured
8. Code signing setup (iOS certificates + provisioning profiles, Android keystore)
9. Flutter build configuration (`flutter build ios`, `flutter build appbundle`)

**Acceptance Criteria**:
- [ ] iOS build signed and uploadable to App Store Connect
- [ ] Android App Bundle signed and uploadable to Google Play Console
- [ ] All store listing assets prepared
- [ ] Privacy policy and ToS hosted and linked

---

## Phase Summary

| Phase | Tasks | Key Deliverable |
|-------|-------|-----------------|
| **0** | 4 tasks | Project scaffold, Docker, DB schema, CI |
| **1** | 7 tasks | Backend API: auth, messaging, replies, sockets, push |
| **2** | 8 tasks | Full Flutter app with all screens |
| **3** | 4 tasks | Unit, integration, widget, and E2E tests |
| **4** | 3 tasks | Logging, metrics, error tracking |
| **5** | 4 tasks | Ads, reports, UX polish |
| **6** | 3 tasks | Production deploy, backups, app store |
| **Total** | **33 tasks** | |
