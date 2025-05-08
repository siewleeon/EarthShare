import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ProductCondition { new_, almostNew, good, fair }

class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String category;
  final DateTime uploadTime;
  final DateTime editTime;
  final int quantity;
  final List<String> productCategory;
  final String sellerId;
  final List<String> imageId;
  final String description;
  final int degreeOfNewness;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.uploadTime,
    required this.editTime,
    required this.quantity,
    required this.productCategory,
    required this.sellerId,
    required this.imageId,
    required this.description,
    required this.degreeOfNewness,
  });

  // Create a copy with some fields changed
  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    String? category,
    DateTime? uploadTime,
    DateTime? editTime,
    int? quantity,
    List<String>? productCategory,
    String? sellerId,
    List<String>? imageId,
    String? description,
    int? degreeOfNewness,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      uploadTime: uploadTime ?? this.uploadTime,
      editTime: editTime ?? this.editTime,
      quantity: quantity ?? this.quantity,
      productCategory: productCategory ?? this.productCategory,
      sellerId: sellerId ?? this.sellerId,
      imageId: imageId ?? this.imageId,
      description: description ?? this.description,
      degreeOfNewness: degreeOfNewness ?? this.degreeOfNewness,
    );
  }

  // Convert from Firestore
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['product_Name'] ?? '',
      price: (map['product_Price'] ?? 0.0).toDouble(),
      imageUrl: (map['images'] as List<dynamic>?)?.isNotEmpty == true
          ? (map['images'] as List<dynamic>).first.toString()
          : '',
      category: (map['product_Category'] as List<dynamic>?)?.isNotEmpty == true
          ? (map['product_Category'] as List<dynamic>).first.toString()
          : '',
      uploadTime: (map['product_Upload_Time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      editTime: (map['product_Edit_Time'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantity: map['product_Quantity'] ?? 0,
      productCategory: List<String>.from(map['product_Category'] ?? []),
      sellerId: map['seller_ID'] ?? '',
      imageId: List<String>.from(map['images'] ?? []),
      description: map['product_Description'] ?? '',
      degreeOfNewness: map['degree_of_Newness'] ?? 1,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'product_ID':id,
      'product_Name': name,
      'product_Price': price,
      'product_Upload_': uploadTime.toIso8601String(),
      'product_Edit_Time': editTime.toIso8601String(),
      'product_Quantity': quantity,
      'product_Category': productCategory,
      'seller_ID': sellerId,
      'images': imageId,
      'product_Description': description,
      'degree_of_Newness': degreeOfNewness,
    };
  }

  String get conditionLabel {
    switch (degreeOfNewness) {
      case 1:
        return 'Brand New';
      case 2:
        return 'Almost New';
      case 3:
        return 'Good Condition';
      case 4:
        return 'Heavily Used';
      default:
        return 'Unknown';
    }
  }
}

// 硬编码的产品数据
// final List<Product> demoProducts = [
//   Product(
//     id: '1',
//     name: 'WATER Free Solution',
//     price: 20.0,
//     imageUrl: 'assets/images/water_free.jpg',
//     category: 'Beauty',
//     date: '01/11/2024',
//     tag: 'beauty',
//     description: 'A revolutionary water-free solution for your beauty needs. Eco-friendly and effective.',
//     condition: ProductCondition.almostNew,
//   ),
//   Product(
//     id: '2',
//     name: 'WATER Not Free Solution',
//     price: 40.0,
//     imageUrl: 'assets/images/water_not_free.jpg',
//     category: 'Health',
//     date: '01/11/2024',
//     tag: 'health',
//     description: 'Premium water-based solution for optimal health benefits.',
//     condition: ProductCondition.new_,
//   ),
//   Product(
//     id: '3',
//     name: 'CryBaby Doll 10',
//     price: 20.0,
//     imageUrl: 'assets/images/crybaby.jpg',
//     category: 'Beauty',
//     date: '01/11/2024',
//     tag: 'beauty',
//     description: 'The latest CryBaby doll with enhanced features and accessories.',
//     condition: ProductCondition.good,
//   ),
//   Product(
//     id: '4',
//     name: 'JoyCon NS【含清修的】',
//     price: 140.0,
//     imageUrl: 'assets/images/joycon.jpg',
//     category: 'Game',
//     date: '01/11/2024',
//     tag: 'game',
//     description: 'Refurbished Nintendo Switch JoyCon controllers, fully tested and cleaned.',
//     condition: ProductCondition.almostNew,
//   ),
// ];