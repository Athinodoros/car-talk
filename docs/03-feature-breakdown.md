# Car Post All — Feature-Based Breakdown

> Feature-centric view showing implementation details for each core capability.
> Cross-references task IDs from [01-phased-roadmap.md](01-phased-roadmap.md) and layers from [02-architectural-layers.md](02-architectural-layers.md).

---

## Feature 1: Authentication & Registration

**What it does**: Users sign up with email, password, and a license plate. JWT-based sessions keep them logged in. Plates are claimed on registration — first come, first served (no verification in MVP).

### Backend Implementation

| Task ID | Details |
|---------|---------|
| AUTH-BE-001 | Registration, login, token refresh |
| AUTH-BE-002 | Plate claim, release, list |

**Module**: `src/modules/auth/` and `src/modules/plates/`

**API Contracts**:

```
POST /api/auth/register
  Body: { email, password, displayName, plateNumber }
  Response 201: { user: { id, email, displayName }, tokens: { access, refresh } }
  Errors: 409 (email/plate taken), 400 (validation)

POST /api/auth/login
  Body: { email, password }
  Response 200: { user: { id, email, displayName }, tokens: { access, refresh } }
  Errors: 401 (invalid credentials)

POST /api/auth/refresh
  Body: { refreshToken }
  Response 200: { tokens: { access, refresh } }
  Errors: 401 (invalid/expired refresh token)
```

**Database Tables**: `users`, `license_plates`

**Business Rules**:
- Email must be unique
- Plate must be unique (normalized: uppercase, no spaces/hyphens)
- Password: minimum 8 characters, hashed with bcrypt (cost 12)
- Access token: 15 min TTL
- Refresh token: 7 days TTL, stored in DB, rotated on use
- Registration = atomic transaction (create user + claim plate)

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| UI-FE-002 | Register and login screens |

**Screens**:
- **RegisterScreen**: `Form` with `TextFormField`s for email, password, confirm password, display name, plate number. Plate field uses `TextInputFormatter` for auto-uppercase. Client-side validation via `GlobalKey<FormState>`.
- **LoginScreen**: email + password. "Forgot password" text (future feature, just placeholder for now).

**State**: `authProvider` (Riverpod) — user object, tokens, `isAuthenticated` computed property.

**Token Storage**: `flutter_secure_storage` for secure persistence.

**Flow**:
```
App Launch → Read tokens from flutter_secure_storage
  ├── Valid refresh token → Auto-login (refresh → get new access token → GoRouter redirects to /)
  └── Missing/Invalid → GoRouter redirects to /login
```

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | Password hashing/comparison, JWT creation/verification, plate normalization |
| Integration | Full register → login → protected route; duplicate email/plate rejection; token refresh flow |
| Widget | Register form validation, login form validation, error display |

### Logging & Metrics

- Log: registration events (success/failure), login attempts (success/failure with reason), token refresh
- Metric: `auth_registrations_total`, `auth_logins_total` (by status), `auth_token_refreshes_total`

---

## Feature 2: Messaging (Send & Receive)

**What it does**: Any authenticated user can send a message to any license plate. If the plate is claimed, the owner receives it immediately (inbox + real-time). If unclaimed, the message waits and is delivered when someone claims that plate.

### Backend Implementation

| Task ID | Details |
|---------|---------|
| MSG-BE-001 | Send message to plate |
| MSG-BE-002 | Inbox, sent, message detail, mark-as-read |

**Module**: `src/modules/messages/`

**API Contracts**:

```
POST /api/messages
  Body: { plateNumber, subject?, body }
  Response 201: { message: { id, subject, body, createdAt, recipientPlate } }
  Errors: 400 (validation), 429 (rate limited)

GET /api/messages/inbox?cursor=<timestamp>&limit=20
  Response 200: { messages: [...], nextCursor: <timestamp> | null }

GET /api/messages/sent?cursor=<timestamp>&limit=20
  Response 200: { messages: [...], nextCursor: <timestamp> | null }

GET /api/messages/unread-count
  Response 200: { count: number }

GET /api/messages/:id
  Response 200: { message: { ...full message }, replies: [...] }
  Errors: 404, 403 (not sender or recipient)

PATCH /api/messages/:id/read
  Response 200: { success: true }
  Errors: 403 (not the recipient)
```

