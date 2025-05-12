import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/pages/cart_page.dart';
import 'package:second_hand_shop/pages/product_detail_page.dart';
import 'dart:math';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'Product/post_page.dart';
import 'home_page.dart';
import 'package:visibility_detector/visibility_detector.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String userId = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )
      ..repeat();
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 添加背景和旋轉效果
      body: Stack(
        children: [
          // 旋轉的背景圖片
          // 修改旋轉背景部分
          // 修改旋轉背景部分 - 減小圖片尺寸


          // 主要內容
          Column(
            children: [
              // 半透明綠色 header，色號 #CCFF66
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xCCFF66),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [

                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const DashboardPage()),
                            );
                          },
                          child: Image.asset(
                            'assets/images/eslogo.png',
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox(width: 28);
                            },
                          ),
                        ),

                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart, color: Colors.black),
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
              ),

              // 主要內容使用 Expanded 和 SingleChildScrollView
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New User Banner - 使用您的高質量橫幅圖片
                      // 取代原本的 Padding(child: Image.asset('newUSER.png')) 那段
                      Transform.translate(
                        offset: const Offset(0, -30), // ❗調整這裡的 Y 值，越負越往上
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 280,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey,
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // ✅ 背景旋轉圖 Intersect.png
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, child) {
                                      return OverflowBox(
                                        maxWidth: double.infinity,
                                        maxHeight: double.infinity,
                                        child: Transform.rotate(
                                          angle: _controller.value * 2 * pi,
                                          alignment: Alignment.center,
                                          child: Image.asset(
                                            'assets/images/Intersect.png',
                                            width: 800,
                                            height: 500,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.center,
                                            errorBuilder: (context, error,
                                                stackTrace) {
                                              return Container(
                                                  color: Colors.green);
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // ✅ 前景的 New User Banner
                                  // ✅ 前景的 New User Banner 圖片，加上點擊跳轉
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (
                                            context) => const HomePage()),
                                      );
                                    },
                                    child: Image.asset(
                                      'assets/images/newUSER.png',
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      errorBuilder: (context, error,
                                          stackTrace) {
                                        return Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.green[900],
                                            borderRadius: BorderRadius.circular(
                                                16),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'New User Discount 50%',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ✅ Categories 標題列（放在外面）
                      // 🔼 向上移動 Categories 區塊
                      Transform.translate(
                        offset: const Offset(0, -12),
                        // 可以微調成 -8、-10、-16 視覺最舒服為準
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Categories',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF178120),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.arrow_forward),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HomePage(),

                                      /// 替換成你的分類頁 class
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

// ✅ 下方 Category Icons 保持不變
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      AnimatedCategoryItem(
                                        delay: const Duration(milliseconds: 0),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.checkroom,
                                              'Fashion', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 100),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.computer,
                                              'Electronic', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 200),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.directions_run,
                                              'Shoes', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 300),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.chair, 'Furniture',
                                              Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 400),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.brush, 'Beauty',
                                              Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 500),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.toys, 'Toy',
                                              Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 600),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.sports_esports,
                                              'Game', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 700),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.health_and_safety,
                                              'Health', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 800),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: 16.0),
                                          child: _buildCategoryItem(
                                              context, Icons.photo_camera,
                                              'Camera', Colors.black),
                                        ),
                                      ),
                                      AnimatedCategoryItem(
                                        delay: const Duration(
                                            milliseconds: 900),
                                        child: _buildCategoryItem(
                                            context, Icons.category, 'Other',
                                            Colors.black),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),


                      const SizedBox(height: 16),

                      // Second Hand Exchange Categories
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'New Second Hand Exchange Items',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF178120),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomePage(),

                                    /// 替換成你的分類頁 class
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // 🔻 Divider 保留
                      const Divider(),

// 🔻 Product Grid 加動畫（從左滑入）
                      const SizedBox(height: 16),

// 🔻 Save Earth Banner 加動畫（從右滑入）
                      AnimatedSlideInFromRight(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/saveearth.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 150,
                                    color: Colors.green[100],
                                    child: const Center(
                                        child: Text('Save Earth Banner')),
                                  ),
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 24),

// ♻️ 使用整张 PNG 展示设计好的宣传图
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          height: 250,
                          child: AnimatedSlideIn( // 從左滑入
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Image.asset(
                                      'assets/images/1.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error,
                                          stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          height: 250,
                          child: AnimatedSlideInFromRight( // 從右滑入
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Image.asset(
                                      'assets/images/2.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error,
                                          stackTrace) =>
                                      const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),


                      const SizedBox(height: 70), // Space for bottom navigation
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCategoryItem(BuildContext context, IconData icon, String label,
      Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(selectedCategory: label),
          ),
        );
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
                  color: Colors.grey,
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey,
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.search, 'Search', false),
            _buildAddButton(),
            _buildNavItem(Icons.history, 'History', false),
            _buildNavItem(Icons.person, 'Profile', false,),

          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          switch (label) {
            case 'Home':
              Navigator.pushNamed(context, '/home');
              break;
            case 'Search':
              Navigator.pushNamed(context, '/search');
              break;
            case 'History':
              Navigator.pushNamed(context, '/history');
              break;
            case 'Profile':
              Navigator.pushNamed(context, '/profile');
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/post');
      },
      child: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.cyanAccent, Colors.green[400]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green,
              spreadRadius: 1,
              blurRadius: 6,
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

class AnimatedSlideInFromRight extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSlideInFromRight({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedSlideInFromRight> createState() => _AnimatedSlideInFromRightState();
}

class _AnimatedSlideInFromRightState extends State<AnimatedSlideInFromRight> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0), // 🔁 從右邊滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_isVisible && info.visibleFraction > 0.1) {
      _controller.forward();
      _isVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: _onVisibilityChanged,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedSlideIn extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSlideIn({
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedSlideIn> createState() => _AnimatedSlideInState();
}

class _AnimatedSlideInState extends State<AnimatedSlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0), // 從左滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_isVisible && info.visibleFraction > 0.1) {
      _controller.forward();
      _isVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: _onVisibilityChanged,
      child: SlideTransition(
        position: _offsetAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

class AnimatedCategoryItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedCategoryItem({Key? key, required this.child, required this.delay}) : super(key: key);

  @override
  State<AnimatedCategoryItem> createState() => _AnimatedCategoryItemState();
}

class _AnimatedCategoryItemState extends State<AnimatedCategoryItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2), // 從上滑入
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}
