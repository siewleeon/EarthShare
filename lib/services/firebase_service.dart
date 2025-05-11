import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../models/cart.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Products Collection
  CollectionReference<Map<String, dynamic>> get productsCollection => 
      _firestore.collection('products');

  // User Carts Collection
  CollectionReference<Map<String, dynamic>> getUserCartCollection(String userId) => 
      _firestore.collection('users').doc(userId).collection('cart');
  
  // Transactions Collection
  CollectionReference<Map<String, dynamic>> get transactionsCollection => 
      _firestore.collection('transactions');

  // Product Methods
  Future<List<Product>> getProducts() async {
    final snapshot = await productsCollection.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product.fromMap(data, id: doc.id);
    }).toList();
  }

  Future<Product?> getProduct(String productId) async {
    final doc = await productsCollection.doc(productId).get();
    if (doc.exists) {
      return Product.fromMap(doc.data()!, id: doc.id);
    }
    return null;
  }

  Future<void> addProduct(Product product) async {
    await productsCollection.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(Product product) async {
    await productsCollection.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) async {
    await productsCollection.doc(productId).delete();
  }

  // Cart Methods
  Future<Map<String, CartItem>> getUserCart() async {
    if (currentUserId == null) return {};
    
    final snapshot = await getUserCartCollection(currentUserId!).get();
    Map<String, CartItem> cartItems = {};
    
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final productId = doc.id;
      final productDoc = await productsCollection.doc(productId).get();
      
      if (productDoc.exists) {
        final product = Product.fromMap(productDoc.data()!, id: productId);
        cartItems[productId] = CartItem(
          id: data['id'] ?? doc.id,
          product: product,
          quantity: data['quantity'] ?? 1,
        );
      }
    }
    
    return cartItems;
  }

  Future<void> addToCart(String productId, int quantity) async {
    if (currentUserId == null) return;
    
    await getUserCartCollection(currentUserId!).doc(productId).set({
      'id': DateTime.now().toString(),
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateCartItemQuantity(String productId, int quantity) async {
    if (currentUserId == null) return;
    
    await getUserCartCollection(currentUserId!).doc(productId).update({
      'quantity': quantity,
    });
  }

  Future<void> removeFromCart(String productId) async {
    if (currentUserId == null) return;
    
    await getUserCartCollection(currentUserId!).doc(productId).delete();
  }

  Future<void> clearCart() async {
    if (currentUserId == null) return;
    
    final snapshot = await getUserCartCollection(currentUserId!).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // Transaction Methods
  Future<String> createTransaction(List<CartItem> items, double totalAmount) async {
    if (currentUserId == null) throw Exception('User not authenticated');
    
    final transactionData = {
      'userId': currentUserId,
      'items': items.map((item) => {
        'productId': item.product.id,
        'name': item.product.name,
        'price': item.product.price,
        'quantity': item.quantity,
      }).toList(),
      'totalAmount': totalAmount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    final docRef = await transactionsCollection.add(transactionData);
    return docRef.id;
  }
}
