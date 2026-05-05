/// Badge Model
class BadgeModel {
  final int? id;
  final int userId;
  final String badgeName;
  final String? badgeIcon;
  final String? unlockedAt;

  BadgeModel({
    this.id,
    required this.userId,
    required this.badgeName,
    this.badgeIcon,
    this.unlockedAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'badgeName': badgeName,
      'badgeIcon': badgeIcon,
      'unlockedAt': unlockedAt,
    };
  }

  /// Create from JSON
  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'],
      userId: json['userId'],
      badgeName: json['badgeName'],
      badgeIcon: json['badgeIcon'],
      unlockedAt: json['unlockedAt'],
    );
  }
}
