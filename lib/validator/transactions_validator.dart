/// Validator untuk halaman Transactions
class TransactionsValidator {
  static String? validateNominal(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
    if (double.tryParse(cleanValue) == null) {
      return 'Angka tidak valid';
    }
    if (double.parse(cleanValue) <= 0) {
      return 'Nominal harus lebih dari 0';
    }
    return null;
  }

  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }
}
