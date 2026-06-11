/// Model untuk data User dari API
class UserModel {
  final String id;
  final String username;
  final String nama;
  final String? role;
  final String? foto;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.username,
    required this.nama,
    this.role,
    this.foto,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      role: json['role']?.toString(),
      foto: json['foto']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nama': nama,
    'role': role,
    'foto': foto,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}

/// Model untuk response autentikasi (login/register)
class AuthResponse {
  final String? token;
  final UserModel? user;
  final String? message;

  AuthResponse({this.token, this.user, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    token: json['token'],
    user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
    message: json['message'],
  );
}

/// Model untuk response admin get users (dengan pagination)
class AdminUsersResponse {
  final List<UserModel> users;
  final int count;
  final int total;
  final int page;
  final int limit;

  AdminUsersResponse({
    required this.users,
    required this.count,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AdminUsersResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['users'] as List?) ?? [];
    return AdminUsersResponse(
      users: list.map((e) => UserModel.fromJson(e)).toList(),
      count: json['count'] ?? 0,
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
    );
  }
}
