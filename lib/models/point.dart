
class Point {
  final String pointId;      // P0001 格式
  final String userId;       // U0001 格式
  final int points;          // 积分数量
  final String description;  // 交易ID描述
  final DateTime createdAt;  // 创建时间
  final bool isIncrease;     // true 表示增加积分, false 表示减少积分

  Point({
    required this.pointId,
    required this.userId,
    required this.points,
    required this.description,
    required this.createdAt,
    required this.isIncrease,
  });

  // 从 Firestore 转换
  factory Point.fromMap(Map<String, dynamic> map) {
    return Point(
      pointId: map['point_ID'] ?? '',
      userId: map['user_ID'] ?? '',
      points: map['points'] ?? 0,
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      isIncrease: map['is_increase'] ?? true,
    );
  }

  // 转换到 Firestore
  Map<String, dynamic> toMap() {
    return {
      'point_ID': pointId,
      'user_ID': userId,
      'points': points,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'is_increase': isIncrease,
    };
  }
}