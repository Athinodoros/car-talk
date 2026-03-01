import 'package:car_post_all/models/plate.dart';
import 'package:car_post_all/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('displays user display name and email', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays user avatar with initial', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('T'), findsOneWidget);
    });

    testWidgets('displays plates section', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Plates'), findsOneWidget);
      expect(find.text('DEMO123'), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
    });

    testWidgets('displays add plate button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Plate'), findsOneWidget);
    });

    testWidgets('shows empty plates message when no plates', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(plates: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No plates claimed yet.'), findsOneWidget);
    });

    testWidgets('displays logout button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('displays version info', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('shows add plate dialog on button tap', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Plate'));
      await tester.pumpAndSettle();

      expect(find.text('License Plate'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Claim'), findsOneWidget);
    });

    testWidgets('shows release confirmation dialog', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Release Plate'), findsOneWidget);
      expect(
        find.text('Are you sure you want to release this license plate?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Release'), findsOneWidget);
    });

    testWidgets('displays multiple plates', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: authenticatedOverrides(
            plates: [
              Plate(
                id: 'plate-1',
                plateNumber: 'ABC1234',
                stateOrRegion: 'CA',
                isActive: true,
                createdAt: DateTime.now(),
              ),
              Plate(
                id: 'plate-2',
                plateNumber: 'XYZ5678',
                stateOrRegion: 'NY',
                isActive: true,
                createdAt: DateTime.now(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ABC1234'), findsOneWidget);
      expect(find.text('XYZ5678'), findsOneWidget);
      expect(find.text('CA'), findsOneWidget);
      expect(find.text('NY'), findsOneWidget);
    });
  });
}
