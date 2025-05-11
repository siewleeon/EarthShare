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
  // 获取单个产品
  Future<Product?> getProductById2(String productId) async {
    try {
      // 使用 where 查询来匹配 product_ID 字段
      final QuerySnapshot querySnapshot = await _productsCollection
          .where('product_ID', isEqualTo: productId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return Product.fromMap(data, id: doc.id);  // 传入文档ID作为必需参数
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
  Future<bool> updateProduct2(Product product) async {
    try {
      // 先通过 product_ID 字段查找对应的文档
      final QuerySnapshot querySnapshot = await _productsCollection
          .where('product_ID', isEqualTo: product.id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('未找到产品文档: ${product.id}');
        return false;
      }

      // 获取实际的文档ID
      final docId = querySnapshot.docs.first.id;

      // 使用实际的文档ID进行更新
      await _productsCollection.doc(docId).update(product.toMap());
      debugPrint('成功更新产品: ${product.id}, docId: $docId');
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