**Database Tables**: `messages`, `license_plates`

**Business Rules**:
- Subject: optional, max 100 chars
- Body: required, max 2000 chars
- Rate limit: 20 messages/hour/user
- Plate lookup: normalize input → find or create `license_plates` entry (with `user_id = NULL` if unclaimed)
- Cursor pagination: ordered by `created_at DESC`, 20 items per page
- Only sender and recipient can view a message
- Only recipient can mark as read

**Unclaimed Plate Flow**:
```
User sends to "ABC 123"
  → Normalize to "ABC123"
  → Look up license_plates where plate_number = "ABC123"
  ├── Found (claimed): message.recipient_plate_id = plate.id → deliver
  └── Not found: INSERT into license_plates (user_id=NULL, plate_number="ABC123")
                 message.recipient_plate_id = new_plate.id → stored, awaits claim
```

**On Plate Claim** (in AUTH-BE-001 or AUTH-BE-002):
```
User claims plate "ABC123"
  → UPDATE license_plates SET user_id = :userId WHERE plate_number = "ABC123"
  → All messages with recipient_plate_id pointing to this plate become visible
  → Emit socket event for any unread messages
```

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| UI-FE-003 | Inbox screen |
| UI-FE-004 | Send message screen |
| UI-FE-006 | Sent messages screen |

**Screens**:

- **InboxScreen**: `ListView.builder` with message preview `ListTile`s. Each shows: sender display name, subject (or body preview), timestamp, read/unread indicator. `RefreshIndicator` for pull-to-refresh. `ScrollController` for infinite scroll. `BannerAd` widget at bottom.
- **SendMessageScreen**: `Form` with plate `TextFormField` (auto-uppercase formatter), optional subject, body `TextFormField` (multiline, maxLines), char counter, `ElevatedButton` for send. `SnackBar` on success.
- **SentScreen**: `ListView.builder` with sent message preview tiles. Recipient plate, subject/body preview, timestamp, read receipt indicator.

**State**: `inboxProvider` (messages, unread count, cursor), `sentProvider` (messages, cursor).

**Real-Time Integration**: Socket `new_message` event updates `inboxProvider` state → UI rebuilds automatically via Riverpod.

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | Rate limit logic, plate normalization, pagination cursor encoding |
| Integration | Send → inbox appears; unclaimed plate → claim → messages appear; pagination correctness; rate limiting |
| Widget | Inbox list rendering, send form validation, empty states |

### Logging & Metrics

- Log: message sent (sender, recipient plate, claimed/unclaimed), inbox queries, rate limit hits
- Metric: `messages_sent_total`, `messages_to_unclaimed_plates_total`, `messages_read_total`

---

## Feature 3: Message Threads & Replies

**What it does**: When viewing a message, both the sender and the recipient (plate owner) can reply, creating a conversation thread. Replies are flat (not nested). Both parties are notified of new replies in real time.

### Backend Implementation

| Task ID | Details |
|---------|---------|
| MSG-BE-003 | Reply creation and authorization |

**Module**: `src/modules/messages/` (same module as messaging)

**API Contracts**:

```
POST /api/messages/:id/replies
  Body: { body }
  Response 201: { reply: { id, body, senderId, createdAt } }
  Errors: 400 (validation), 403 (not sender/recipient), 404 (message not found)
```

**Database Tables**: `replies`

**Business Rules**:
- Only the original sender and the plate owner (recipient) can reply
- Body: required, max 2000 chars
- On reply: update `messages.updated_at` to current time (for active thread sorting)
- On reply: emit socket event to the other party
- On reply: send push notification if the other party is offline

**Authorization Logic**:
```
Can reply if:
  currentUser.id === message.sender_id
  OR
  currentUser owns the plate referenced by message.recipient_plate_id
```

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| UI-FE-005 | Message detail and thread screen |

