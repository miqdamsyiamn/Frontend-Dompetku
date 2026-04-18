// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '/utils/app_theme.dart';
import '/services/api_services.dart';
import '/services/auth_manager.dart';
import '/model/user_model.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  UserModel? _profile;
  File? _selectedImage;
  bool _isEditing = false;

  late TextEditingController _namaController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userModel = await ApiService().getProfile();
      setState(() {
        _profile = userModel;
        _namaController.text = userModel.nama;
        _isLoading = false;
      });
      await AuthManager().saveUser(userModel.toJson());
    } catch (e) {
      setState(() => _isLoading = false);
      final cachedUser = AuthManager().user;
      if (cachedUser != null) {
        final userFromCache = UserModel.fromJson(cachedUser);
        _namaController.text = userFromCache.nama;
        setState(() => _profile = userFromCache);
      }
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = result.files.first;

    if (file.extension == 'png' ||
        file.extension == 'jpg' ||
        file.extension == 'jpeg' ||
        file.extension == 'gif' ||
        file.extension == 'webp') {
      setState(() {
        _selectedImage = File(file.path!);
        _isEditing = true;
      });
      displaySnackbar('Foto dipilih. Klik Simpan untuk menyimpan.');
    } else {
      displaySnackbar(
        'Pilih file gambar (png, jpg, jpeg, gif, webp)',
        isError: true,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_namaController.text.isEmpty) {
      displaySnackbar('Nama tidak boleh kosong', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userModel = await ApiService().updateProfile(
        nama: _namaController.text,
        filePath: _selectedImage?.path,
      );

      await AuthManager().saveUser(userModel.toJson());

      displaySnackbar('Profil berhasil disimpan');
      setState(() {
        _isEditing = false;
        _selectedImage = null;
        _profile = userModel;
      });
    } on ApiException catch (e) {
      displaySnackbar(e.message, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _namaController.text = _profile?.nama ?? '';
      _selectedImage = null;
    });
  }

  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Field ini wajib diisi';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password baru wajib diisi';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  String? Function(String?) _validateConfirmPassword(String newPassword) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Konfirmasi password wajib diisi';
      }
      if (value != newPassword) {
        return 'Password tidak cocok';
      }
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    // Prefer _profile, fallback to cached user from AuthManager
    final UserModel? user =
        _profile ??
        (AuthManager().user != null
            ? UserModel.fromJson(AuthManager().user!)
            : null);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading && _profile == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppTheme.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 3,
                                      ),
                                      image: _selectedImage != null
                                          ? DecorationImage(
                                              image: FileImage(_selectedImage!),
                                              fit: BoxFit.cover,
                                            )
                                          : (user?.foto != null &&
                                                    user!.foto!.isNotEmpty
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                      user.foto!,
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null),
                                    ),
                                    child:
                                        _selectedImage == null &&
                                            (user?.foto == null ||
                                                user!.foto!.isEmpty)
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppTheme.primary,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              user?.nama ?? 'User',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${user?.username ?? 'username'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Informasi Profil',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (!_isEditing)
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                  icon: Icon(
                                    Icons.edit,
                                    color: AppTheme.primary,
                                  ),
                                  tooltip: 'Edit Profil',
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Nama Field
                          _buildProfileItem(
                            icon: Icons.person_outline,
                            label: 'Nama Lengkap',
                            value: user?.nama ?? '-',
                            isEditing: _isEditing,
                            controller: _namaController,
                          ),
                          const SizedBox(height: 16),

                          // Username Field
                          _buildProfileItem(
                            icon: Icons.alternate_email,
                            label: 'Username',
                            value: user?.username ?? '-',
                            isEditing: false,
                            isDisabled: true,
                          ),

                          if (_isEditing) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _cancelEdit,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text('Batal'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isLoading ? null : _saveProfile,
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.save, size: 20),
                                    label: Text(
                                      _isLoading ? 'Menyimpan...' : 'Simpan',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Menu Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Ganti Password',
                          onTap: _showChangePasswordDialog,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Lainnya',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuItem(
                          icon: Icons.info_outline,
                          title: 'Tentang Aplikasi',
                          onTap: _showAboutDialog,
                        ),
                        _buildMenuItem(
                          icon: Icons.logout,
                          title: 'Keluar',
                          color: AppTheme.danger,
                          onTap: _confirmLogout,
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: Text(
                            'DompetKu v1.0.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isEditing,
    TextEditingController? controller,
    bool isDisabled = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDisabled ? AppTheme.textSecondary : AppTheme.primary)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDisabled ? AppTheme.textSecondary : AppTheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              if (isEditing && controller != null)
                TextFormField(
                  controller: controller,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDisabled
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color ?? AppTheme.primary, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Ganti Password',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildPasswordField(
                    controller: oldPasswordController,
                    label: 'Password Lama',
                    obscureText: obscureOld,
                    onToggle: () =>
                        setModalState(() => obscureOld = !obscureOld),
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: newPasswordController,
                    label: 'Password Baru',
                    obscureText: obscureNew,
                    onToggle: () =>
                        setModalState(() => obscureNew = !obscureNew),
                    validator: _validateNewPassword,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordField(
                    controller: confirmPasswordController,
                    label: 'Konfirmasi Password Baru',
                    obscureText: obscureConfirm,
                    onToggle: () =>
                        setModalState(() => obscureConfirm = !obscureConfirm),
                    validator: _validateConfirmPassword(
                      newPasswordController.text,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        Navigator.pop(context);

                        try {
                          await ApiService().changePassword(
                            oldPasswordController.text,
                            newPasswordController.text,
                          );
                          displaySnackbar('Password berhasil diubah');
                        } on ApiException catch (e) {
                          displaySnackbar(e.message, isError: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ubah Password',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('DompetKu'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplikasi pencatatan keuangan pribadi yang membantu Anda mengelola pemasukan, pengeluaran, dan mencapai tujuan finansial.',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Versi 1.0.0',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              navigator.pop();
              await AuthManager().logout();
              if (mounted) {
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  dynamic displaySnackbar(String msg, {bool isError = false}) {
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }
}
