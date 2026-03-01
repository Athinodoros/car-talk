import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Demo credentials used for E2E testing against the real backend.
const demoEmail = 'demo@carpostall.com';
const demoPassword = 'Demo1234!';

/// Timeout applied when waiting for network responses to settle.
const networkSettleTimeout = Duration(seconds: 10);

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
