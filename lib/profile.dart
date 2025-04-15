import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:p8userprofile/edit_profile.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String userId = 'U0001';
  String phone = '';
  String email = '';
  String address = '';
  bool isMember=false;
  String avatarUrl = '';
  String sampleAvatarUrl =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

  void _navigateToEditPage() async {
    final shouldRefresh = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(userId: userId),
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
    String userId = 'U0001';

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        username = data['name'] ?? username;
        phone = data['phone'] ?? phone;
        email = data['email'] ?? email;
        address = data['address'] ?? address;
        isMember=data['member_Status']?? isMember;
        avatarUrl=data['profile_Picture']?? avatarUrl;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(
                    isMember
                        ? 'assets/images/member_banner.png'
                        : 'assets/images/non_member_banner.png',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (avatarUrl == null || avatarUrl.isEmpty)
                        ? NetworkImage(sampleAvatarUrl)
                        : NetworkImage(avatarUrl),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isMember)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                      onPressed: () {
                        Navigator.pushNamed(context, '/upgradeMember');
                      },
                      child: Text(
                        'Upgrade to Member',
                        style: TextStyle(color: Colors.blue),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Member',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),


            // My Point Section
            Text('My Points', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/vouchers');
                  },
                  child: Text('Voucher'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/earningPoints');
                  },
                  child: Text('Earning Points'),
                ),
              ],
            ),

            SizedBox(height: 24),

            // My Store Section
            Text('My Store', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/myPosts');
                  },
                  child: Text('Post'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/history');
                  },
                  child: Text('History'),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Support Section
            Text('Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/contactUs');
                },
                child: Text('Contact Us'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
