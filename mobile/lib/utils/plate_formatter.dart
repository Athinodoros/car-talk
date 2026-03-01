import 'package:flutter/services.dart';

/// Normalizes a license plate string by converting to uppercase
/// and removing all spaces and hyphens.
String normalizePlate(String input) {
  return input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
}

/// A [TextInputFormatter] that converts input to uppercase and strips
/// spaces and hyphens as the user types, matching the backend
/// normalization rules for license plates.
class PlateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = normalizePlate(newValue.text);

    // Adjust the cursor position based on how many characters were removed
    final selectionIndex = normalized.length.clamp(0, normalized.length);

    return TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }
}
