import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider with ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();
  List<Product> _products = [];
  Map<String, String> _productsIdToDocId = {};
  bool _isLoading = false;
  String? _error;
  bool _isDescending = true;

  List<Product> get products => [..._products];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final CollectionReference _productsCollection = FirebaseFirestore.instance.collection('products');

  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _productsCollection.get();
      _products = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final product = Product.fromMap(data, id: '');
        _productsIdToDocId[product.id] = doc.id;
        return product;
      }).toList();
      debugPrint('Products fetched: ${_products.length}');
    } catch (e) {
      _error = 'Failed to load products: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateNextProductId() async {
    try {
      if (_products.isEmpty) {
        await fetchProducts();
      }

      int maxNumber = 0;
      for (var product in _products) {
        final id = product.id;
        if (id.startsWith('P') && id.length == 5) {
          final numberPart = id.substring(1);
          final number = int.tryParse(numberPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      final nextNumber = maxNumber + 1;
      return 'P${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Failed to generate product ID: $e');
      return 'P0001';
    }
  }

  Future<String> generateSmallestNonTakenProductId() async {
    try {
      if (_products.isEmpty) {
        await fetchProducts();
      }

      final usedNumbers = _products
          .map((product) {
        final id = product.id;
        if (id.startsWith('P') && id.length == 5) {
          return int.tryParse(id.substring(1));
        }
        return null;
      })
          .where((number) => number != null)
          .cast<int>()
          .toSet();

      for (int i = 1; i <= 9999; i++) {
        if (!usedNumbers.contains(i)) {
          return 'P${i.toString().padLeft(4, '0')}';
        }
      }

      return 'P0001';
    } catch (e) {
      debugPrint('Failed to generate smallest non-taken product ID: $e');
      return 'P0001';
    }
  }

  void toggleSortProductsById() {
    _isDescending = !_isDescending;
    _products.sort((a, b) {
      final aNumber = int.parse(a.id.substring(1));
      final bNumber = int.parse(b.id.substring(1));
      return _isDescending ? bNumber.compareTo(aNumber) : aNumber.compareTo(bNumber);
    });
    notifyListeners();
  }

  Future<Product?> getProductId(String productId) async {
    final product = _products.firstWhere((p) => p.id == productId);
    return product;
  }

  Future<Product?> getProductById(String productId) async {
    try {
      return await _productRepository.getProductById(productId);
    } catch (e) {
      debugPrint('Failed to get product: $e');
      return null;
    }
  }

  List<Product> getUserProducts(String userId) {
    return _products.where((p) => p.sellerId == userId).toList();
  }

  Future<bool> addProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_products.any((p) => p.id == product.id)) {
        throw Exception('Product ID ${product.id} is already taken');
      }

      final docRef = await _productsCollection.add(product.toMap());
      final newProduct = product.copyWith(id: product.id);
      _products.add(newProduct);
      _productsIdToDocId[product.id] = docRef.id;
      debugPrint('Added product with doc ID: ${docRef.id}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to add product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProduct(Product product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docId = _productsIdToDocId[product.id];
      if (docId == null) {
        throw Exception('Document ID not found for product ${product.id}');
      }
      await _productsCollection.doc(docId).update(product.toMap());
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _products[index] = product;
        notifyListeners();
      }
      debugPrint('Updated product with doc ID: $docId');
      return true;
    } catch (e) {
      debugPrint('Failed to update product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String productId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docId = _productsIdToDocId[productId];
      if (docId == null) {
        throw Exception('Document ID not found for product $productId');
      }
      await _productsCollection.doc(docId).delete();
      _products.removeWhere((p) => p.id == productId);
      _productsIdToDocId.remove(productId);
      debugPrint('Deleted product with doc ID: $docId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete product: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((product) => product.productCategory == category).toList();
  }

  List<Product> getProductsByTag(String tag) {
    return _products.where((product) => product.productCategory == tag).toList();
  }


  List<Product> searchProducts(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _products.where((product) {
      return product.name.toLowerCase().contains(lowercaseQuery) ||
          product.description.toLowerCase().contains(lowercaseQuery) ||
          product.productCategory.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // 更新产品库存数量
  Future<bool> updateProductQuantity(String productId, int quantityToReduce) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 先获取当前产品
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        return false;
      }
      
      // 计算新的库存数量
      final newQuantity = product.quantity - quantityToReduce;
      if (newQuantity < 0) {
        return false;
      }
      
      // 创建更新后的产品对象
      final updatedProduct = product.copyWith(quantity: newQuantity);
      
      // 更新产品
      final success = await _productRepository.updateProduct(updatedProduct);
      if (success) {
        // 更新本地缓存
        final index = _products.indexWhere((p) => p.id == productId);
        if (index >= 0) {
          _products[index] = updatedProduct;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('更新产品库存失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}