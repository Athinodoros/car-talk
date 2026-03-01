import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Demo credentials used for E2E testing against the real backend.
const demoEmail = 'demo@carpostall.com';
const demoPassword = 'Demo1234!';

/// Password used when registering new test accounts.
const testPassword = 'TestPass1234!';

/// Timeout applied when waiting for network responses to settle.
const networkSettleTimeout = Duration(seconds: 10);

/// Generates a unique email address using the current timestamp.
///
/// Each call produces a different email, ensuring registration tests
/// never collide with existing accounts.
String generateUniqueEmail() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return 'test_$timestamp@carpostall.com';
}

/// Generates a unique license plate using the current timestamp.
///
/// Produces a 7-character plate like "T1234567" derived from the
/// last 7 digits of the epoch milliseconds to avoid collisions.
String generateUniquePlate() {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final digits = timestamp.toString();
  // Take last 6 digits and prefix with 'T' for a 7-char plate
  return 'T${digits.substring(digits.length - 6)}';
}

/// Performs the full login flow using the demo credentials.
///
/// Assumes the app is currently showing the login screen.
/// After calling this, the tester should be on the inbox screen.
Future<void> login(WidgetTester tester) async {
  // Wait for the app to finish initializing (splash -> login redirect)
  await tester.pumpAndSettle(networkSettleTimeout);

  // Verify we are on the login screen
  expect(find.text('Login'), findsWidgets);

  // Enter email
  final emailField = find.widgetWithText(TextFormField, 'Email');
  expect(emailField, findsOneWidget);
  await tester.enterText(emailField, demoEmail);

  // Enter password
  final passwordField = find.widgetWithText(TextFormField, 'Password');
  expect(passwordField, findsOneWidget);
  await tester.enterText(passwordField, demoPassword);

  // Dismiss keyboard so the Login button is visible
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Tap the Login button (the ElevatedButton, not the "Don't have an account?" text)
  final loginButton = find.widgetWithText(ElevatedButton, 'Login');
  expect(loginButton, findsOneWidget);
  await tester.tap(loginButton);

  // Wait for the backend response and navigation to complete
  await tester.pumpAndSettle(networkSettleTimeout);
}

/// Navigates to a bottom navigation tab by index.
///
/// Tab indices:
///   0 = Inbox
///   1 = Send
///   2 = Sent
///   3 = Profile
///
/// The function finds the [NavigationBar] and taps the destination at [index].
Future<void> navigateToTab(WidgetTester tester, int index) async {
  final labels = ['Inbox', 'Send', 'Sent', 'Profile'];
  assert(index >= 0 && index < labels.length, 'Tab index must be 0-3');

  // Find the NavigationDestination by its label text
  final destination = find.text(labels[index]);
  expect(destination, findsWidgets);

  // Tap the first match (the NavigationDestination label)
  await tester.tap(destination.first);
  await tester.pumpAndSettle(networkSettleTimeout);
}

/// Performs the full registration flow with the given credentials.
///
/// Assumes the app is currently showing the login screen.
/// Navigates to the register screen, fills in all required fields,
/// and submits the form.
///
/// After calling this, the tester should be on the inbox screen
/// (on success) or still on the register screen (on failure with a SnackBar).
Future<void> register(
  WidgetTester tester, {
  required String email,
  required String password,
  required String displayName,
  required String plateNumber,
}) async {
  // Wait for the app to finish initializing (splash -> login redirect)
  await tester.pumpAndSettle(networkSettleTimeout);

  // We should be on the login screen. Tap the Register link to navigate.
  final registerLink = find.text("Don't have an account? Register");
  expect(registerLink, findsOneWidget);
  await tester.tap(registerLink);
  await tester.pumpAndSettle();

  // Verify we are on the register screen
  expect(find.text('Create Account'), findsOneWidget);

  // Fill in email
  final emailField = find.widgetWithText(TextFormField, 'Email');
  expect(emailField, findsOneWidget);
  await tester.enterText(emailField, email);

  // Fill in display name
  final displayNameField = find.widgetWithText(TextFormField, 'Display Name');
  expect(displayNameField, findsOneWidget);
  await tester.enterText(displayNameField, displayName);

  // Fill in password
  final passwordField = find.widgetWithText(TextFormField, 'Password');
  expect(passwordField, findsOneWidget);
  await tester.enterText(passwordField, password);

  // Fill in confirm password
  final confirmPasswordField = find.widgetWithText(
    TextFormField,
    'Confirm Password',
  );
  expect(confirmPasswordField, findsOneWidget);
  await tester.enterText(confirmPasswordField, password);

  // Scroll down to make the plate field and Register button visible
  await tester.drag(
    find.byType(SingleChildScrollView),
    const Offset(0, -300),
  );
  await tester.pumpAndSettle();

  // Fill in license plate
  final plateField = find.widgetWithText(TextFormField, 'License Plate');
  expect(plateField, findsOneWidget);
  await tester.enterText(plateField, plateNumber);

  // Dismiss keyboard
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Tap the Register button (ElevatedButton inside LoadingButton)
  final registerButton = find.widgetWithText(ElevatedButton, 'Register');
  await tester.ensureVisible(registerButton);
  await tester.pumpAndSettle();
  expect(registerButton, findsOneWidget);
  await tester.tap(registerButton);

  // Wait for the network call and navigation to complete
  await tester.pumpAndSettle(networkSettleTimeout);
}
