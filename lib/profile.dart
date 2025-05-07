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
              crossAxisAlignment: CrossAxisAlignment.start, // Aligns the column content to the left
              children: [
                buildTopSection(),

                buildCardSection("My Points", [
                  buildFeatureButton(label: "Voucher", icon: Icons.card_giftcard),
                  buildFeatureButton(label: "Earning Points", icon: Icons.monetization_on, iconBgColor: Colors.purpleAccent),
                ]),

                buildCardSection("My Store", [
                  buildFeatureButton(label: "My Post", icon: Icons.post_add),
                  buildFeatureButton(label: "History", icon: Icons.lock_clock, iconBgColor: Colors.grey),
                ]),

                buildCardSection("Support", [
                  buildFeatureButton(label: "Contact Us", icon: Icons.contact_support, iconBgColor: Colors.green),
                ]),

                SizedBox(height: 80), // for bottom nav bar space
              ],
            ),
          ),

        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        backgroundColor: Colors.grey,
        onTap: (index) {
          // handle navigation
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home),label: 'Home'),
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
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bigger Avatar
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
                // Name + Edit Button Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        username,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 100, 0),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Icon(Icons.edit, size: 18, color: Colors.black54),
                        onPressed: _navigateToEditPage,
                      ),
                    ),
                  ],
                ),

                // Tighter layout between elements
                const SizedBox(height: 2),
                Text(
                  userId,
                  style: TextStyle(fontSize: 10, color: Colors.blue),
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
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () {
                    // go to upgrade page
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Upgrade to become member?',
                    style: TextStyle(
                      fontSize: 10,
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

  Widget buildCardSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.6,
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
        width: 130, 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
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



}
