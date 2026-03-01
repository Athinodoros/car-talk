import 'package:car_post_all/widgets/message_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageTile', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Your headlights are on',
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              isRead: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Your headlights are on'), findsOneWidget);
    });

    testWidgets('shows unread indicator for unread messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Hello',
              timestamp: DateTime.now(),
              isRead: false,
              onTap: () {},
            ),
          ),
        ),
      );

      // The unread indicator is a blue circle Container
      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.blue,
        ),
      );
      expect(container, isNotNull);
    });

    testWidgets('hides unread indicator for read messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Hello',
              timestamp: DateTime.now(),
              isRead: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not find a blue circle
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == Colors.blue,
        ),
        findsNothing,
      );
    });

    testWidgets('shows relative timestamp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Hello',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              isRead: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('2h ago'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Hello',
              timestamp: DateTime.now(),
              isRead: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('uses bold font weight for unread messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageTile(
              title: 'Alice',
              subtitle: 'Hello',
              timestamp: DateTime.now(),
              isRead: false,
              onTap: () {},
            ),
          ),
        ),
      );

      final titleText = tester.widget<Text>(find.text('Alice'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });
  });
}
