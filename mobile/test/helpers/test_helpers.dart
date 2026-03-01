import 'package:car_post_all/models/auth_state.dart';
import 'package:car_post_all/models/auth_tokens.dart';
import 'package:car_post_all/models/inbox_message.dart';
import 'package:car_post_all/models/message_detail.dart';
import 'package:car_post_all/models/plate.dart';
import 'package:car_post_all/models/sent_message.dart';
import 'package:car_post_all/models/user.dart';
import 'package:car_post_all/providers/auth_provider.dart';
import 'package:car_post_all/providers/inbox_provider.dart';
import 'package:car_post_all/providers/plates_provider.dart';
import 'package:car_post_all/providers/sent_provider.dart';
import 'package:car_post_all/providers/socket_provider.dart';
import 'package:car_post_all/providers/unread_count_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

const testUser = User(
  id: 'user-1',
  email: 'test@example.com',
  displayName: 'Test User',
);

const testTokens = AuthTokens(
  accessToken: 'test-access-token',
  refreshToken: 'test-refresh-token',
);

final authenticatedAuthState = AuthState(
  user: testUser,
  tokens: testTokens,
  isAuthenticated: true,
  isLoading: false,
);

const unauthenticatedAuthState = AuthState(isLoading: false);

List<InboxMessage> testInboxMessages = [
  InboxMessage(
    id: 'msg-1',
    recipientPlateId: 'plate-1',
    subject: 'Your headlights are on',
    body: 'Hey, your headlights are still on!',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    senderDisplayName: 'Alice',
  ),
  InboxMessage(
    id: 'msg-2',
    recipientPlateId: 'plate-1',
    subject: 'Nice car!',
    body: 'Love your car!',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    senderDisplayName: 'Bob',
  ),
];

List<SentMessage> testSentMessages = [
  SentMessage(
    id: 'msg-3',
    subject: 'Parking issue',
    body: 'Your car is parked too close.',
    isRead: false,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    recipientPlateNumber: 'ABC1234',
  ),
  SentMessage(
    id: 'msg-4',
    subject: null,
    body: 'Your tire looks flat!',
    isRead: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    recipientPlateNumber: 'XYZ5678',
  ),
];

final testMessageDetail = MessageDetail(
  id: 'msg-1',
  subject: 'Your headlights are on',
  body: 'Hey, your headlights are still on in the parking lot!',
  isRead: false,
  createdAt: DateTime.now().subtract(const Duration(hours: 1)),
  sender: const MessageSender(id: 'user-2', displayName: 'Alice'),
  recipientPlate: const MessageRecipientPlate(
    id: 'plate-1',
    plateNumber: 'DEMO123',
  ),
  replies: [
    Reply(
      id: 'reply-1',
      senderId: 'user-1',
      body: 'Thanks for letting me know!',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      senderDisplayName: 'Test User',
    ),
  ],
);

List<Plate> testPlates = [
  Plate(
    id: 'plate-1',
    plateNumber: 'DEMO123',
    stateOrRegion: 'CA',
    isActive: true,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  ),
];

/// Wraps a widget with MaterialApp for testing
Widget createTestWidget(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: child,
    ),
  );
}

/// Creates standard provider overrides for authenticated state
List<Override> authenticatedOverrides({
  InboxState? inboxState,
  SentState? sentState,
  List<Plate>? plates,
  int unreadCount = 0,
}) {
  return [
    authProvider.overrideWith(() => _FakeAuthNotifier(authenticatedAuthState)),
    inboxProvider.overrideWith(
      () => _FakeInboxNotifier(
        inboxState ??
            InboxState(
              messages: testInboxMessages,
              hasMore: false,
            ),
      ),
    ),
    sentProvider.overrideWith(
      () => _FakeSentNotifier(
        sentState ??
            SentState(
              messages: testSentMessages,
              hasMore: false,
            ),
      ),
    ),
    platesProvider.overrideWith(
      () => _FakePlatesNotifier(plates ?? testPlates),
    ),
    unreadCountProvider.overrideWith(
      () => _FakeUnreadCountNotifier(unreadCount),
    ),
    newMessageStreamProvider.overrideWith(
      (ref) => const Stream<Map<String, dynamic>>.empty(),
    ),
    newReplyStreamProvider.overrideWith(
      (ref) => const Stream<Map<String, dynamic>>.empty(),
    ),
    messageReadStreamProvider.overrideWith(
      (ref) => const Stream<Map<String, dynamic>>.empty(),
    ),
    unreadCountStreamProvider.overrideWith(
      (ref) => const Stream<Map<String, dynamic>>.empty(),
    ),
  ];
}

// Fake notifiers for testing

class _FakeAuthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;

  @override
  Future<void> login({required String email, required String password}) async {}

  @override
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String plateNumber,
    String? stateOrRegion,
  }) async {}

  @override
  Future<void> logout() async {}
}

class _FakeInboxNotifier extends AsyncNotifier<InboxState>
    implements InboxNotifier {
  _FakeInboxNotifier(this._state);
  final InboxState _state;

  @override
  Future<InboxState> build() async => _state;

  @override
  Future<void> fetchNextPage() async {}

  @override
  Future<void> refresh() async {}
}

class _FakeSentNotifier extends AsyncNotifier<SentState>
    implements SentNotifier {
  _FakeSentNotifier(this._state);
  final SentState _state;

  @override
  Future<SentState> build() async => _state;

  @override
  Future<void> fetchNextPage() async {}

  @override
  Future<void> refresh() async {}
}

class _FakePlatesNotifier extends AsyncNotifier<List<Plate>>
    implements PlatesNotifier {
  _FakePlatesNotifier(this._plates);
  final List<Plate> _plates;

  @override
  Future<List<Plate>> build() async => _plates;

  @override
  Future<void> claimPlate({
    required String plateNumber,
    String? stateOrRegion,
  }) async {}

  @override
  Future<void> releasePlate(String id) async {}
}

class _FakeUnreadCountNotifier extends AsyncNotifier<int>
    implements UnreadCountNotifier {
  _FakeUnreadCountNotifier(this._count);
  final int _count;

  @override
  Future<int> build() async => _count;

  @override
  void decrement() {}

  @override
  Future<void> refresh() async {}
}
