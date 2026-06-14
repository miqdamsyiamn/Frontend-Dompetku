// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/utils/app_theme.dart';
import '/services/api_services.dart';
import '/services/auth_manager.dart';
import '/model/user_model.dart';
import 'leaderboard_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.people, size: 20), text: 'Manajemen User'),
            Tab(icon: Icon(Icons.leaderboard, size: 20), text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _UserListContent(),
          LeaderboardScreen(),
        ],
      ),
    );
  }
}

// ========== TAB 1: User Management Content ==========

class _UserListContent extends StatefulWidget {
  const _UserListContent();

  @override
  State<_UserListContent> createState() => _UserListContentState();
}

class _UserListContentState extends State<_UserListContent> {
  bool _isLoading = false;
  List<UserModel> _users = [];
  int _totalUsers = 0;
  int _currentPage = 1;
  final int _limit = 10;
  String? _selectedRole;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool reset = true}) async {
    if (reset) _currentPage = 1;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().adminGetUsers(
        page: _currentPage,
        limit: _limit,
        role: _selectedRole,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _users = response.users;
        _totalUsers = response.total;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.message, isError: true);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Terjadi kesalahan: $e', isError: true);
    }
  }

  void _onSearch(String value) {
    _searchQuery = value;
    _loadUsers();
  }

  void _onFilterRole(String? role) {
    setState(() => _selectedRole = role);
    _loadUsers();
  }

  void _nextPage() {
    if (_currentPage * _limit < _totalUsers) {
      _currentPage++;
      _loadUsers(reset: false);
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _currentPage--;
      _loadUsers(reset: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: AppTheme.background,
            child: Column(
              children: [
                // Search + refresh row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: _onSearch,
                          style: TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Cari nama atau username...',
                            prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: AppTheme.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearch('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh, color: AppTheme.primary),
                        onPressed: _loadUsers,
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Info + Filter
                Row(
                  children: [
                    Text('Total: $_totalUsers user', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    _buildFilterChip('Semua', null),
                    const SizedBox(width: 6),
                    _buildFilterChip('User', 'user'),
                    const SizedBox(width: 6),
                    _buildFilterChip('Admin', 'admin'),
                  ],
                ),
              ],
            ),
          ),
          // User list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: AppTheme.textSecondary),
                            const SizedBox(height: 12),
                            Text('Tidak ada user ditemukan', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _users.length,
                          itemBuilder: (context, index) => _buildUserCard(_users[index]),
                        ),
                      ),
          ),
          // Pagination
          if (_totalUsers > _limit)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _currentPage > 1 ? _prevPage : null,
                    icon: const Icon(Icons.chevron_left, size: 20),
                    label: const Text('Prev'),
                  ),
                  Text('Hal $_currentPage / ${((_totalUsers + _limit - 1) / _limit).ceil()}',
                      style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  TextButton.icon(
                    onPressed: _currentPage * _limit < _totalUsers ? _nextPage : null,
                    icon: const Icon(Icons.chevron_right, size: 20),
                    label: const Text('Next'),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Tombol Tambah User',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: _showCreateUserSheet,
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.person_add, color: Colors.white),
          label: const Text('Tambah User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => _onFilterRole(role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final isAdmin = user.role == 'admin';
    final currentUserId = AuthManager().userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: (isAdmin ? const Color(0xFF3B82F6) : AppTheme.primary).withOpacity(0.1),
          backgroundImage: user.foto != null && user.foto!.isNotEmpty ? NetworkImage(user.foto!) : null,
          child: user.foto == null || user.foto!.isEmpty
              ? Icon(isAdmin ? Icons.shield : Icons.person, color: isAdmin ? const Color(0xFF3B82F6) : AppTheme.primary, size: 22)
              : null,
        ),
        title: Text(user.nama, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('@${user.username}', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (isAdmin ? const Color(0xFF3B82F6) : AppTheme.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role?.toUpperCase() ?? 'USER',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isAdmin ? const Color(0xFF3B82F6) : AppTheme.success),
                  ),
                ),
                if (user.createdAt != null) ...[
                  const SizedBox(width: 8),
                  Text(_dateFormat.format(user.createdAt!), style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppTheme.textSecondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') _showEditUserSheet(user);
            if (value == 'delete') _confirmDeleteUser(user);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Edit')])),
            if (user.id != currentUserId)
              PopupMenuItem(
                value: 'delete',
                child: Row(children: [Icon(Icons.delete, size: 18, color: AppTheme.danger), SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppTheme.danger))]),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserSheet() {
    final namaC = TextEditingController();
    final usernameC = TextEditingController();
    final passwordC = TextEditingController();
    String selectedRole = 'user';
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Tambah User Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: AppTheme.textSecondary), tooltip: 'Tutup'),
                  ]),
                  const SizedBox(height: 20),
                  _buildFormField('Nama Lengkap', namaC, Icons.person_outline, validator: (v) => v == null || v.length < 2 ? 'Nama minimal 2 karakter' : null),
                  const SizedBox(height: 14),
                  _buildFormField('Username', usernameC, Icons.alternate_email, validator: (v) => v == null || v.length < 4 ? 'Username minimal 4 karakter' : null),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordC,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                            onPressed: () => setModalState(() => obscure = !obscure),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Role', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleOption('user', 'User', selectedRole, (v) => setModalState(() => selectedRole = v)),
                      const SizedBox(width: 12),
                      _buildRoleOption('admin', 'Admin', selectedRole, (v) => setModalState(() => selectedRole = v)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => loading = true);
                              try {
                                await ApiService().adminCreateUser(
                                  nama: namaC.text.trim(),
                                  username: usernameC.text.trim(),
                                  password: passwordC.text,
                                  role: selectedRole,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _showSnackbar('User berhasil dibuat');
                                _loadUsers();
                              } on ApiException catch (e) {
                                setModalState(() => loading = false);
                                _showSnackbar(e.message, isError: true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buat User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _showEditUserSheet(UserModel user) {
    final namaC = TextEditingController(text: user.nama);
    final usernameC = TextEditingController(text: user.username);
    final passwordC = TextEditingController();
    String selectedRole = user.role ?? 'user';
    final formKey = GlobalKey<FormState>();
    bool obscure = true;
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Edit User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: Icon(Icons.close, color: AppTheme.textSecondary), tooltip: 'Tutup'),
                  ]),
                  const SizedBox(height: 4),
                  Text('@${user.username}', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 20),
                  _buildFormField('Nama Lengkap', namaC, Icons.person_outline, validator: (v) => v != null && v.isNotEmpty && v.length < 2 ? 'Nama minimal 2 karakter' : null),
                  const SizedBox(height: 14),
                  _buildFormField('Username', usernameC, Icons.alternate_email, validator: (v) => v != null && v.isNotEmpty && v.length < 4 ? 'Username minimal 4 karakter' : null),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password Baru (opsional)', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordC,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          hintText: 'Kosongkan jika tidak diubah',
                          prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                          suffixIcon: IconButton(
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: AppTheme.textSecondary),
                            onPressed: () => setModalState(() => obscure = !obscure),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v != null && v.isNotEmpty && v.length < 6 ? 'Password minimal 6 karakter' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Role', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildRoleOption('user', 'User', selectedRole, (v) => setModalState(() => selectedRole = v)),
                      const SizedBox(width: 12),
                      _buildRoleOption('admin', 'Admin', selectedRole, (v) => setModalState(() => selectedRole = v)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => loading = true);
                              try {
                                await ApiService().adminUpdateUser(
                                  user.id,
                                  nama: namaC.text.trim(),
                                  username: usernameC.text.trim(),
                                  role: selectedRole,
                                  password: passwordC.text.isNotEmpty ? passwordC.text : null,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                _showSnackbar('User berhasil diperbarui');
                                _loadUsers();
                              } on ApiException catch (e) {
                                setModalState(() => loading = false);
                                _showSnackbar(e.message, isError: true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _confirmDeleteUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah Anda yakin ingin menghapus user ini?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.nama, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                  Text('@${user.username}', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '⚠️ Semua data user (transaksi & goals) juga akan dihapus!',
              style: TextStyle(fontSize: 13, color: AppTheme.danger, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final result = await ApiService().adminDeleteUser(user.id);
                _showSnackbar(result['message'] ?? 'User berhasil dihapus');
                _loadUsers();
              } on ApiException catch (e) {
                _showSnackbar(e.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, {String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textSecondary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRoleOption(String value, String label, String selected, Function(String) onSelect) {
    final isSelected = selected == value;
    final color = value == 'admin' ? const Color(0xFF3B82F6) : AppTheme.success;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : AppTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : AppTheme.border, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(value == 'admin' ? Icons.shield : Icons.person, color: isSelected ? color : AppTheme.textSecondary, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? color : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? AppTheme.danger : AppTheme.success),
    );
  }
}