**Screen: MessageDetailScreen**:
- `AppBar` with sender name → recipient plate, timestamp
- Message body (`Text` widget, full text)
- Reply list: flat, chronological (`ListView.builder`)
- Reply input bar at bottom: `TextField` + send `IconButton` in a `SafeArea`
- `Scaffold.resizeToAvoidBottomInset = true` for keyboard-aware layout
- Real-time: `new_reply` socket event updates `threadProvider` → UI rebuilds
- Auto-mark as read on screen init (if recipient)

**State**: `threadProvider(messageId)` — `AsyncNotifier` holding current message + replies list.

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | Authorization logic (can this user reply?) |
| Integration | Reply flow; unauthorized user rejected; replies appear in message detail; message.updated_at refreshed |
| Widget | Thread rendering, reply input, keyboard behavior |

### Logging & Metrics

- Log: reply created, authorization failures
- Metric: `replies_total`, `threads_active` (messages with recent replies)

---

## Feature 4: Real-Time Updates (WebSockets)

**What it does**: When the app is open, new messages and replies appear instantly without manual refresh. Uses Socket.IO over WebSockets with JWT authentication.

### Backend Implementation

| Task ID | Details |
|---------|---------|
| RT-BE-001 | Socket.IO server setup, auth, rooms, events |

**Module**: `src/socket/`

**Socket Events**:

| Event | Direction | Payload | Trigger |
|-------|-----------|---------|---------|
| `new_message` | Server → Client | `{ message: {...} }` | Message sent to user's plate |
| `new_reply` | Server → Client | `{ messageId, reply: {...} }` | Reply added to user's thread |
| `message_read` | Server → Client | `{ messageId }` | Recipient marks message as read |
| `unread_count` | Server → Client | `{ count: number }` | Unread count changed |

**Architecture**:
```
Client connects with JWT → Server verifies → Client joins room "user:{userId}"

Message created in handler:
  → Save to DB
  → Get recipient user ID from plate
  → socketService.emitToUser(recipientId, "new_message", { message })
  → If recipient not connected → send push notification
```

**Connection Management**:
- JWT verified on handshake (`socket.io` middleware)
- User joins room `user:{userId}` on connect
- Leaves room on disconnect
- Track connected user IDs in-memory Set (for push notification decision)
- Heartbeat: Socket.IO default ping/pong (25s interval)

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| UI-FE-008 | socket_io_client + FCM integration |

**Client Setup (Dart)**:
```
On login success:
  → Connect socket_io_client with access token in extraHeaders
  → Listen for events → update Riverpod providers
  → Register FCM device token with backend

On logout:
  → Disconnect socket
  → Unregister device token

On token refresh:
  → Reconnect socket with new token
```

**Event Handlers** (in a `SocketService` class injected via Riverpod):
- `new_message` → invalidate/update `inboxProvider`, increment unread count
- `new_reply` → if `threadProvider(messageId)` is active, append reply
- `message_read` → update read receipt in `sentProvider`
- `unread_count` → sync unread count provider

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | Socket auth middleware, room join/leave logic |
| Integration | Connect → send message → recipient receives event; disconnect → reconnect preserves room |
| E2E | Full real-time flow: User A sends → User B sees it live |

### Logging & Metrics

- Log: socket connections/disconnections, event emissions, auth failures
- Metric: `ws_connections_active` (gauge), `ws_events_emitted_total` (by event type)

---

## Feature 5: Push Notifications

**What it does**: When a user is not connected via WebSocket (app closed/backgrounded), they receive a push notification for new messages and replies. Tapping the notification deep-links to the relevant message.

### Backend Implementation

| Task ID | Details |
|---------|---------|
| RT-BE-002 | FCM integration, device token management, push delivery |

**Module**: `src/modules/notifications/`

**API Contracts**:

```
POST /api/devices
  Body: { token, platform: "ios" | "android" }
  Response 201: { success: true }

DELETE /api/devices/:token
  Response 200: { success: true }
```

**Database Tables**: `device_tokens`

**Push Logic**:
```
shouldSendPush(userId):
  return !connectedUsers.has(userId)  // Check in-memory Set

sendPush(userId, notification):
  tokens = await db.getDeviceTokens(userId)
  for each token:
    await fcm.send({ token, notification, data: { messageId, type } })
```

