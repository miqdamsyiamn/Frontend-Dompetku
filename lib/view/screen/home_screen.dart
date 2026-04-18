// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '/utils/app_theme.dart';
import '/services/api_services.dart';
import '/services/auth_manager.dart';
import '/model/summary_model.dart';
import '/model/transaction_model.dart';
import '/model/goal_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: HomeContent());
  }
}

class HomeContent extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const HomeContent({super.key, this.onNavigateToTab});

  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  bool _isLoading = true;
  SummaryModel? _summary;
  List<TransactionModel> _transactions = [];
  List<CategoryExpense> _expenseByCategory = [];
  List<GoalModel> _goals = [];
  String? _error;

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Warna untuk pie chart
  final _colors = [
    AppTheme.primary,
    AppTheme.success,
    AppTheme.danger,
    const Color(0xFF3B82F6),
    const Color(0xFFF59E0B),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF6B7280),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public method untuk load data ulang
  void loadData() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService().getSummary(),
        ApiService().getTransactions(),
        ApiService().getExpenseByCategory(),
        ApiService().getGoals(),
      ]);

      if (!mounted) return;
      setState(() {
        _summary = results[0] as SummaryModel;
        _transactions = results[1] as List<TransactionModel>;

        _transactions.sort((a, b) {
          final dateCompare = b.tanggal.compareTo(a.tanggal);
          if (dateCompare != 0) return dateCompare;
          return b.id.compareTo(a.id);
        });
        _expenseByCategory = results[2] as List<CategoryExpense>;
        _goals = results[3] as List<GoalModel>;
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

  @override
  Widget build(BuildContext context) {
    final user = AuthManager().user;
    final saldo = _summary?.saldo ?? 0;
    final pemasukan = _summary?.totalPemasukan ?? 0;
    final pengeluaran = _summary?.totalPengeluaran ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('DompetKu'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: AppTheme.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                user?['foto'] != null &&
                                    user!['foto'].toString().isNotEmpty
                                ? NetworkImage(user['foto'])
                                : null,
                            child:
                                user?['foto'] == null ||
                                    user!['foto'].toString().isEmpty
                                ? Icon(Icons.person, color: AppTheme.primary)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang,',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                user?['nama'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Section
                    Text(
                      'Ringkasan Keuangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Saldo',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currencyFormat.format(saldo),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Pemasukan',
                            pemasukan,
                            Icons.arrow_downward,
                            AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Pengeluaran',
                            pengeluaran,
                            Icons.arrow_upward,
                            AppTheme.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Goals Section
                    _buildSectionHeader('Goals', () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(2);
                      }
                    }),
                    const SizedBox(height: 12),
                    if (_goals.isEmpty)
                      _buildEmptyCard(Icons.savings_outlined, 'Belum ada goals')
                    else
                      Column(
                        children: _goals
                            .take(3)
                            .map((goal) => _buildGoalCard(goal))
                            .toList(),
                      ),
                    const SizedBox(height: 24),

                    // Chart Section
                    Text(
                      'Pengeluaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_expenseByCategory.isEmpty)
                      _buildEmptyCard(
                        Icons.pie_chart_outline,
                        'Belum ada data pengeluaran',
                      )
                    else
                      _buildPieChart(),
                    const SizedBox(height: 24),

                    // Transactions Section
                    _buildSectionHeader('Transaksi Terakhir', () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(1);
                      }
                    }),
                    const SizedBox(height: 12),
                    if (_transactions.isEmpty)
                      _buildEmptyCard(
                        Icons.receipt_long_outlined,
                        'Belum ada transaksi',
                      )
                    else
                      _buildTransactionList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
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
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onViewAll,
          child: Text(
            'Lihat Semua',
            style: TextStyle(color: AppTheme.primary, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyCard(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(GoalModel goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.nama,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (goal.isCompleted ? AppTheme.success : AppTheme.primary)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  goal.isCompleted ? 'Tercapai' : '${goal.progressPercent}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: goal.isCompleted
                        ? AppTheme.success
                        : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppTheme.success : AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_currencyFormat.format(goal.currentAmount)} / ${_currencyFormat.format(goal.targetAmount)}',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: _expenseByCategory.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final color = _colors[index % _colors.length];

                  return PieChartSectionData(
                    value: item.total,
                    title: '${item.percentage.toStringAsFixed(0)}%',
                    color: color,
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _expenseByCategory.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final color = _colors[index % _colors.length];

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.kategori,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.take(5).length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppTheme.border),
        itemBuilder: (context, index) {
          final tx = _transactions[index];

          return ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (tx.isPemasukan ? AppTheme.success : AppTheme.danger)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                tx.isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
                size: 20,
              ),
            ),
            title: Text(
              tx.catatan ?? (tx.isPemasukan ? 'Pemasukan' : 'Pengeluaran'),
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            subtitle: Text(
              tx.kategori ?? tx.tipe,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            trailing: Text(
              '${tx.isPemasukan ? '+' : '-'}${_currencyFormat.format(tx.nominal)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
              ),
            ),
          );
        },
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
