import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/pages/product_detail_page.dart';

import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'Product/post_page.dart';
import 'cart_page.dart';
import 'dashboardpage.dart';

class HomePage extends StatefulWidget {
  final String selectedCategory;

  const HomePage({super.key, this.selectedCategory = 'All'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchQuery = '';
  late String _selectedCategory;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      _loadUser();
    });
  }

  void _loadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final UID = currentUser.uid;
    DocumentSnapshot doc =
    await FirebaseFirestore.instance.collection('Users').doc(UID).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        userId = data['userId'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/eslogo.png',
          height: 40,
        ),
        backgroundColor: Colors.lightGreen,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartPage()),
                  );
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount > 0) {
                    return Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            _buildCategoriesScrollable(),
            Expanded(child: _buildProductGrid()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.cyan[50],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search products',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Alternative: Single-row scrollable layout with ListView
  Widget _buildCategoriesScrollable() {
    final categories = [
      {'label': 'All', 'icon': Icons.all_inclusive},
      {'label': 'Shoes', 'icon': Icons.directions_run},
      {'label': 'Fashion', 'icon': Icons.checkroom},
      {'label': 'Electronic', 'icon': Icons.computer},
      {'label': 'Toy', 'icon': Icons.toys},
      {'label': 'Furniture', 'icon': Icons.chair},
      {'label': 'Beauty', 'icon': Icons.brush},
      {'label': 'Health', 'icon': Icons.health_and_safety},
      {'label': 'Game', 'icon': Icons.sports_esports},
      {'label': 'Camera', 'icon': Icons.photo_camera},
      {'label': 'Other', 'icon': Icons.category},
    ];

    return SizedBox(
      height: 90, // Adjusted to fit icon + text
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final label = category['label'] as String;
          final icon = category['icon'] as IconData;
          final selected = _selectedCategory == label;

          return AnimatedCategoryItem(
            delay: Duration(milliseconds: index * 20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategory = label;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                        border: selected
                            ? Border.all(color: Colors.lightGreen, width: 2)
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: selected ? Colors.lightGreen : Colors.grey,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.lightGreen : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productProvider.error != null) {
          return Center(
            child: Text(
              '加载失败: ${productProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final products = productProvider.products.where((product) {
          final nameMatch = product.name.toLowerCase().contains(_searchQuery);
          final categoryMatch = _selectedCategory == 'All' ||
              product.productCategory == _selectedCategory;
          final notOwnedByUser = product.sellerId != userId;
          final noEmpty = product.quantity != 0;
          return nameMatch && categoryMatch && notOwnedByUser && noEmpty;
        }).toList();

        if (products.isEmpty) {
          return const Center(
            child: Text(
              'No Product',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Provider.of<ProductProvider>(context, listen: false).fetchProducts();
          },
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(productId: product.id),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final currentImageIndex = ValueNotifier<int>(0);
                            return Stack(
                              children: [
                                ValueListenableBuilder<int>(
                                  valueListenable: currentImageIndex,
                                  builder: (context, index, _) {
                                    return PageView.builder(
                                      itemCount: product.imageId.length,
                                      onPageChanged: (i) => currentImageIndex.value = i,
                                      itemBuilder: (context, i) {
                                        return Image.network(
                                          product.imageId[i],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        );
                                      },
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      product.conditionLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: ValueListenableBuilder<int>(
                                    valueListenable: currentImageIndex,
                                    builder: (context, index, _) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}/${product.imageId.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Product info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RM ${product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.productCategory,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Right side: Quantity display
                            Text(
                              'x${product.quantity}', // 假设你有 product.quantity
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.shopping_cart, 'Cart', false),
          _buildAddButton(),
          _buildNavItem(Icons.history, 'History', false),
          _buildNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Home':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 'Cart':
            Navigator.pushReplacementNamed(context, '/test');
            break;
          case 'History':
            Navigator.pushReplacementNamed(context, '/history');
            break;
          case 'Profile':
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.lightGreen : Colors.grey),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.lightGreen : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostPage()),
        );
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.lightGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.lightGreen.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
