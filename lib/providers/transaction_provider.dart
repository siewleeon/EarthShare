import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionRepository _transactionRepository = TransactionRepository();
  List<Transaction> _transactions = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Transaction> get transactions => [..._transactions];
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 加载用户的交易历史
  Future<void> loadUserTransactions(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transactions = await _transactionRepository.getUserTransactions(userId);
      _transactions = transactions;
    } catch (e) {
      _error = '加载交易历史失败: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 创建新交易
  Future<String?> createTransaction(Transaction transaction) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final transactionId = await _transactionRepository.createTransaction(transaction);
      if (transactionId != null) {
        // 刷新交易列表
        await loadUserTransactions(transaction.userId);
        return transactionId;
      }
      return null;
    } catch (e) {
      _error = '创建交易失败: $e';
      debugPrint(_error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新交易状态
  Future<bool> updateTransactionStatus(String transactionId, TransactionStatus status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _transactionRepository.updateTransactionStatus(transactionId, status);
      if (success) {
        // 更新本地交易状态
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index >= 0) {
          _transactions[index] = _transactions[index].copyWith(status: status);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = '更新交易状态失败: $e';
      debugPrint(_error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取单个交易详情
  Transaction? getTransactionById(String transactionId) {
    return _transactions.firstWhere(
      (transaction) => transaction.id == transactionId,
      orElse: () => null as Transaction,
    );
  }

  // 清除错误信息
  void clearError() {
    _error = null;
    notifyListeners();
  }
}