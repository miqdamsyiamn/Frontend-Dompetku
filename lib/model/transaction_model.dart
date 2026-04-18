/// Model untuk data Transaksi dari API
class TransactionModel {
  final String id;
  final String tipe;
  final double nominal;
  final String? kategori;
  final String? catatan;
  final DateTime tanggal;

  TransactionModel({
    required this.id,
    required this.tipe,
    required this.nominal,
    this.kategori,
    this.catatan,
    required this.tanggal,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateStr = json['tanggal']?.toString().split('T')[0] ?? '';
      parsedDate = DateTime.parse(dateStr);
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: (json['id'] ?? 0).toString(),
      tipe: json['tipe'] ?? 'pengeluaran',
      nominal: (json['nominal'] ?? 0).toDouble(),
      kategori: json['kategori'],
      catatan: json['catatan'],
      tanggal: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipe': tipe,
    'nominal': nominal,
    'kategori': kategori,
    'catatan': catatan,
    'tanggal': tanggal.toIso8601String().split('T')[0],
  };

  bool get isPemasukan => tipe == 'pemasukan';
}
