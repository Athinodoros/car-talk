import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:car_post_all/utils/date_formatter.dart';

void main() {
  group('formatRelativeTime', () {
    test('returns "just now" for less than 60 seconds ago', () {
      final dateTime = DateTime.now().subtract(const Duration(seconds: 30));
      expect(formatRelativeTime(dateTime), equals('just now'));
    });

    test('returns "just now" for 0 seconds ago', () {
      final dateTime = DateTime.now();
      expect(formatRelativeTime(dateTime), equals('just now'));
    });

    test('returns "just now" for 59 seconds ago', () {
      final dateTime = DateTime.now().subtract(const Duration(seconds: 59));
      expect(formatRelativeTime(dateTime), equals('just now'));
    });

    test('returns minutes ago for 1 minute', () {
      final dateTime = DateTime.now().subtract(const Duration(minutes: 1));
      expect(formatRelativeTime(dateTime), equals('1m ago'));
    });

    test('returns minutes ago for 30 minutes', () {
      final dateTime = DateTime.now().subtract(const Duration(minutes: 30));
      expect(formatRelativeTime(dateTime), equals('30m ago'));
    });

    test('returns minutes ago for 59 minutes', () {
      final dateTime = DateTime.now().subtract(const Duration(minutes: 59));
      expect(formatRelativeTime(dateTime), equals('59m ago'));
    });

    test('returns hours ago for 1 hour', () {
      final dateTime = DateTime.now().subtract(const Duration(hours: 1));
      expect(formatRelativeTime(dateTime), equals('1h ago'));
    });

    test('returns hours ago for 12 hours', () {
      final dateTime = DateTime.now().subtract(const Duration(hours: 12));
      expect(formatRelativeTime(dateTime), equals('12h ago'));
    });

    test('returns hours ago for 23 hours', () {
      final dateTime = DateTime.now().subtract(const Duration(hours: 23));
      expect(formatRelativeTime(dateTime), equals('23h ago'));
    });

    test('returns days ago for 1 day', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 1));
      expect(formatRelativeTime(dateTime), equals('1d ago'));
    });

    test('returns days ago for 6 days', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 6));
      expect(formatRelativeTime(dateTime), equals('6d ago'));
    });

    test('returns formatted date for 7 days ago', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 7));
      final expected = DateFormat('MMM d, yyyy').format(dateTime);
      expect(formatRelativeTime(dateTime), equals(expected));
    });

    test('returns formatted date for 30 days ago', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 30));
      final expected = DateFormat('MMM d, yyyy').format(dateTime);
      expect(formatRelativeTime(dateTime), equals(expected));
    });

    test('returns formatted date for dates over a year ago', () {
      final dateTime = DateTime.now().subtract(const Duration(days: 400));
      final expected = DateFormat('MMM d, yyyy').format(dateTime);
      expect(formatRelativeTime(dateTime), equals(expected));
    });
  });

  group('formatMessageTimestamp', () {
    test('returns time only for today', () {
      final now = DateTime.now();
      final todayAt1430 = DateTime(now.year, now.month, now.day, 14, 30);

      // Only test if the constructed time is still "today" (not in the future
      // relative to test boundaries).
      final result = formatMessageTimestamp(todayAt1430);
      expect(result, equals('14:30'));
    });

    test('returns "Yesterday HH:mm" for yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final yesterdayAt0915 = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        9,
        15,
      );

      final result = formatMessageTimestamp(yesterdayAt0915);
      expect(result, equals('Yesterday 09:15'));
    });

    test('returns "MMM d, HH:mm" for older dates', () {
      final olderDate = DateTime(2025, 1, 5, 14, 30);
      final result = formatMessageTimestamp(olderDate);
      expect(result, equals('Jan 5, 14:30'));
    });

    test('returns "MMM d, HH:mm" for two days ago', () {
      final now = DateTime.now();
      final twoDaysAgo = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 2));
      final dateTime = DateTime(
        twoDaysAgo.year,
        twoDaysAgo.month,
        twoDaysAgo.day,
        10,
        0,
      );

      final result = formatMessageTimestamp(dateTime);
      final expected = DateFormat('MMM d, HH:mm').format(dateTime);
      expect(result, equals(expected));
    });

    test('formats midnight correctly for today', () {
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day, 0, 0);

      final result = formatMessageTimestamp(midnight);
      expect(result, equals('00:00'));
    });

    test('formats late-night time correctly for yesterday', () {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1));
      final lateNight = DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        23,
        59,
      );

      final result = formatMessageTimestamp(lateNight);
      expect(result, equals('Yesterday 23:59'));
    });
  });
}
