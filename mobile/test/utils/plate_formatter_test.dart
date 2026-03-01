import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:car_post_all/utils/plate_formatter.dart';

void main() {
  group('normalizePlate', () {
    test('converts lowercase to uppercase', () {
      expect(normalizePlate('abc123'), equals('ABC123'));
    });

    test('strips spaces', () {
      expect(normalizePlate('AB C 123'), equals('ABC123'));
    });

    test('strips hyphens', () {
      expect(normalizePlate('AB-C-123'), equals('ABC123'));
    });

    test('strips mixed spaces and hyphens', () {
      expect(normalizePlate('ab - c 1-23'), equals('ABC123'));
    });

    test('handles empty string', () {
      expect(normalizePlate(''), equals(''));
    });

    test('returns already-normalized input unchanged', () {
      expect(normalizePlate('ABC123'), equals('ABC123'));
    });

    test('handles string with only spaces and hyphens', () {
      expect(normalizePlate('  - -- '), equals(''));
    });

    test('preserves special characters other than spaces/hyphens', () {
      expect(normalizePlate('ab.c!1@2'), equals('AB.C!1@2'));
    });

    test('handles single character', () {
      expect(normalizePlate('a'), equals('A'));
    });

    test('handles tabs and other whitespace', () {
      expect(normalizePlate('AB\t12\n3'), equals('AB123'));
    });
  });

  group('PlateInputFormatter', () {
    late PlateInputFormatter formatter;

    setUp(() {
      formatter = PlateInputFormatter();
    });

    test('normalizes input on edit update', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'abc-123',
        selection: TextSelection.collapsed(offset: 7),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ABC123'));
      expect(result.selection.baseOffset, equals(6));
    });

    test('handles empty input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue.empty;

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals(''));
      expect(result.selection.baseOffset, equals(0));
    });

    test('collapses cursor to end after normalization', () {
      const oldValue = TextEditingValue(
        text: 'AB',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: 'AB C',
        selection: TextSelection.collapsed(offset: 4),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ABC'));
      expect(result.selection.baseOffset, equals(3));
      expect(result.selection.isCollapsed, isTrue);
    });

    test('converts lowercase to uppercase on input', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('ABC'));
    });

    test('strips hyphens on input', () {
      const oldValue = TextEditingValue(
        text: 'AB',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: 'AB-',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);

      expect(result.text, equals('AB'));
      expect(result.selection.baseOffset, equals(2));
    });
  });
}
