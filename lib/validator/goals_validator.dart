class GoalsValidator {
  /// Validasi nama goal
  static String? validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }

  /// Validasi target amount
  static String? validateTargetAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
    if (double.tryParse(cleanValue) == null) {
      return 'Angka tidak valid';
    }
    if (double.parse(cleanValue) <= 0) {
      return 'Target harus lebih dari 0';
    }
    return null;
  }

  /// Validasi amount untuk tambah progress
  static String? validateAmount(String? value) {
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

  static String? Function(String?) validateWithdrawAmount(
    double currentAmount,
  ) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Wajib diisi';
      }
      final cleanValue = value.replaceAll('.', '').replaceAll(',', '');
      final amount = double.tryParse(cleanValue);
      if (amount == null) {
        return 'Angka tidak valid';
      }
      if (amount <= 0) {
        return 'Nominal harus lebih dari 0';
      }
      if (amount > currentAmount) {
        return 'Melebihi saldo tersedia';
      }
      return null;
    };
  }

  /// Validasi apakah goal bisa dihapus
  static String? canDeleteGoal(double currentAmount) {
    if (currentAmount > 0) {
      return 'Goal masih memiliki saldo. Tarik saldo terlebih dahulu sebelum menghapus goal ini.';
    }
    return null;
  }
}
