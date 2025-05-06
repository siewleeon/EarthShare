import 'package:flutter/foundation.dart';
import 'cart.dart';

enum TransactionStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled
}

enum PaymentMethod {
  creditCard,
  cashOnDelivery
}

class Transaction {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double totalAmount;
  final TransactionStatus status;
  final PaymentMethod paymentMethod;
  final String shippingAddress;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? transactionId,
    String? userId,
    List<CartItem>? items,
    double? totalAmount,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    String? shippingAddress,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}