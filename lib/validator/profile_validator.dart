/// Validator untuk halaman Profile
class ProfileValidator {
  /// Validasi field tidak boleh kosong
  static String? validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }

  /// Validasi password baru
  static String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Wajib diisi';
    }
    if (value.length < 6) {
      return 'Minimal 6 karakter';
    }
    return null;
  }

  /// Validasi konfirmasi password
  static String? Function(String?) validateConfirmPassword(String newPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Wajib diisi';
      }
      if (value != newPassword) {
        return 'Password tidak cocok';
      }
      return null;
    };
  }
}
