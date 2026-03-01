import 'package:intl/intl.dart';

/// Returns a human-readable relative time string such as "just now",
/// "2m ago", "3h ago", "2d ago", or a formatted date for older timestamps.
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'just now';
  } else if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  } else if (difference.inHours < 24) {
    return '${difference.inHours}h ago';
  } else if (difference.inDays < 7) {
    return '${difference.inDays}d ago';
  } else {
    return DateFormat('MMM d, yyyy').format(dateTime);
  }
}

/// Returns a formatted timestamp suitable for message detail views.
///
/// - Today: "HH:mm" (e.g. "14:30")
/// - Yesterday: "Yesterday HH:mm" (e.g. "Yesterday 09:15")
/// - Older: "MMM d, HH:mm" (e.g. "Jan 5, 14:30")
String formatMessageTimestamp(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final timeFormat = DateFormat('HH:mm');

  if (dateOnly == today) {
    return timeFormat.format(dateTime);
  } else if (dateOnly == yesterday) {
    return 'Yesterday ${timeFormat.format(dateTime)}';
  } else {
    return DateFormat('MMM d, HH:mm').format(dateTime);
  }
}
