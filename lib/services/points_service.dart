import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/point.dart';

class PointsService {
  static final _collection = FirebaseFirestore.instance.collection('points');

  static Future<void> addPoint({
    required String userId,
    required int points,
    required String description,
    required bool isIncrease,
  }) async {
    final snapshot = await _collection.orderBy('point_ID', descending: true).limit(1).get();

    String newId = 'P0001';
    if (snapshot.docs.isNotEmpty) {
      final lastId = snapshot.docs.first['point_ID'];
      final number = int.parse(lastId.substring(1)) + 1;
      newId = 'P${number.toString().padLeft(4, '0')}';
    }

    final point = Point(
      pointId: newId,
      userId: userId,
      points: points,
      description: description,
      createdAt: DateTime.now(),
      isIncrease: isIncrease,
    );

    await _collection.doc(newId).set(point.toMap());
  }

  static Future<List<Point>> getUserPoints(String userId) async {
    final snapshot = await _collection
        .where('user_ID', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs.map((doc) => Point.fromMap(doc.data())).toList();
  }

  static Future<int> getUserTotalPoints(String userId) async {
    final list = await getUserPoints(userId);
    int total = 0;
    for (final p in list) {
      total += p.isIncrease ? p.points : -p.points;
    }
    return total;
  }
}
