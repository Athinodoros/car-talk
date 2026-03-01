import 'package:car_post_all/screens/send_message_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SendMessageScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Send Message'), findsOneWidget);
    });

    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recipient License Plate'), findsOneWidget);
      expect(find.text('Subject (optional)'), findsOneWidget);
      expect(find.text('Message'), findsOneWidget);
    });

    testWidgets('renders send button', (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ElevatedButton, 'Send'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty required fields',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      // Tap the Send ElevatedButton directly
      await tester.tap(find.widgetWithText(ElevatedButton, 'Send'));
      await tester.pumpAndSettle();

      // Should show validation errors for plate and message
      expect(find.textContaining('plate'), findsWidgets);
    });

    testWidgets('shows character counter for message body', (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      expect(find.text('0 / 2000'), findsOneWidget);
    });

    testWidgets('updates character counter as user types', (tester) async {
      await tester.pumpWidget(createTestWidget(const SendMessageScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Message'),
        'Hello!',
      );
      await tester.pumpAndSettle();

      expect(find.text('6 / 2000'), findsOneWidget);
    });
  });
}
