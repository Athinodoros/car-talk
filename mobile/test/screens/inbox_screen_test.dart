import 'package:car_post_all/providers/inbox_provider.dart';
import 'package:car_post_all/screens/inbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('InboxScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const InboxScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('displays inbox messages', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const InboxScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows subject as subtitle when available', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const InboxScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your headlights are on'), findsOneWidget);
      expect(find.text('Nice car!'), findsOneWidget);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const InboxScreen(),
          overrides: authenticatedOverrides(
            inboxState: const InboxState(messages: [], hasMore: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);
      expect(
        find.text('Messages sent to your plates will appear here.'),
        findsOneWidget,
      );
    });
  });
}
