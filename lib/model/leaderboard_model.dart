/// Model untuk data Leaderboard entry dari API
class LeaderboardEntry {
  final int rank;
  final String userId;
  final String nama;
  final String username;
  final String? foto;
  final String? role;
  final double saldo;
  final double totalPemasukan;
  final double totalPengeluaran;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nama,
    required this.username,
    this.foto,
    this.role,
    required this.saldo,
    required this.totalPemasukan,
    required this.totalPengeluaran,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      foto: json['foto']?.toString(),
      role: json['role']?.toString(),
      saldo: (json['saldo'] ?? 0).toDouble(),
      totalPemasukan: (json['total_pemasukan'] ?? 0).toDouble(),
      totalPengeluaran: (json['total_pengeluaran'] ?? 0).toDouble(),
    );
  }
}

/// Model untuk detail distribusi dividen per user
class DividendDetail {
  final String userId;
  final String nama;
  final String? username;
  final double saldo;
  final double dividendAmount;
  final String transactionId;

  DividendDetail({
    required this.userId,
    required this.nama,
    this.username,
    required this.saldo,
    required this.dividendAmount,
    required this.transactionId,
  });

  factory DividendDetail.fromJson(Map<String, dynamic> json) {
    return DividendDetail(
      userId: json['user_id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString(),
      saldo: (json['saldo'] ?? 0).toDouble(),
      dividendAmount: (json['dividend_amount'] ?? 0).toDouble(),
      transactionId: json['transaction_id']?.toString() ?? '',
    );
  }
}

/// Model untuk response distribusi dividen
class DividendResult {
  final String message;
  final double percentage;
  final List<DividendDetail> distributions;
  final int count;

  DividendResult({
    required this.message,
    required this.percentage,
    required this.distributions,
    required this.count,
  });

  factory DividendResult.fromJson(Map<String, dynamic> json) {
    final list = (json['distributions'] as List?) ?? [];
    return DividendResult(
      message: json['message'] ?? '',
      percentage: (json['percentage'] ?? 0).toDouble(),
      distributions: list.map((e) => DividendDetail.fromJson(e)).toList(),
      count: json['count'] ?? 0,
    );
  }
}
