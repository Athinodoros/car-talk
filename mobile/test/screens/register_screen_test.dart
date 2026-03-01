import 'package:car_post_all/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('RegisterScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('License Plate'), findsOneWidget);
      expect(find.text('State / Region (optional)'), findsOneWidget);
    });

    testWidgets('renders register button', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // The button text 'Register' is inside an ElevatedButton
      expect(find.widgetWithText(ElevatedButton, 'Register'), findsOneWidget);
    });

    testWidgets('renders login link', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('Already have an account? Login'),
        findsOneWidget,
      );
    });

    testWidgets('renders Create Account title', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows validation errors when submitting empty form',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // The Register button may be off-screen, so use ensureVisible before tapping
      final registerButton =
          find.widgetWithText(ElevatedButton, 'Register');
      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Should show multiple validation errors (Email, Password, etc.)
      expect(find.textContaining('required'), findsWidgets);
    });

    testWidgets('renders car icon in app header', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // There may be multiple car icons (header + plate input), so just check at least one
      expect(find.byIcon(Icons.directions_car), findsWidgets);
    });
  });
}
