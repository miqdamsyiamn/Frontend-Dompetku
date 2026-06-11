// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '/utils/app_theme.dart';
import '/utils/currency_input_formatter.dart';
import '/services/api_services.dart';
import '/model/transaction_model.dart';
import '/validator/transactions_validator.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen> {
  bool _isLoading = true;
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String? _error;
  String _filterType = 'semua';

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _setFilter(String filter) {
    setState(() {
      _filterType = filter;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_filterType == 'semua') {
      _filteredTransactions = List.from(_transactions);
    } else {
      _filteredTransactions = _transactions
          .where((tx) => tx.tipe == _filterType)
          .toList();
    }
    _filteredTransactions.sort((a, b) {
      final dateCompare = b.tanggal.compareTo(a.tanggal);
      if (dateCompare != 0) return dateCompare;
      return b.id.compareTo(a.id);
    });
  }

  void loadData() => _loadData();

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await ApiService().getTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _applyFilter();
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

  /// simpan transaksi
  Future<void> _performTransaction(
    Map<String, dynamic> data,
    bool isEdit,
    String? transactionId,
  ) async {
    try {
      if (isEdit && transactionId != null) {
        await ApiService().updateTransaction(transactionId, data);
        displaySnackbar('Transaksi berhasil diupdate');
      } else {
        await ApiService().createTransaction(data);
        displaySnackbar('Transaksi berhasil ditambahkan');
      }
      _loadData();
    } on ApiException catch (e) {
      displaySnackbar(e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView()
          : Column(
              children: [
                // Filter Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _buildFilterButton('Semua', 'semua'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Pemasukan', 'pemasukan'),
                      const SizedBox(width: 8),
                      _buildFilterButton('Pengeluaran', 'pengeluaran'),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: _filteredTransactions.isEmpty
                        ? _buildEmptyView()
                        : _buildTransactionList(),
                  ),
                ),
              ],
            ),
      floatingActionButton: Semantics(
        label: 'Tombol Tambah Transaksi',
        button: true,
        child: FloatingActionButton(
          onPressed: () => _showAddTransactionDialog(),
          backgroundColor: AppTheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filterType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setFilter(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + untuk menambah transaksi baru',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // Group by date
    Map<String, List<TransactionModel>> grouped = {};
    for (var tx in _filteredTransactions) {
      String dateKey = tx.tanggal.toIso8601String().split('T')[0];
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(tx);
    }

    List<String> sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        String dateKey = sortedDates[index];
        List<TransactionModel> dayTransactions = grouped[dateKey]!;

        DateTime? date;
        try {
          date = DateTime.parse(dateKey);
        } catch (_) {}

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                date != null ? _dateFormat.format(date) : dateKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            ...dayTransactions.map((tx) => _buildTransactionItem(tx)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel tx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetail(tx),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (tx.isPemasukan ? AppTheme.success : AppTheme.danger)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            tx.isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
            color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
          ),
        ),
        title: Text(
          tx.catatan ?? (tx.isPemasukan ? 'Pemasukan' : 'Pengeluaran'),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          tx.kategori ?? tx.tipe,
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          '${tx.isPemasukan ? '+' : '-'}${_currencyFormat.format(tx.nominal)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detail Transaksi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: AppTheme.textSecondary),
                  tooltip: 'Tutup',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tx.isPemasukan ? AppTheme.success : AppTheme.danger)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tx.isPemasukan ? Icons.arrow_downward : Icons.arrow_upward,
                    color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.catatan ??
                            (tx.isPemasukan ? 'Pemasukan' : 'Pengeluaran'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        tx.kategori ?? tx.tipe,
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '${tx.isPemasukan ? '+' : '-'}${_currencyFormat.format(tx.nominal)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: tx.isPemasukan ? AppTheme.success : AppTheme.danger,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransactionDialog(tx);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(tx);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Hapus'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    _showTransactionForm(isEdit: false);
  }

  void _showEditTransactionDialog(TransactionModel tx) {
    _showTransactionForm(isEdit: true, transaction: tx);
  }

  void _showTransactionForm({
    required bool isEdit,
    TransactionModel? transaction,
  }) {
    final formKey = GlobalKey<FormState>();
    String tipe = transaction?.tipe ?? 'pengeluaran';
    final nominalController = TextEditingController(
      text: isEdit
          ? NumberFormat.decimalPattern(
              'id_ID',
            ).format(transaction!.nominal.toInt())
          : '',
    );
    final catatanController = TextEditingController(
      text: isEdit ? (transaction?.catatan ?? '') : '',
    );
    String kategori = transaction?.kategori ?? 'Makanan & Minuman';
    DateTime tanggal = transaction?.tanggal ?? DateTime.now();

    final categories = [
      'Makanan & Minuman',
      'Transportasi',
      'Belanja',
      'Tagihan',
      'Hiburan',
      'Pendidikan',
      'Kesehatan',
      'Lainnya',
    ];

    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Edit Transaksi' : 'Tambah Transaksi',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipe
                          Text(
                            'Tipe Transaksi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => tipe = 'pemasukan'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: tipe == 'pemasukan'
                                          ? AppTheme.success.withOpacity(0.1)
                                          : AppTheme.background,
                                      border: Border.all(
                                        color: tipe == 'pemasukan'
                                            ? AppTheme.success
                                            : AppTheme.border,
                                        width: tipe == 'pemasukan' ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          color: tipe == 'pemasukan'
                                              ? AppTheme.success
                                              : AppTheme.textSecondary,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pemasukan',
                                          style: TextStyle(
                                            color: tipe == 'pemasukan'
                                                ? AppTheme.success
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setModalState(() => tipe = 'pengeluaran'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: tipe == 'pengeluaran'
                                          ? AppTheme.danger.withOpacity(0.1)
                                          : AppTheme.background,
                                      border: Border.all(
                                        color: tipe == 'pengeluaran'
                                            ? AppTheme.danger
                                            : AppTheme.border,
                                        width: tipe == 'pengeluaran' ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.arrow_upward,
                                          color: tipe == 'pengeluaran'
                                              ? AppTheme.danger
                                              : AppTheme.textSecondary,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pengeluaran',
                                          style: TextStyle(
                                            color: tipe == 'pengeluaran'
                                                ? AppTheme.danger
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Nominal
                          Text(
                            'Nominal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nominalController,
                            keyboardType: TextInputType.number,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              CurrencyInputFormatter(),
                            ],
                            decoration: InputDecoration(
                              prefixText: 'Rp ',
                              hintText: '0',
                              helperText:
                                  'Masukkan angka saja (contoh: 50.000)',
                              helperStyle: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: TransactionsValidator.validateNominal,
                          ),
                          const SizedBox(height: 20),

                          // Kategori (only for pengeluaran)
                          if (tipe == 'pengeluaran') ...[
                            Text(
                              'Kategori',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: kategori,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setModalState(() => kategori = v!),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Catatan
                          Text(
                            'Catatan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: catatanController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              hintText: 'Opsional',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Tanggal
                          Text(
                            'Tanggal',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tanggal,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setModalState(() => tanggal = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dateFormat.format(tanggal),
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;

                                final data = {
                                  'tipe': tipe,
                                  'nominal':
                                      CurrencyInputFormatter.parseFormattedValue(
                                        nominalController.text,
                                      ).toDouble(),
                                  'catatan': catatanController.text.isNotEmpty
                                      ? catatanController.text
                                      : null,
                                  'tanggal': DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(tanggal),
                                };

                                if (tipe == 'pengeluaran') {
                                  data['kategori'] = kategori;
                                }

                                // Pop modal with result data
                                Navigator.pop(context, {
                                  'data': data,
                                  'isEdit': isEdit,
                                  'id': transaction?.id,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Tambah Transaksi',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((result) {
      if (result != null) {
        _performTransaction(
          result['data'] as Map<String, dynamic>,
          result['isEdit'] as bool,
          result['id'] as String?,
        );
      }
    });
  }

  void _confirmDelete(TransactionModel tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteTransaction(tx.id);
                displaySnackbar('Transaksi berhasil dihapus');
                _loadData();
              } on ApiException catch (e) {
                displaySnackbar(e.message, isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void displaySnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
      ),
    );
  }
}
