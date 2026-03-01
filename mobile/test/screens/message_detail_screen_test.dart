import 'package:car_post_all/models/message_detail.dart';
import 'package:car_post_all/providers/thread_provider.dart';
import 'package:car_post_all/providers/unread_count_provider.dart';
import 'package:car_post_all/screens/message_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('MessageDetailScreen', () {
    List<Override> detailOverrides({MessageDetail? detail}) {
      final d = detail ?? testMessageDetail;
      return [
        threadProvider(d.id).overrideWith((ref) async => d),
        unreadCountProvider.overrideWith(
          () => _FakeUnreadCount(3),
        ),
      ];
    }

    testWidgets('renders app bar with Message title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('displays sender name', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('displays recipient plate', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('To: DEMO123'), findsOneWidget);
    });

    testWidgets('displays message subject', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your headlights are on'), findsOneWidget);
    });

    testWidgets('displays message body', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Hey, your headlights are still on in the parking lot!',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays replies', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Replies (1)'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Thanks for letting me know!'), findsOneWidget);
    });

    testWidgets('renders reply input bar', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Write a reply...'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('hides subject when not present', (tester) async {
      final noSubjectDetail = MessageDetail(
        id: 'msg-no-subject',
        subject: null,
        body: 'Just a plain message.',
        isRead: true,
        createdAt: DateTime.now(),
        sender: const MessageSender(id: 'user-2', displayName: 'Bob'),
        recipientPlate: const MessageRecipientPlate(
          id: 'plate-1',
          plateNumber: 'DEMO123',
        ),
        replies: [],
      );

      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: noSubjectDetail.id),
          overrides: detailOverrides(detail: noSubjectDetail),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Just a plain message.'), findsOneWidget);
      expect(find.textContaining('Replies'), findsNothing);
    });

    testWidgets('displays sender avatar initial', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MessageDetailScreen(messageId: testMessageDetail.id),
          overrides: detailOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget); // 'A' for Alice
    });
  });
}

class _FakeUnreadCount extends AsyncNotifier<int>
    implements UnreadCountNotifier {
  _FakeUnreadCount(this._count);
  final int _count;

  @override
  Future<int> build() async => _count;

  @override
  void decrement() {}

  @override
  Future<void> refresh() async {}
}
