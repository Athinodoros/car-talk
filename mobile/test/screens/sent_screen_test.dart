import 'package:car_post_all/providers/sent_provider.dart';
import 'package:car_post_all/screens/sent_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SentScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SentScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sent'), findsOneWidget);
    });

    testWidgets('displays sent messages', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SentScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABC1234'), findsOneWidget);
      expect(find.text('XYZ5678'), findsOneWidget);
    });

    testWidgets('shows subject as subtitle when available', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SentScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Parking issue'), findsOneWidget);
    });

    testWidgets('shows body as subtitle when no subject', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SentScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your tire looks flat!'), findsOneWidget);
    });

    testWidgets('shows empty state when no messages', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const SentScreen(),
          overrides: authenticatedOverrides(
            sentState: const SentState(messages: [], hasMore: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No sent messages'), findsOneWidget);
      expect(
        find.text('Messages you send will appear here.'),
        findsOneWidget,
      );
    });
  });
}