**Notification Payloads**:

| Type | Title | Body | Data |
|------|-------|------|------|
| New message | "New message for {plate}" | "{sender}: {subject or body preview}" | `{ type: "message", messageId }` |
| New reply | "New reply from {sender}" | "{body preview}" | `{ type: "reply", messageId }` |

### Frontend Implementation (Flutter)

Part of **UI-FE-008**.

**Setup**:
- `firebase_messaging` + `firebase_core` packages
- Request notification permission on first login (`FirebaseMessaging.instance.requestPermission()`)
- Register token with backend on login
- Handle foreground notifications via `FirebaseMessaging.onMessage` (show in-app `SnackBar` or overlay, not system notification)
- Handle background/quit notification taps via `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage()`

**Deep Linking**:
```
Notification tap → extract { type, messageId } from data
  → GoRouter.go('/inbox/$messageId') or GoRouter.go('/sent/$messageId')
```

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | shouldSendPush logic, notification payload formatting |
| Integration | Send message to offline user → push sent; send to online user → no push |

### Logging & Metrics

- Log: push sent (success/failure), token registrations, invalid token cleanup
- Metric: `push_notifications_sent_total`, `push_notifications_failed_total`

---

## Feature 6: Ad Integration (Monetization)

**What it does**: Ads are the sole revenue source. Banner ads on the inbox screen, interstitial ads triggered after every 3rd message send.

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| ADS-FE-001 | AdMob SDK setup, banner placement, interstitial logic |

**Package**: `google_mobile_ads`

**Ad Placements**:

| Ad Type | Location | Trigger |
|---------|----------|---------|
| Banner | Bottom of InboxScreen (above bottom nav) | Always visible |
| Interstitial | Full-screen overlay | After every 3rd message sent |

**Implementation Details**:
- Initialize `MobileAds.instance.initialize()` in `main.dart`
- Use test ad unit IDs in development (`ca-app-pub-3940256099942544/...`)
- Production ad unit IDs stored in Dart environment config (`--dart-define`)
- `BannerAd` widget wrapped in a `Container` with fixed height; collapses to `SizedBox.shrink()` on load failure
- `InterstitialAd` preloaded after each display for smooth UX
- Send counter stored in a Riverpod `StateProvider` (resets on app restart — acceptable for MVP)

**Considerations**:
- iOS: App Tracking Transparency (ATT) prompt via `app_tracking_transparency` package before showing personalized ads
- Android: No special permission needed
- AdMob requires privacy policy — covered in DEPLOY-INF-003

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Widget | Banner widget renders without crashing, interstitial trigger logic (every 3rd send) |

### Logging & Metrics

- Metric: `ad_impressions_total` (by type), `ad_clicks_total` (if available from AdMob callbacks)

---

## Feature 7: Report System

**What it does**: Users can report inappropriate messages or fraudulent plate claims. Reports are stored for future admin review (admin panel is out of scope for MVP but the backend stores the data).

### Backend Implementation

| Task ID | Details |
|---------|---------|
| RPT-BE-001 | Report creation, deduplication, storage |

**Module**: `src/modules/reports/`

**API Contracts**:

```
POST /api/reports
  Body: { reportedMessageId?, reportedUserId?, reason, description? }
  Response 201: { report: { id, reason, status, createdAt } }
  Errors: 400 (validation), 409 (duplicate report)
```

**Database Tables**: `reports`

**Report Reasons** (enum):
- `spam` — Unsolicited/commercial messages
- `harassment` — Threatening or abusive content
- `fraudulent_plate` — User claims a plate they don't own
- `other` — Free-text description required

**Business Rules**:
- User cannot report the same message twice (unique constraint)
- Must provide at least `reportedMessageId` or `reportedUserId`
- Reports default to `status: "pending"`
- Admin endpoints (GET, PATCH) stubbed but not exposed in MVP

### Frontend Implementation (Flutter)

| Task ID | Details |
|---------|---------|
| RPT-FE-001 | Report button and modal on message detail |

