import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductRepository {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // 获取所有产品
  Future<List<Product>> getAllProducts() async {
    try {
      debugPrint('开始获取所有产品...');
      debugPrint('集合路径: ${_productsCollection.path}');

      final QuerySnapshot snapshot = await _productsCollection.get();
      debugPrint('获取到文档数量: ${snapshot.docs.length}');

      final products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('文档ID: ${doc.id}');
        debugPrint('文档数据: $data');

        return Product.fromMap(data, id: doc.id);
      }).toList();

      debugPrint('成功转换产品数量: ${products.length}');
      return products;
    } catch (e, stackTrace) {
      debugPrint('获取产品失败: $e');
      debugPrint('错误堆栈: $stackTrace');
      return [];
    }
  }

  // 获取单个产品
  Future<Product?> getProductById(String productId) async {
    try {
      final DocumentSnapshot doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return Product.fromMap(data, id: doc.id);
    } catch (e) {
      debugPrint('获取产品详情失败: $e');
      return null;
    }
  }



  // 添加产品
  Future<String?> addProduct(Product product) async {
    try {
      final docRef = await _productsCollection.add(product.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('添加产品失败: $e');
      return null;
    }
  }

  // 更新产品
  Future<bool> updateProduct(Product product) async {
    try {
      await _productsCollection.doc(product.id).update(product.toMap());
      return true;
    } catch (e) {
      debugPrint('更新产品失败: $e');
      return false;
    }
  }

  // 删除产品
  Future<bool> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
      return true;
    } catch (e) {
      debugPrint('删除产品失败: $e');
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
}
