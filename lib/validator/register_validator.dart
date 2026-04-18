class RegisterValidator {
  static String? validateNama(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    if (value.length < 4) {
      return 'Nama minimal 4 karakter';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 5) {
      return 'Username minimal 5 karakter';
    }
    // Cek apakah semua karakter adalah angka (tidak boleh)
    if (RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Username tidak boleh hanya angka';
    }
    // Harus mengandung minimal 4 huruf
    final letterCount = value.replaceAll(RegExp(r'[^a-zA-Z]'), '').length;
    if (letterCount < 4) {
      return 'Username harus mengandung minimal 4 huruf';
    }
    // Hanya boleh huruf dan angka
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Username hanya boleh huruf dan angka';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != password) {
      return 'Password tidak cocok';
    }
    return null;
  }
}
