import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika kosong, return langsung
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hapus semua karakter non-digit
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Jika tidak ada digit, return kosong
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Parse ke integer dan format
    final int value = int.parse(digitsOnly);
    final String formattedValue = _formatter.format(value);

    int newCursorPosition = formattedValue.length;

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  /// Helper method untuk mengekstrak nilai numerik dari string terformat
  static int parseFormattedValue(String value) {
    if (value.isEmpty) return 0;
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.isEmpty ? 0 : int.parse(digitsOnly);
  }
}
