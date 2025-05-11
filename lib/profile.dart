import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:second_hand_shop/accountSetting.dart';
import 'package:second_hand_shop/pages/Product/YourStoragePage.dart';
import 'package:second_hand_shop/pages/contactUs_page.dart';
import 'package:second_hand_shop/pages/points_page.dart';
import './edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/voucher_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  String username = '';
  String userId = '';
  String phone = '';
  String email = '';
  String avatarUrl = '';
  String sampleAvatarUrl =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';


  void _navigateToEditPage() async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfilePage(userUid: FirebaseAuth.instance.currentUser!.uid),
      ),
    );

    if (shouldRefresh == true) {
      _loadUserProfile();
    }
  }

  void _navigateToSettingPage() async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SettingsPage(),
      ),
    );

    if (shouldRefresh == true) {
      _loadUserProfile();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final UID = currentUser.uid;

    DocumentSnapshot doc =
    await FirebaseFirestore.instance.collection('Users').doc(UID).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        userId=data['userId'] ?? '';
        username = data['name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        avatarUrl = data['profile_Picture'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 内容区
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildTopSection(),

                    // Points section
                    buildCardSection("My Points", [
                      buildFeatureButton(
                        label: "Voucher",
                        icon: Icons.confirmation_number,
                        onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VoucherPage(),
                        ),
                      );
                    },
                      ),
                      buildFeatureButton(
                        label: "Earning Points",
                        icon: Icons.monetization_on,
                        iconBgColor: Colors.purple.shade50,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PointsPage(userId: userId),
                            ),
                          );
                        },
                      ),
                    ]),

                    // Store section
                    buildCardSection("My Store", [
                      buildFeatureButton(
                        label: "My Post",
                        icon: Icons.post_add,
                      ),
                      buildFeatureButton(
                        label: "History",
                        icon: Icons.lock_clock,
                        iconBgColor: Colors.grey,
                      ),
                    ]),
                buildCardSection("My Store", [
                  buildFeatureButton(
                    label: "My Post",
                    icon: Icons.post_add,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YourStorePage(currentUserId : userId),
                        ),
                      );
                    },
                  ),
                  buildFeatureButton(
                    label: "History",
                    icon: Icons.lock_clock,
                    iconBgColor: Colors.grey,
                    // 可以加跳转逻辑
                  ),
                ]),

                    // Support section
                    buildCardSection("Support", [
                      buildFeatureButton(
                        label: "Contact Us",
                        icon: Icons.support_agent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ContactUsPage(),
                            ),
                          );
                        },
                      ),
                    ]),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 15),
      child: Stack(
        children: [
          // Top content
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
                const SizedBox(width: 15),

                // User Info Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.black54),
                            padding: const EdgeInsets.only(left: 5),
                            constraints: const BoxConstraints(),
                            onPressed: _navigateToEditPage,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userId,
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Settings icon at top-left
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.black54),
              onPressed: _navigateToSettingPage,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCardSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 8,
                  offset: Offset(4, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: MediaQuery.of(context).orientation == Orientation.portrait ? 2 : 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: MediaQuery.of(context).size.width < 600 ? 1.2 : 1.5, // 适配屏幕尺寸
              physics: NeverScrollableScrollPhysics(),
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFeatureButton({
    required String label,
    required IconData icon,
    Color iconBgColor = Colors.lightGreenAccent,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
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
            _buildNavItem(Icons.home, 'Home',false),
            _buildNavItem(Icons.shopping_cart, 'Cart', false),
            _buildAddButton(),
            _buildNavItem(Icons.history, 'History', false),
            _buildNavItem(Icons.person, 'Profile', true),
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
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 'Cart':
              Navigator.pushReplacementNamed(context, '/cart');
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.blue,
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
      ),
    );
  }

}
