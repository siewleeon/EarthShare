import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:EarthShareApp/edit_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String address = '';
  bool isMember = false;
  String avatarUrl = '';
  String sampleAvatarUrl =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

  void _navigateToEditPage() async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
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

    final userId = currentUser.uid;

    DocumentSnapshot doc =
    await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        username = data['name'] ?? '';
        phone = data['phone'] ?? '';
        email = data['email'] ?? '';
        address = data['address'] ?? '';
        isMember = data['member_Status'] ?? false;
        avatarUrl = data['profile_Picture'] ?? '';
      });
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fullscreen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/profile_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Foreground content
          SingleChildScrollView(
            child: Column(
              children: [
                buildTopSection(),

                const SizedBox(height: 20),

                // My Points section
                buildSection(
                  context,
                  title: 'My Points',
                  items: [
                    buildIconButton(context, 'Voucher', Icons.confirmation_number, '/vouchers', Colors.lightGreen),
                    buildIconButton(context, 'Earning Points', Icons.stars, '/earningPoints', Colors.deepPurpleAccent),
                  ],
                ),

                // My Store section
                buildSection(
                  context,
                  title: 'My Store',
                  items: [
                    buildIconButton(context, 'My Post', Icons.post_add, '/myPosts', Colors.lightGreen),
                    buildIconButton(context, 'History', Icons.lock_clock, '/history', Colors.grey.shade300),
                  ],
                ),

                // Support section
                buildSection(
                  context,
                  title: 'Support',
                  items: [
                    buildIconButton(context, 'Contact Us', Icons.support_agent, '/contactUs', Colors.lightGreen),
                  ],
                ),

                const SizedBox(height: 40), // space for bottom navigation
              ],
            ),
          ),
        ],
      ),
      // Optional: bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          // handle navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Post'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget buildTopSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24), // 调整顶部间距适配背景图
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Avatar
          CircleAvatar(
            radius: 36,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          const SizedBox(width: 16),
          // Right: User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _navigateToEditPage,
                      icon: Icon(Icons.edit, size: 20, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userId,
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.lightBlueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Non-Member',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // go to upgrade page
                  },
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  child: Text(
                    'Upgrade to become member?',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSection(BuildContext context,
      {required String title, required List<Widget> items}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildIconButton(BuildContext context, String label, IconData icon,
      String route, Color bgColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}
