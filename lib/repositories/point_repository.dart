import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/point.dart';

class PointRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // 获取用户积分历史
  Future<List<Point>> getUserPoints(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('points')
          .where('user_ID', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Point.fromMap({...data, 'point_ID': doc.id});
      }).toList();
    } catch (e) {
      debugPrint('获取用户积分历史失败: $e');
      return [];
    }
  }

  // 添加积分记录
  Future<bool> addPoints(Point point) async {
    try {
      await _firestore.collection('points').doc(point.pointId).set(point.toMap());
      return true;
    } catch (e) {
      debugPrint('添加积分记录失败: $e');
      return false;
    }
  }

  // 获取用户总积分
  Future<int> getUserTotalPoints(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('points')
          .where('user_ID', isEqualTo: userId)
          .get();
      
      int totalPoints = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final points = data['points'] as int;
        final isIncrease = data['is_increase'] as bool;
        
        if (isIncrease) {
          totalPoints += points;
        } else {
          totalPoints -= points;
        }
      }
      
      return totalPoints;
    } catch (e) {
      debugPrint('获取用户总积分失败: $e');
      return 0;
    }
  }

  // 生成新的积分ID
  Future<String> generateNewPointId() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('points')
          .orderBy('point_ID', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'P0001';
      }

      final lastId = snapshot.docs.first['point_ID'] as String;
      final lastNumber = int.parse(lastId.substring(1));
      return 'P${(lastNumber + 1).toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('生成积分ID失败: $e');
      return 'P${DateTime.now().millisecondsSinceEpoch}';
    }
  }
}