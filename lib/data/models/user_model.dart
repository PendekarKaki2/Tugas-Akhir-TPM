/// User Model
class UserModel {
  final int? id;
  final String username;
  final String password;
  final String role;
  final String? photo;
  final String? createdAt;
  final int level;
  final int xp;
  final bool isPremium;

  UserModel({
    this.id,
    required this.username,
    required this.password,
    this.role = 'student',
    this.photo,
    this.createdAt,
    this.level = 1,
    this.xp = 0,
    this.isPremium = false,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'photo': photo,
      'createdAt': createdAt,
      'level': level,
      'xp': xp,
      'isPremium': isPremium ? 1 : 0,
    };
  }

  /// Create from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      username: json['username'],
      password: json['password'],
      role: json['role'] ?? 'student',
      photo: json['photo'],
      createdAt: json['createdAt'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      isPremium: (() {
        final raw = json['isPremium'] ?? json['is_premium'];
        if (raw is bool) return raw;
        if (raw is int) return raw == 1;
        if (raw is String) return raw.toLowerCase() == 'true' || raw == '1';
        return false;
      })(),
    );
  }

  /// Create copy with modifications
  UserModel copyWith({
    int? id,
    String? username,
    String? password,
    String? role,
    String? photo,
    String? createdAt,
    int? level,
    int? xp,
    bool? isPremium,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      role: role ?? this.role,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
