import 'package:flutter/foundation.dart';
import '../models/point.dart';
import '../repositories/point_repository.dart';

class PointProvider extends ChangeNotifier {
  final PointRepository _pointRepository = PointRepository();  // 直接在类中初始化
  List<Point> _points = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Point> get points => [..._points];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 加载用户积分历史
  Future<void> loadUserPoints(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final points = await _pointRepository.getUserPoints(userId);
      _points = points;
    } catch (e) {
      _error = '加载积分历史失败: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 添加积分
  Future<bool> addPoints(Point point) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _pointRepository.addPoints(point);
      if (success) {
        _points.insert(0, point);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = '添加积分失败: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取用户总积分
  Future<int> getUserTotalPoints(String userId) async {
    try {
      return await _pointRepository.getUserTotalPoints(userId);
    } catch (e) {
      debugPrint('获取用户总积分失败: $e');
      return 0;
    }
  }
}