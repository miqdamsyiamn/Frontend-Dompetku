/// Model untuk data User dari API
class UserModel {
  final int id;
  final String username;
  final String nama;
  final String? foto;

  UserModel({
    required this.id,
    required this.username,
    required this.nama,
    this.foto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle id as either int or String from API
    int parsedId = 0;
    final rawId = json['id'];
    if (rawId is int) {
      parsedId = rawId;
    } else if (rawId is String) {
      parsedId = int.tryParse(rawId) ?? 0;
    }

    return UserModel(
      id: parsedId,
      username: json['username']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      foto: json['foto']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'nama': nama,
    'foto': foto,
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
