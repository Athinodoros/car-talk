import 'package:car_post_all/models/auth_state.dart';
import 'package:car_post_all/models/plate.dart';
import 'package:car_post_all/providers/auth_provider.dart';
import 'package:car_post_all/providers/inbox_provider.dart';
import 'package:car_post_all/providers/plates_provider.dart';
import 'package:car_post_all/providers/sent_provider.dart';
import 'package:car_post_all/providers/socket_provider.dart';
import 'package:car_post_all/providers/unread_count_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_post_all/app.dart';

import 'helpers/test_helpers.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _UnauthNotifier(),
          ),
          inboxProvider.overrideWith(
            () => _EmptyInboxNotifier(),
          ),
          sentProvider.overrideWith(
            () => _EmptySentNotifier(),
          ),
          platesProvider.overrideWith(
            () => _EmptyPlatesNotifier(),
          ),
          unreadCountProvider.overrideWith(
            () => _ZeroUnreadNotifier(),
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
        ],
        child: const CarPostAllApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should show login screen
    expect(find.text('Car Post All'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}

class _UnauthNotifier extends AsyncNotifier<AuthState>
    implements AuthNotifier {
  @override
  Future<AuthState> build() async => unauthenticatedAuthState;

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

class _EmptyInboxNotifier extends AsyncNotifier<InboxState>
    implements InboxNotifier {
  @override
  Future<InboxState> build() async =>
      const InboxState(messages: [], hasMore: false);
  @override
  Future<void> fetchNextPage() async {}
  @override
  Future<void> refresh() async {}
}

class _EmptySentNotifier extends AsyncNotifier<SentState>
    implements SentNotifier {
  @override
  Future<SentState> build() async =>
      const SentState(messages: [], hasMore: false);
  @override
  Future<void> fetchNextPage() async {}
  @override
  Future<void> refresh() async {}
}

class _EmptyPlatesNotifier extends AsyncNotifier<List<Plate>>
    implements PlatesNotifier {
  @override
  Future<List<Plate>> build() async => [];
  @override
  Future<void> claimPlate(
      {required String plateNumber, String? stateOrRegion}) async {}
  @override
  Future<void> releasePlate(String id) async {}
}

class _ZeroUnreadNotifier extends AsyncNotifier<int>
    implements UnreadCountNotifier {
  @override
  Future<int> build() async => 0;
  @override
  void decrement() {}
  @override
  Future<void> refresh() async {}
}
