import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/transaction.dart' as model;
import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart.dart';

class TransactionRepository {
  final firestore.CollectionReference _transactionsCollection = 
      firestore.FirebaseFirestore.instance.collection('transactions');

  // 创建交易
  Future<String?> createTransaction(model.Transaction transaction) async {
    try {
      final timestamp = firestore.Timestamp.now();
      final docRef = await _transactionsCollection.add({
        'transaction_ID': 'T${timestamp.seconds}${timestamp.nanoseconds}', 
        'userId': transaction.userId,
        'items': transaction.items.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        }).toList(),
        'totalAmount': transaction.totalAmount,
        'status': transaction.status.toString().split('.').last,
        'paymentMethod': transaction.paymentMethod.toString().split('.').last,
        'shippingAddress': transaction.shippingAddress,
        'createdAt': firestore.FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('创建交易失败: $e');
      return null;
    }
  }

  // 获取用户交易历史
  Future<List<model.Transaction>> getUserTransactions(String userId) async {
    try {
      final firestore.QuerySnapshot snapshot = await _transactionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final itemsData = (data['items'] as List<dynamic>?) ?? [];
        
        final items = itemsData.map((item) {
          return CartItem(
            id: item['productId'] ?? '',
            product: Product(
              id: item['productId'] ?? '',
              name: '',  // 这些字段将从产品集合中获取
              price: (item['price'] ?? 0.0).toDouble(),
              imageUrl: '',
              category: '',
              uploadTime: DateTime.now(),  // 默认当前时间
              editTime: DateTime.now(),    // 默认当前时间
              quantity: 0,                 // 默认数量
              productCategory: [],         // 空分类列表
              sellerId: '',               // 空卖家ID
              imageId: [],                // 空图片ID列表
              description: '',            // 空描述
              degreeOfNewness: 1,         // 默认为全新(1)
            ),
            quantity: item['quantity'] ?? 1,
          );
        }).toList();

        return model.Transaction(
          id: doc.id,
          userId: data['userId'],
          items: items,
          totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
          status: _parseTransactionStatus(data['status']),
          paymentMethod: _parsePaymentMethod(data['paymentMethod']),
          shippingAddress: data['shippingAddress'] ?? '',
          createdAt: (data['createdAt'] as firestore.Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    } catch (e) {
      debugPrint('获取用户交易历史失败: $e');
      return [];
    }
  }

  // 更新交易状态
  Future<bool> updateTransactionStatus(String transactionId, model.TransactionStatus status) async {
    try {
      await _transactionsCollection.doc(transactionId).update({
        'status': status.toString().split('.').last,
      });
      return true;
    } catch (e) {
      debugPrint('更新交易状态失败: $e');
      return false;
    }
  }

  // 解析交易状态
  model.TransactionStatus _parseTransactionStatus(String? status) {
    switch (status) {
      case 'pending':
        return model.TransactionStatus.pending;
      case 'processing':
        return model.TransactionStatus.processing;
      case 'shipped':
        return model.TransactionStatus.shipped;
      case 'delivered':
        return model.TransactionStatus.delivered;
      case 'cancelled':
        return model.TransactionStatus.cancelled;
      default:
        return model.TransactionStatus.pending;
    }
  }

  // 解析支付方式
  model.PaymentMethod _parsePaymentMethod(String? method) {
    switch (method) {
      case 'creditCard':
        return model.PaymentMethod.creditCard;
      case 'cashOnDelivery':
        return model.PaymentMethod.cashOnDelivery;
      default:
        return model.PaymentMethod.creditCard;
    }
  }
}