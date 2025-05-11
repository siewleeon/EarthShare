import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';

class CartRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 获取当前用户ID
  Future<String?> getCurrentUserId() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    
    final doc = await _firestore
        .collection('Users')
        .doc(currentUser.uid)
        .get();
    
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['userId'];
    }
    return null;
  }

  // 获取用户购物车
  Future<Map<String, CartItem>> getUserCart(String userId) async {
    try {
      final DocumentSnapshot cartDoc = await _firestore
          .collection('carts')
          .doc(userId)
          .get();
      
      if (!cartDoc.exists) return {};
      
      final data = cartDoc.data() as Map<String, dynamic>;
      final Map<String, dynamic> items = data['items'] ?? {};
      
      final Map<String, CartItem> cartItems = {};
      
      // 这里需要获取每个产品的详细信息
      // 实际实现中可能需要批量获取产品信息
      for (var entry in items.entries) {
        final productId = entry.key;
        final itemData = entry.value as Map<String, dynamic>;
        
        // 获取产品信息
        final productDoc = await _firestore
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final productData = productDoc.data() as Map<String, dynamic>;
          final product = Product(
            id: productDoc.id,
            name: productData['product_Name'] ?? '',
            price: (productData['product_Price'] ?? 0.0).toDouble(),
            imageUrl: productData['imageUrl'] ?? '',
            productCategory: productData['category'] ?? '',
            uploadTime: DateTime.parse(productData['product_Upload_'] ?? DateTime.now().toIso8601String()),
            editTime: DateTime.parse(productData['product_Edit_Time'] ?? DateTime.now().toIso8601String()),
            quantity: productData['product_Quantity'] ?? 0,
            sellerId: productData['saller_ID'] ?? '',
            imageId: List<String>.from(productData['image_ID'] ?? []),
            description: productData['product_Description'] ?? '',
            degreeOfNewness: productData['degree_of_Newness'] ?? 1,
          );

          
          cartItems[productId] = CartItem(
            id: itemData['id'] ?? '',
            product: product,
            quantity: itemData['quantity'] ?? 1,
          );
        }
      }
      
      return cartItems;
    } catch (e) {
      debugPrint('获取用户购物车失败: $e');
      return {};
    }
  }

  // 更新用户购物车
  Future<bool> updateUserCart(String userId, Map<String, CartItem> items) async {
    try {
      final Map<String, dynamic> cartData = {
        'items': items.map((key, item) => MapEntry(key, {
          'id': item.id,
          'quantity': item.quantity,
        })),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('carts')
          .doc(userId)
          .set(cartData, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      debugPrint('更新用户购物车失败: $e');
      return false;
    }
  }

  // 添加商品到购物车
  Future<bool> addItemToCart(String userId, Product product, int quantity) async {
    try {
      final cartRef = _firestore.collection('carts').doc(userId);
      final cartDoc = await cartRef.get();
      final timestamp = firestore.Timestamp.now();
      if (!cartDoc.exists) {
        // 创建新购物车
        await cartRef.set({
          'items': {
            product.id: {
              'id':'C${timestamp.seconds}${timestamp.nanoseconds}',  
              'quantity': quantity,
            }
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // 更新现有购物车
        await cartRef.update({
          'items.${product.id}': {
            'id':'C${timestamp.seconds}${timestamp.nanoseconds}',  
            'quantity': FieldValue.increment(quantity),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      debugPrint('添加商品到购物车失败: $e');
      return false;
    }
  }

  // 从购物车移除商品
  Future<bool> removeItemFromCart(String userId, String productId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .update({
            'items.$productId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return true;
    } catch (e) {
      debugPrint('从购物车移除商品失败: $e');
      return false;
    }
  }

  // 清空购物车
  Future<bool> clearCart(String userId) async {
    try {
      await _firestore
          .collection('carts')
          .doc(userId)
          .update({
            'items': {},
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      return true;
    } catch (e) {
      debugPrint('清空购物车失败: $e');
      return false;
    }
  }

  // 解析产品状态
  ProductCondition _parseCondition(String? condition) {
    switch (condition) {
      case 'new':
        return ProductCondition.new_;
      case 'almostNew':
        return ProductCondition.almostNew;
      case 'good':
        return ProductCondition.good;
      case 'fair':
        return ProductCondition.fair;
      default:
        return ProductCondition.good;
    }
  }

  // 获取当前用户的购物车
  Future<Map<String, CartItem>> getDefaultUserCart() async {
    final userId = await getCurrentUserId();
    if (userId == null) return {};
    return getUserCart(userId);
  }

  // 更新当前用户的购物车
  Future<bool> updateDefaultUserCart(Map<String, CartItem> items) async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    return updateUserCart(userId, items);
  }

  // 添加商品到当前用户的购物车
  Future<bool> addItemToDefaultCart(Product product, int quantity) async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    return addItemToCart(userId, product, quantity);
  }

  // 从当前用户的购物车移除商品
  Future<bool> removeItemFromDefaultCart(String productId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    return removeItemFromCart(userId, productId);
  }

  // 清空当前用户的购物车
  Future<bool> clearDefaultCart() async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    return clearCart(userId);
  }
}
