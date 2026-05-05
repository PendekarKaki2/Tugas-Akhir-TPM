/// User Model
class UserModel {
  final int? id;
  final String username;
  final String password;
  final String? photo;
  final String? createdAt;
  final int level;
  final int xp;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    this.photo,
    this.createdAt,
    this.level = 1,
    this.xp = 0,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'photo': photo,
      'createdAt': createdAt,
      'level': level,
      'xp': xp,
    };
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      photo: json['photo'],
      createdAt: json['createdAt'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
    );
  }

  /// Create copy with modifications
  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    String? photo,
    String? createdAt,
    int? level,
    int? xp,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
    );
  }
}
