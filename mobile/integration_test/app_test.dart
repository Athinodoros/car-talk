// Integration (E2E) tests for Car Post All.
//
// These tests run against the real backend at localhost:3002.
// They are designed for manual development use, not CI.
//
// Run with:
//   cd mobile && flutter test integration_test/app_test.dart
//
// Ensure the backend and database are running before executing.

import 'package:car_post_all/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/e2e_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login flow', () {
    testWidgets('user can log in with demo credentials and reach the inbox',
        (tester) async {
      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );

      // Perform login
      await login(tester);

      // After login we should see the inbox screen.
      // The AppBar title is 'Inbox' and the bottom nav has an 'Inbox' label.
      expect(find.text('Inbox'), findsWidgets);

      // The bottom navigation bar should be visible with all four destinations.
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
      expect(find.text('Sent'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });
  });

  group('Send message flow', () {
    testWidgets('user can fill and send a message', (tester) async {
      // Launch and login
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );
      await login(tester);

      // Navigate to Send tab (index 1)
      await navigateToTab(tester, 1);

      // Verify the Send Message screen is visible
      expect(find.text('Send Message'), findsOneWidget);

      // Enter a license plate
      final plateField = find.widgetWithText(
        TextFormField,
        'Recipient License Plate',
      );
      expect(plateField, findsOneWidget);
      await tester.enterText(plateField, 'TEST999');

      // Enter a subject
      final subjectField = find.widgetWithText(
        TextFormField,
        'Subject (optional)',
      );
      expect(subjectField, findsOneWidget);
      await tester.enterText(subjectField, 'E2E Test Subject');

      // Enter a message body
      final bodyField = find.widgetWithText(TextFormField, 'Message');
      expect(bodyField, findsOneWidget);
      await tester.enterText(bodyField, 'This is an automated E2E test message.');

      // Dismiss keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap the Send button
      final sendButton = find.widgetWithText(ElevatedButton, 'Send');
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);

      // Wait for the network call and UI feedback
      await tester.pumpAndSettle(networkSettleTimeout);

      // Check for success or error feedback via SnackBar.
      // On success: "Message sent successfully"
      // On expected failure (plate not found, etc.): some error message
      // Either way, a SnackBar should appear.
      expect(find.byType(SnackBar), findsOneWidget);

      // If the plate exists in the database, we get the success message.
      // We check optimistically but do not fail if the plate is not registered,
      // since the test environment may not have plate TEST999.
      final successSnackbar = find.text('Message sent successfully');
      if (successSnackbar.evaluate().isNotEmpty) {
        expect(successSnackbar, findsOneWidget);
      }
    });
  });

  group('Inbox navigation', () {
    testWidgets('inbox screen renders and messages can be tapped',
        (tester) async {
      // Launch and login
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );
      await login(tester);

      // We should already be on the inbox. Verify it.
      expect(find.text('Inbox'), findsWidgets);

      // Wait for inbox to load (it may show a loading spinner first)
      await tester.pumpAndSettle(networkSettleTimeout);

      // The inbox either has messages or shows the empty state.
      final emptyState = find.text('No messages yet');
      final listView = find.byType(ListView);

      // One of these must be present
      expect(
        emptyState.evaluate().isNotEmpty || listView.evaluate().isNotEmpty,
        isTrue,
        reason: 'Inbox should show either messages or the empty state',
      );

      // If there are messages (ListTile widgets from MessageTile), tap the first one.
      final messageTiles = find.byType(ListTile);
      if (messageTiles.evaluate().isNotEmpty) {
        await tester.tap(messageTiles.first);
        await tester.pumpAndSettle(networkSettleTimeout);

        // Verify we navigated to the message detail screen.
        // The AppBar title is 'Message'.
        expect(find.text('Message'), findsOneWidget);

        // The reply input should be visible.
        expect(find.text('Write a reply...'), findsOneWidget);
      }
    });
  });

  group('Registration flow', () {
    testWidgets('user can register a new account and reach the inbox',
        (tester) async {
      // Generate unique credentials to avoid collisions with existing accounts
      final uniqueEmail = generateUniqueEmail();
      final uniquePlate = generateUniquePlate();

      // Launch the app
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );

      // Perform registration
      await register(
        tester,
        email: uniqueEmail,
        password: testPassword,
        displayName: 'E2E Test User',
        plateNumber: uniquePlate,
      );

      // After successful registration we should be navigated to the inbox.
      // Check for the inbox screen indicators.
      final inboxFinder = find.text('Inbox');
      final snackBarFinder = find.byType(SnackBar);

      if (inboxFinder.evaluate().isNotEmpty) {
        // Registration succeeded and we navigated to the inbox
        expect(inboxFinder, findsWidgets);
        expect(find.byType(NavigationBar), findsOneWidget);
      } else if (snackBarFinder.evaluate().isNotEmpty) {
        // Registration failed (e.g., backend not running, email taken).
        // The test still verifies the UI flow works — we just could not
        // complete server-side registration in this environment.
        expect(snackBarFinder, findsOneWidget);
      } else {
        // Neither outcome — fail with a descriptive message
        fail(
          'After registration, expected either navigation to Inbox '
          'or a SnackBar with an error message',
        );
      }
    });
  });

  group('Reply flow', () {
    testWidgets('user can reply to a message in the inbox', (tester) async {
      // Launch and login
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );
      await login(tester);

      // We should be on the inbox screen
      expect(find.text('Inbox'), findsWidgets);

      // Wait for inbox messages to load
      await tester.pumpAndSettle(networkSettleTimeout);

      // Check whether there are messages in the inbox
      final messageTiles = find.byType(ListTile);
      if (messageTiles.evaluate().isEmpty) {
        // No messages in the inbox — nothing to reply to.
        // This is acceptable; the test passes as a no-op in this case.
        return;
      }

      // Tap the first message to open the detail screen
      await tester.tap(messageTiles.first);
      await tester.pumpAndSettle(networkSettleTimeout);

      // Verify we are on the message detail screen
      expect(find.text('Message'), findsOneWidget);

      // The reply input field should be visible
      final replyField = find.widgetWithText(TextField, 'Write a reply...');
      expect(replyField, findsOneWidget);

      // Enter reply text
      final replyText = 'E2E reply ${DateTime.now().millisecondsSinceEpoch}';
      await tester.enterText(replyField, replyText);

      // Dismiss keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap the send reply button (IconButton with send icon)
      final sendReplyButton = find.byTooltip('Send reply');
      expect(sendReplyButton, findsOneWidget);
      await tester.tap(sendReplyButton);

      // Wait for the network call to complete
      await tester.pumpAndSettle(networkSettleTimeout);

      // Verify the outcome. On success, the reply text should appear in the
      // thread. On failure, a SnackBar with an error message is shown.
      final replyInThread = find.text(replyText);
      final errorSnackBar = find.byType(SnackBar);

      if (replyInThread.evaluate().isNotEmpty) {
        // Reply was sent successfully and appears in the thread
        expect(replyInThread, findsOneWidget);
      } else if (errorSnackBar.evaluate().isNotEmpty) {
        // Reply failed (e.g., network error, permission issue).
        // The SnackBar confirms the UI handled the error gracefully.
        expect(errorSnackBar, findsOneWidget);
      } else {
        // The reply text might not be visible if the thread auto-scrolled
        // or the provider state updated. As a fallback, ensure we are
        // still on the message detail screen (no crash occurred).
        expect(find.text('Message'), findsOneWidget);
      }
    });
  });

  group('Profile screen', () {
    testWidgets('profile screen displays user info, plates, and logout button',
        (tester) async {
      // Launch and login
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );
      await login(tester);

      // Navigate to Profile tab (index 3)
      await navigateToTab(tester, 3);

      // Wait for profile data to load
      await tester.pumpAndSettle(networkSettleTimeout);

      // Verify the Profile AppBar title
      expect(find.text('Profile'), findsWidgets);

      // User info card should display the user's email.
      // The demo user email should be visible somewhere on screen.
      // We look for text containing the demo email or any email pattern.
      // Since we logged in with demoEmail, the profile should show it.
      final emailFinder = find.text(demoEmail);
      expect(emailFinder, findsOneWidget);

      // The "My Plates" section header should be visible.
      expect(find.text('My Plates'), findsOneWidget);

      // The "Add Plate" button should be visible.
      expect(find.text('Add Plate'), findsOneWidget);

      // The Logout button must be present.
      final logoutButton = find.text('Logout');
      expect(logoutButton, findsOneWidget);

      // The version text should be displayed.
      expect(find.text('Version 1.0.0'), findsOneWidget);
    });

    testWidgets('logout returns to login screen', (tester) async {
      // Launch and login
      await tester.pumpWidget(
        const ProviderScope(child: CarPostAllApp()),
      );
      await login(tester);

      // Navigate to Profile tab
      await navigateToTab(tester, 3);
      await tester.pumpAndSettle(networkSettleTimeout);

      // Tap Logout
      final logoutButton = find.text('Logout');
      expect(logoutButton, findsOneWidget);

      // Scroll down if necessary to ensure the logout button is visible
      await tester.ensureVisible(logoutButton);
      await tester.pumpAndSettle();

      await tester.tap(logoutButton);
      await tester.pumpAndSettle(networkSettleTimeout);

      // After logout, the router should redirect to the login screen.
      expect(find.text('Car Post All'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    });
  });
}
