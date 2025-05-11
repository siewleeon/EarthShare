import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/pages/Product/post_page.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../pages/order_summary_page.dart';
import '../pages/history_page.dart';

class CartPage extends StatefulWidget  {
  const CartPage({super.key});
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, child) {
            return Column(
              children: [
                _buildHeader(context, cart),
                if (cart.items.isNotEmpty) _buildProgressIndicator(cart),
                Expanded(
                  child: cart.items.isEmpty
                      ? _buildEmptyCart(context)
                      : _buildCartItems(context, cart),
                ),
                BottomNavBar(
                  currentIndex: -1,
                  onTap: (index) {
                    switch (index) {
                      case 0: // Home
                        Navigator.pop(context);
                        break;
                      case 1: // Search
                        // TODO: 实现搜索页面导航
                        break;
                      case 2: // Post
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PostPage(),
                          ),
                        );
                        break;
                      case 3: // History
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryPage(),
                          ),
                        );
                        break;
                      case 4: // Profile
                        // TODO: 实现个人资料页面导航
                        break;
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.lightGreen[100],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'EarthShare',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          Stack(
            children: [
              const Icon(
                Icons.shopping_cart,
                color: Colors.green,
                size: 28,
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _buildProgressStep(1, 'Review Cart', true),
              _buildProgressLine(true),
              _buildProgressStep(2, 'Order Summary', false),
              _buildProgressLine(false),
              _buildProgressStep(3, 'Payment', false),
              _buildProgressLine(false),
              _buildProgressStep(4, 'Order Completed', false),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'My Cart',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              if (cart.itemCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${cart.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int number, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isActive ? Colors.blue : Colors.grey[300],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/empty_cart.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 32),
          const Text(
            'Please Login Before',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Adding Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          const Text(
            'To The Cart',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'ADD ITEM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(BuildContext context, CartProvider cart) {
    final allItems = cart.items.values.toList();
    final filteredItems = allItems.where((item) {
      final matchesSearch = item.product.name.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        _buildSearchUI(),
        if (filteredItems.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                '无此产品',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                return _buildCartItem(context, item, cart);
              },
            ),
          ),
        _buildCartSummary(context, cart),
      ],
    );
  }

  Widget _buildSearchUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索商品名称',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    CartItem item,
    CartProvider cart,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageId[0],
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'RM ${item.product.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 12),
                                onPressed: () {
                                  if (item.quantity > 1) {
                                    cart.updateItemQuantity(item.product.id, item.quantity - 1);
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('confirm delete'),
                                        content: const Text('do u sure u want to delete?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text('cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              cart.removeItem(item.product.id);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text('confirm'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                                color: Colors.grey[600],
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 12),
                                onPressed: () {
                                  if (item.quantity >= item.product.quantity) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('已达到商品最大库存数量'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  cart.updateItemQuantity(item.product.id, item.quantity + 1);
                                },
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Text(
                        //   'RM${(item.product.price * item.quantity).toStringAsFixed(2)}',
                        //   style: const TextStyle(
                        //     color: Colors.green,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              cart.removeItem(item.product.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM ${cart.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderSummaryPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'PROCEED TO CHECKOUT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
