/// Model untuk data Summary/Ringkasan keuangan
class SummaryModel {
  final double saldo;
  final double totalPemasukan;
  final double totalPengeluaran;

  SummaryModel({
    required this.saldo,
    required this.totalPemasukan,
    required this.totalPengeluaran,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) => SummaryModel(
    saldo: (json['saldo'] ?? 0).toDouble(),
    totalPemasukan: (json['total_pemasukan'] ?? 0).toDouble(),
    totalPengeluaran: (json['total_pengeluaran'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'saldo': saldo,
    'total_pemasukan': totalPemasukan,
    'total_pengeluaran': totalPengeluaran,
  };
}

/// Model Category
class CategoryExpense {
  final String kategori;
  final double total;
  final double percentage;

  CategoryExpense({
    required this.kategori,
    required this.total,
    required this.percentage,
  });

  factory CategoryExpense.fromJson(Map<String, dynamic> json) =>
      CategoryExpense(
        kategori: json['kategori'] ?? 'Lainnya',
        total: (json['total'] ?? 0).toDouble(),
        percentage: (json['percentage'] ?? 0).toDouble(),
      );
}
