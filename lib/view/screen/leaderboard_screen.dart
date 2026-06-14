// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '/utils/app_theme.dart';
import '/services/api_services.dart';
import '/model/leaderboard_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _isLoading = true;
  List<LeaderboardEntry> _leaderboard = [];
  String? _error;
  bool _isDistributing = false;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Podium colors
  static const _goldColor = Color(0xFFFFD700);
  static const _silverColor = Color(0xFFC0C0C0);
  static const _bronzeColor = Color(0xFFCD7F32);

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService().adminGetLeaderboard();
      if (!mounted) return;
      setState(() {
        _leaderboard = data;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return _goldColor;
      case 2:
        return _silverColor;
      case 3:
        return _bronzeColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getMedalEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: _leaderboard.isEmpty
                      ? _buildEmptyView()
                      : _buildContent(),
                ),
      floatingActionButton: _leaderboard.length >= 3
          ? Semantics(
              label: 'Tombol Bagikan Dividen',
              button: true,
              child: FloatingActionButton.extended(
                onPressed: _isDistributing ? null : _showDividendConfirmation,
                backgroundColor: const Color(0xFFFFD700),
                icon: const Icon(Icons.card_giftcard, color: Color(0xFF7B6700)),
                label: const Text(
                  'Bagikan Dividen',
                  style: TextStyle(
                    color: Color(0xFF7B6700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppTheme.danger),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Terjadi kesalahan',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLeaderboard,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 80, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Belum ada data leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'User perlu melakukan transaksi terlebih dahulu',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final top3 = _leaderboard.take(3).toList();
    final rest = _leaderboard.length > 3 ? _leaderboard.sublist(3) : <LeaderboardEntry>[];

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // Podium Section
          _buildPodiumSection(top3),
          const SizedBox(height: 8),
          // Dividen info card
          _buildDividendInfoCard(top3),
          // Full ranking list
          if (rest.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.format_list_numbered, color: AppTheme.textSecondary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Peringkat Lainnya',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ...rest.map((entry) => _buildRankingCard(entry)),
          ],
          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildPodiumSection(List<LeaderboardEntry> top3) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                const Text(
                  'Leaderboard Saldo',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${_leaderboard.length} user terdaftar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 12),
            // Podium
            SizedBox(
              height: 245,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 2nd place
                  if (top3.length >= 2) Expanded(child: _buildPodiumItem(top3[1], 2, 65)),
                  if (top3.length < 2) const Expanded(child: SizedBox()),
                  const SizedBox(width: 6),
                  // 1st place
                  if (top3.isNotEmpty) Expanded(child: _buildPodiumItem(top3[0], 1, 90)),
                  const SizedBox(width: 6),
                  // 3rd place
                  if (top3.length >= 3) Expanded(child: _buildPodiumItem(top3[2], 3, 45)),
                  if (top3.length < 3) const Expanded(child: SizedBox()),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumItem(LeaderboardEntry entry, int position, double podiumHeight) {
    final medalColor = _getMedalColor(position);
    final isFirst = position == 1;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown for 1st place
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 18)),
        // Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: medalColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: medalColor.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 24 : 20,
            backgroundColor: Colors.white,
            backgroundImage: entry.foto != null && entry.foto!.isNotEmpty
                ? NetworkImage(entry.foto!)
                : null,
            child: entry.foto == null || entry.foto!.isEmpty
                ? Icon(Icons.person, size: isFirst ? 22 : 18, color: AppTheme.primary)
                : null,
          ),
        ),
        const SizedBox(height: 4),
        // Name
        Text(
          entry.nama,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isFirst ? 11 : 10,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Username
        Text(
          '@${entry.username}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: isFirst ? 10 : 9,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Saldo
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _currencyFormat.format(entry.saldo),
            style: TextStyle(
              color: medalColor,
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 11 : 10,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        // Podium block
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                medalColor.withOpacity(0.8),
                medalColor.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getMedalEmoji(position),
                style: const TextStyle(fontSize: 20),
              ),
              Text(
                '#$position',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDividendInfoCard(List<LeaderboardEntry> top3) {
    final eligibleUsers = top3.where((e) => e.saldo > 0).toList();
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFB8860B), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dividen 5%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${eligibleUsers.length} user berhak menerima dividen',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...eligibleUsers.map((entry) {
            final dividend = entry.saldo * 0.05;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(_getMedalEmoji(entry.rank), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.nama,
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                  Text(
                    '+${_currencyFormat.format(dividend)}',
                    style: TextStyle(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankingCard(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ),
        title: Text(
          entry.nama,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
        ),
        subtitle: Text(
          '@${entry.username}',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Text(
          _currencyFormat.format(entry.saldo),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: entry.saldo >= 0 ? AppTheme.primary : AppTheme.danger,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showDividendConfirmation() {
    final top3 = _leaderboard.take(3).where((e) => e.saldo > 0).toList();

    if (top3.isEmpty) {
      _showSnackbar('Tidak ada user dengan saldo positif', isError: true);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Konfirmasi Distribusi Dividen', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dividen 5% dari saldo akan diberikan ke:',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ...top3.map((entry) {
                final dividend = entry.saldo * 0.05;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getMedalColor(entry.rank).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getMedalColor(entry.rank).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_getMedalEmoji(entry.rank), style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.nama,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Saldo: ${_currencyFormat.format(entry.saldo)}',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${_currencyFormat.format(dividend)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.success,
                            ),
                          ),
                          Text(
                            '5%',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaksi pemasukan akan otomatis ditambahkan ke akun masing-masing user.',
                        style: TextStyle(fontSize: 12, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _distributeDividend();
            },
            icon: const Icon(Icons.card_giftcard, size: 18),
            label: const Text('Bagikan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: const Color(0xFF7B6700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _distributeDividend() async {
    setState(() => _isDistributing = true);

    try {
      final result = await ApiService().adminDistributeDividend(percentage: 5, topN: 3);
      _showSnackbar('${result.message} ke ${result.count} user');
      // Show success dialog
      if (mounted) {
        _showSuccessDialog(result);
      }
      _loadLeaderboard(); // Refresh leaderboard
    } on ApiException catch (e) {
      _showSnackbar(e.message, isError: true);
    } catch (e) {
      _showSnackbar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isDistributing = false);
    }
  }

  void _showSuccessDialog(DividendResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('✅', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Expanded(child: Text('Dividen Berhasil!', style: TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...result.distributions.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(d.nama, style: TextStyle(color: AppTheme.textPrimary)),
                  ),
                  Text(
                    '+${_currencyFormat.format(d.dividendAmount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }
}
