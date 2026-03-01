import 'package:car_post_all/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders icon, title, and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No messages',
              subtitle: 'Check back later.',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
      expect(find.text('No messages'), findsOneWidget);
      expect(find.text('Check back later.'), findsOneWidget);
    });

    testWidgets('renders with empty subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox_outlined,
              title: 'No messages',
              subtitle: '',
            ),
          ),
        ),
      );

      expect(find.text('No messages'), findsOneWidget);
    });
  });
}