**UI**:
- Flag `IconButton` in MessageDetailScreen `AppBar` actions
- Tap → `showModalBottomSheet` with reason selection (`RadioListTile`s) + optional description `TextField`
- Submit → confirmation `SnackBar`
- Reported messages show subtle "Reported" chip/indicator
- Cannot report same message twice (button disabled after report)

### Tests Needed

| Tier | What to Test |
|------|-------------|
| Unit | Report validation, duplicate detection |
| Integration | Submit report → stored in DB; duplicate rejected |
| Widget | Report bottom sheet rendering, reason selection, submission flow |

### Logging & Metrics

- Log: report submitted (reason, target)
- Metric: `reports_submitted_total` (by reason)

---

## Feature Cross-Reference Matrix

| Feature | Backend Tasks | Frontend Tasks | Phase | DB Tables |
|---------|--------------|----------------|-------|-----------|
| Auth & Registration | AUTH-BE-001, AUTH-BE-002 | UI-FE-002 | 1, 2 | users, license_plates |
| Messaging | MSG-BE-001, MSG-BE-002 | UI-FE-003, UI-FE-004, UI-FE-006 | 1, 2 | messages, license_plates |
| Threads & Replies | MSG-BE-003 | UI-FE-005 | 1, 2 | replies |
| Real-Time | RT-BE-001 | UI-FE-008 | 1, 2 | — |
| Push Notifications | RT-BE-002 | UI-FE-008 | 1, 2 | device_tokens |
| Ads | — | ADS-FE-001 | 5 | — |
| Reports | RPT-BE-001 | RPT-FE-001 | 5 | reports |
| Profile | AUTH-BE-002 | UI-FE-007 | 1, 2 | users, license_plates |

---

## Task ID Master Index

| Task ID | Name | Phase | Layer |
|---------|------|-------|-------|
| INFRA-INF-001 | Initialize project | 0 | Infrastructure |
| INFRA-INF-002 | Docker & Compose setup | 0 | Infrastructure |
| INFRA-INF-003 | CI/CD pipeline | 0 | Infrastructure |
| INFRA-DB-001 | DB schema & migrations | 0 | Database |
| AUTH-BE-001 | Auth: register & login | 1 | Backend |
| AUTH-BE-002 | Plate management | 1 | Backend |
| MSG-BE-001 | Message sending | 1 | Backend |
| MSG-BE-002 | Inbox & sent retrieval | 1 | Backend |
| MSG-BE-003 | Reply system | 1 | Backend |
| RT-BE-001 | WebSocket real-time | 1 | Backend |
| RT-BE-002 | Push notifications | 1 | Backend |
| UI-FE-001 | Navigation & app shell | 2 | Frontend |
| UI-FE-002 | Auth screens | 2 | Frontend |
| UI-FE-003 | Inbox screen | 2 | Frontend |
| UI-FE-004 | Send message screen | 2 | Frontend |
| UI-FE-005 | Message detail & thread | 2 | Frontend |
| UI-FE-006 | Sent messages screen | 2 | Frontend |
| UI-FE-007 | Profile screen | 2 | Frontend |
| UI-FE-008 | Socket & push integration | 2 | Frontend |
| TEST-BE-001 | Backend unit tests | 3 | Testing |
| TEST-BE-002 | Backend integration tests | 3 | Testing |
| TEST-FE-001 | Frontend widget tests | 3 | Testing |
| TEST-E2E-001 | E2E tests | 3 | Testing |
| OBS-BE-001 | Structured logging | 4 | Observability |
| OBS-BE-002 | Health checks & metrics | 4 | Observability |
| OBS-BE-003 | Error tracking | 4 | Observability |
| ADS-FE-001 | AdMob integration | 5 | Frontend |
| RPT-BE-001 | Report system backend | 5 | Backend |
| RPT-FE-001 | Report UI | 5 | Frontend |
| UI-FE-009 | UX polish & animations | 5 | Frontend |
| DEPLOY-INF-001 | Production deployment | 6 | Infrastructure |
| DEPLOY-INF-002 | DB backup & recovery | 6 | Infrastructure |
| DEPLOY-INF-003 | App store preparation | 6 | Infrastructure |

**Total: 33 tasks across 7 phases**
