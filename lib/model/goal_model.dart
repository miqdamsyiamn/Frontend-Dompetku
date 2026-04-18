/// Model untuk data Goal dari API
class GoalModel {
  final String id;
  final String nama;
  final double targetAmount;
  final double currentAmount;

  GoalModel({
    required this.id,
    required this.nama,
    required this.targetAmount,
    required this.currentAmount,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: (json['id'] ?? 0).toString(),
    nama: json['nama'] ?? '',
    targetAmount: (json['target_amount'] ?? 0).toDouble(),
    currentAmount: (json['current_amount'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
  };

  double get progress => targetAmount > 0 ? currentAmount / targetAmount : 0.0;

  bool get isCompleted => currentAmount >= targetAmount;

  int get progressPercent => (progress * 100).round();
}
