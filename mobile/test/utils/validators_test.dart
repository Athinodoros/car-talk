import 'package:flutter_test/flutter_test.dart';

import 'package:car_post_all/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('returns error for null', () {
      expect(validateEmail(null), equals('Email is required'));
    });

    test('returns error for empty string', () {
      expect(validateEmail(''), equals('Email is required'));
    });

    test('returns error for whitespace-only string', () {
      expect(validateEmail('   '), equals('Email is required'));
    });

    test('returns error for email without @', () {
      expect(validateEmail('invalidemail.com'), equals('Enter a valid email address'));
    });

    test('returns error for email without domain', () {
      expect(validateEmail('user@'), equals('Enter a valid email address'));
    });

    test('returns error for email without TLD', () {
      expect(validateEmail('user@domain'), equals('Enter a valid email address'));
    });

    test('returns error for email with single-char TLD', () {
      expect(validateEmail('user@domain.a'), equals('Enter a valid email address'));
    });

    test('returns null for valid email', () {
      expect(validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with dots in local part', () {
      expect(validateEmail('first.last@example.com'), isNull);
    });

    test('returns null for email with plus in local part', () {
      expect(validateEmail('user+tag@example.com'), isNull);
    });

    test('returns null for email with hyphen in domain', () {
      expect(validateEmail('user@my-domain.com'), isNull);
    });

    test('returns null for email with subdomain', () {
      expect(validateEmail('user@mail.example.com'), isNull);
    });

    test('trims whitespace before validation', () {
      expect(validateEmail('  user@example.com  '), isNull);
    });
  });

  group('validatePassword', () {
    test('returns error for null', () {
      expect(validatePassword(null), equals('Password is required'));
    });

    test('returns error for empty string', () {
      expect(validatePassword(''), equals('Password is required'));
    });

    test('returns error for password shorter than 8 characters', () {
      expect(validatePassword('short'), equals('Password must be at least 8 characters'));
    });

    test('returns error for 7-character password', () {
      expect(validatePassword('1234567'), equals('Password must be at least 8 characters'));
    });

    test('returns null for exactly 8 characters', () {
      expect(validatePassword('12345678'), isNull);
    });

    test('returns null for long password', () {
      expect(validatePassword('a very long and secure password'), isNull);
    });
  });

  group('validateConfirmPassword', () {
    test('returns error for null', () {
      expect(
        validateConfirmPassword(null, 'password'),
        equals('Please confirm your password'),
      );
    });

    test('returns error for empty string', () {
      expect(
        validateConfirmPassword('', 'password'),
        equals('Please confirm your password'),
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        validateConfirmPassword('different', 'password'),
        equals('Passwords do not match'),
      );
    });

    test('returns null when passwords match', () {
      expect(validateConfirmPassword('password', 'password'), isNull);
    });
  });

  group('validateDisplayName', () {
    test('returns error for null', () {
      expect(validateDisplayName(null), equals('Display name is required'));
    });

    test('returns error for empty string', () {
      expect(validateDisplayName(''), equals('Display name is required'));
    });

    test('returns error for whitespace-only string', () {
      expect(validateDisplayName('   '), equals('Display name is required'));
    });

    test('returns error for single character after trimming', () {
      expect(
        validateDisplayName('a'),
        equals('Display name must be at least 2 characters'),
      );
    });

    test('returns null for 2-character name', () {
      expect(validateDisplayName('Jo'), isNull);
    });

    test('returns null for a normal display name', () {
      expect(validateDisplayName('John Doe'), isNull);
    });
  });

  group('validatePlate', () {
    test('returns error for null', () {
      expect(validatePlate(null), equals('License plate is required'));
    });

    test('returns error for empty string', () {
      expect(validatePlate(''), equals('License plate is required'));
    });

    test('returns error for whitespace-only string', () {
      expect(validatePlate('   '), equals('License plate is required'));
    });

    test('returns error for single character (too short after normalization)', () {
      expect(
        validatePlate('a'),
        equals('License plate must be at least 2 characters'),
      );
    });

    test('returns error for only hyphens/spaces (normalizes to empty)', () {
      expect(validatePlate('- -'), equals('License plate must be at least 2 characters'));
    });

    test('returns null for valid plate', () {
      expect(validatePlate('ABC123'), isNull);
    });

    test('returns null for plate with spaces and hyphens (valid after normalization)', () {
      expect(validatePlate('AB-C 123'), isNull);
    });

    test('returns null for minimal valid plate (2 chars)', () {
      expect(validatePlate('AB'), isNull);
    });
  });

  group('validateMessageBody', () {
    test('returns error for null', () {
      expect(validateMessageBody(null), equals('Message body is required'));
    });

    test('returns error for empty string', () {
      expect(validateMessageBody(''), equals('Message body is required'));
    });

    test('returns error for whitespace-only string', () {
      expect(validateMessageBody('   '), equals('Message body is required'));
    });

    test('returns error for string exceeding 2000 characters', () {
      final longMessage = 'a' * 2001;
      expect(
        validateMessageBody(longMessage),
        equals('Message body must be 2000 characters or less'),
      );
    });

    test('returns null for exactly 2000 characters', () {
      final maxMessage = 'a' * 2000;
      expect(validateMessageBody(maxMessage), isNull);
    });

    test('returns null for a normal message', () {
      expect(validateMessageBody('Hello, nice car!'), isNull);
    });
  });

  group('validateSubject', () {
    test('returns null for null (subject is optional)', () {
      expect(validateSubject(null), isNull);
    });

    test('returns null for empty string (subject is optional)', () {
      expect(validateSubject(''), isNull);
    });

    test('returns null for whitespace-only string (subject is optional)', () {
      expect(validateSubject('   '), isNull);
    });

    test('returns error for string exceeding 100 characters', () {
      final longSubject = 'a' * 101;
      expect(
        validateSubject(longSubject),
        equals('Subject must be 100 characters or less'),
      );
    });

    test('returns null for exactly 100 characters', () {
      final maxSubject = 'a' * 100;
      expect(validateSubject(maxSubject), isNull);
    });

    test('returns null for a normal subject', () {
      expect(validateSubject('Your headlights are on'), isNull);
    });
  });
}
