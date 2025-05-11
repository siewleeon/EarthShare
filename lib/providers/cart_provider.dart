import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../repositories/cart_repository.dart';  
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class CartProvider with ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();
  Map<String, CartItem> _items = {};
  bool _isLoading = false;

  CartProvider() {
    _loadCartFromFirebase();
  }

  bool get isLoading => _isLoading;
  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) {
      return sum + item.totalPrice;
    });
  }

  Future<void> _loadCartFromFirebase() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _cartRepository.getDefaultUserCart();
    } catch (error) {
      debugPrint('Error loading cart: $error');
      // 保持默认商品如果出错
      // _items = {
      //   '1': CartItem(
      //     id: '1',
      //     product: Product(
      //       id: '1',
      //       name: 'WATER Free Solution',
      //       price: 20.0,
      //       imageUrl: 'assets/images/water_free.jpg',
      //       category: 'Beauty',
      //       date: '01/11/2024',
      //       tag: 'beauty',
      //       description: 'A revolutionary water-free solution for your beauty needs. Eco-friendly and effective.',
      //       condition: ProductCondition.almostNew,
      //     ),
      //     quantity: 2,
      //   ),
      // };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(Product product, {int quantity = 1}) async {
    debugPrint('🛒 addItem called: ${product.name}');

    try {
      if (_items.containsKey(product.id)) {
        final newQuantity = _items[product.id]!.quantity + quantity;
        _items.update(
          product.id,
          (existingItem) => existingItem.copyWith(
            quantity: newQuantity,
          ),
        );
        await _cartRepository.updateDefaultUserCart(_items);
      } else {
        final timestamp = firestore.Timestamp.now();
        final cartItem = CartItem(
          id: 'C${timestamp.seconds}${timestamp.nanoseconds}',  
          product: product,
          quantity: quantity,
        );
        _items.putIfAbsent(product.id, () => cartItem);
        await _cartRepository.addItemToDefaultCart(product, quantity);
      }

      // 打印购物车内容
      print('\n=== Cart Items ===');
      _items.forEach((key, item) {
        print('Product: ${item.product.name}');
        print('Quantity: ${item.quantity}');
        print('Price: RM${item.product.price}');
        print('Total: RM${(item.product.price * item.quantity).toStringAsFixed(2)}');
        print('-------------------');
      });
      print('Total Amount: RM${totalAmount.toStringAsFixed(2)}');
      print('==================\n');
      
      notifyListeners();
    } catch (error) {
      debugPrint('Error adding item to cart: $error');
      // Handle error (could show a snackbar or dialog)
    }
  }

  Future<void> removeItem(String productId) async {
    try {
      _items.remove(productId);
      await _cartRepository.removeItemFromDefaultCart(productId);
      notifyListeners();
    } catch (error) {
      debugPrint('Error removing item from cart: $error');
    }
  }

  Future<void> updateItemQuantity(String productId, int quantity) async {
    if (_items.containsKey(productId) && quantity > 0) {
      try {
        _items.update(
          productId,
          (existingItem) => existingItem.copyWith(quantity: quantity),
        );
        await _cartRepository.updateDefaultUserCart(_items);
        notifyListeners();
      } catch (error) {
        debugPrint('Error updating item quantity: $error');
      }
    }
  }

  Future<void> clear() async {
    try {
      _items.clear();
      await _cartRepository.clearDefaultCart();
      notifyListeners();
    } catch (error) {
      debugPrint('Error clearing cart: $error');
    }
  }

  Future<String?> checkout() async {
    try {
      if (_items.isEmpty) return null;
      
      // TODO: 需要添加 TransactionRepository 来处理交易
      // 暂时返回空
      return null;
    } catch (error) {
      debugPrint('Error during checkout: $error');
      return null;
    }
  }

  int getItemQuantity(String productId) {
    if (_items.containsKey(productId)) {
      return _items[productId]!.quantity;
    }
    return 0;
  }
}