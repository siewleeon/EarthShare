import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../main.dart';  // 导入 navigatorKey
import '../widgets/bottom_nav_bar.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';  // 添加这行
import 'cart_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailPage extends StatelessWidget {
  final String productId;  // 改为接收 productId
  
  const ProductDetailPage({
    super.key,
    required this.productId,  // 修改构造函数参数
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return FutureBuilder<Product?>(
          future: productProvider.getProductId(productId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('错误: ${snapshot.error}'),
                ),
              );
            }

            final product = snapshot.data;
            if (product == null) {
              return const Scaffold(
                body: Center(
                  child: Text('Product Not Found!!'),
                ),
              );
            }

            return Scaffold(
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, product),
                    _buildProductImage(product),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildProductInfo(product),
                      ),
                    ),
                    BottomNavBar(
                      currentIndex: -1, // 不高亮任何选项，因为这是详情页
                      onTap: (index) {
                        // 根据index处理导航
                        switch (index) {
                          case 0: // Home
                            Navigator.popUntil(context, (route) => route.isFirst);
                            break;
                          case 1: // Search
                            // TODO: 实现搜索页面导航
                            break;
                          case 2: // Post
                            // TODO: 实现发布页面导航
                            break;
                          case 3: // History
                            // TODO: 实现历史页面导航
                            break;
                          case 4: // Profile
                            // TODO: 实现个人资料页面导航
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  product.productCategory,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartPage(),
                    ),
                  );
                },
              ),
              Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.itemCount > 0) {
                    return Positioned(
                      right: 0,
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
    );
  }



  Widget _buildProductImage(Product product) {
    final PageController _pageController = PageController();

    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.purple[100],
          ),
          child: PageView.builder(
            controller: _pageController,
            itemCount: product.imageId.length,
            itemBuilder: (context, index) {
              return Image.network(
                product.imageId[index],
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.broken_image));
                },
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator());
                },
              );
            },
          ),
        ),

        // 小圆点指示器
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: SmoothPageIndicator(
              controller: _pageController,
              count: product.imageId.length,
              effect: WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                activeDotColor: Colors.white,
                dotColor: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
        ),

      ],
    );
  }



  Widget _buildProductInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'QTY ：${product.quantity.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Builder(
                builder: (context) => ElevatedButton.icon(
                  onPressed: () {
                    _addToCart(context, product);  // 添加 product 参数
                  },
                  icon: const Icon(Icons.shopping_cart,color: Colors.white),
                  label: const Text(''),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Post Edit: ${product.editTime}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildConditionSection(product),  // 添加 product 参数
        ],
      ),
    );
  }

  Widget _buildConditionSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.star,
              color: Colors.amber,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Condition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _getConditionText(product.degreeOfNewness),
                style: TextStyle(
                  color: Colors.blue[900],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildConditionDescription(product),  // 添加 product 参数
      ],
    );
  }

  String _getConditionText(int degreeOfNewness) {
    switch (degreeOfNewness) {
      case 1:
        return 'Brand New';
      case 2:
        return 'Almost New';
      case 3:
        return 'Good';
      case 4:
        return 'Heavily Used';
      default:
        return 'Unknown';
    }
  }

  Widget _buildConditionDescription(Product product) {
    String description;
    switch (product.degreeOfNewness) {
      case 1:
        description = 'Not yet used, Brand New';
      case 2:
        description = 'Used 1-5 times, Almost New';
      case 3:
        description = 'Used 6-10 times, Good Condition';
      case 4:
        description = 'More than 10 times, Heavily Used Condition';
      default:
        description = 'Condition unknown';
    }
    return Text(
      description,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 14,
      ),
    );

  }

  void _showAddToCartSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/success_leaf.png',
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Add to Cart Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green[300],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, Product product) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    // 检查购物车中该商品的当前数量
    final currentQuantityInCart = cart.getItemQuantity(product.id);

    // 如果购物车中的数量已经达到商品的库存量，显示提示信息
    if (currentQuantityInCart >= product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sorry, this product only left ${product.quantity}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 如果还未达到库存限制，则添加到购物车
    cart.addItem(
      product,
      quantity: 1,
    );
    _showAddToCartSuccess(context);
  }
}