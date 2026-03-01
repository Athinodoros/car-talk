import 'plate_formatter.dart';

/// Validates an email field.
/// Returns null if valid, or an error message string.
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  final emailRegex = RegExp(r'^[\w\.\-\+]+@[\w\.\-]+\.\w{2,}$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Enter a valid email address';
  }
  return null;
}

/// Validates a password field.
/// Returns null if valid, or an error message string.
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters';
  }
  return null;
}

/// Validates that a confirmation password matches the original password.
/// Returns null if valid, or an error message string.
String? validateConfirmPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Please confirm your password';
  }
  if (value != password) {
    return 'Passwords do not match';
  }
  return null;
}

/// Validates a display name field.
/// Returns null if valid, or an error message string.
String? validateDisplayName(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Display name is required';
  }
  if (value.trim().length < 2) {
    return 'Display name must be at least 2 characters';
  }
  return null;
}

/// Validates a license plate field.
/// Returns null if valid, or an error message string.
String? validatePlate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'License plate is required';
  }
  final normalized = normalizePlate(value);
  if (normalized.length < 2) {
    return 'License plate must be at least 2 characters';
  }
  return null;
}

/// Validates a message body field.
/// Returns null if valid, or an error message string.
String? validateMessageBody(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Message body is required';
  }
  if (value.length > 2000) {
    return 'Message body must be 2000 characters or less';
  }
  return null;
}

/// Validates a message subject field.
/// Subject is optional, but if provided must be 100 characters or less.
/// Returns null if valid, or an error message string.
String? validateSubject(String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  if (value.length > 100) {
    return 'Subject must be 100 characters or less';
  }
  return null;
}
