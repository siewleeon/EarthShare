import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  // 获取所有产品
  List<Product> get products => [..._products];
  
  // 获取加载状态
  bool get isLoading => _isLoading;
  
  // 获取错误信息
  String? get error => _error;

  // 加载所有产品
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final products = await _productRepository.getAllProducts();
      _products = products;
      debugPrint(products.toString());
    } catch (e) {
      _error = '加载产品失败: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 根据ID获取产品
  Future<Product?> getProductById(String productId) async {
    try {
      return await _productRepository.getProductById(productId);
    } catch (e) {
      debugPrint('获取产品详情失败: $e');
      return null;
    }
  }

  // 添加产品
  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final productId = await _productRepository.addProduct(product);
      if (productId != null) {
        final newProduct = product.copyWith(id: productId);
        _products.add(newProduct);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('添加产品失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新产品
  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _productRepository.updateProduct(product);
      if (success) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index >= 0) {
          _products[index] = product;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('更新产品失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 删除产品
  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final success = await _productRepository.deleteProduct(productId);
      if (success) {
        _products.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除产品失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 按类别筛选产品
  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.productCategory == category).toList();
  }

  // 按标签筛选产品
  List<Product> getProductsByTag(String tag) {
    return _products.where((product) => product.productCategory == tag).toList();
  }

  // 搜索产品
  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
             product.description.toLowerCase().contains(lowercaseQuery) ||
             product.productCategory.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}