import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'editUser_page.dart';

class ManageUserPage extends StatefulWidget {
  const ManageUserPage({super.key});

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _sortBy = 'name';
  String _searchBy = 'name';
  final List<String> _sortOptions = ['name', 'userId', 'email'];
  final List<String> _searchOptions = ['name', 'email'];

  void changePage(int page) {
    switch (page) {
      case 0:
        debugPrint("home");
        Navigator.pushReplacementNamed(context, "/adminPage");
        break;
      case 1:
        debugPrint("user");
        Navigator.pushReplacementNamed(context, "/manageUserPage");
        break;
      case 2:
        debugPrint("voucher");
        Navigator.pushReplacementNamed(context, "/manageVoucherPage");
        break;
      case 3:
        debugPrint("product");
        Navigator.pushReplacementNamed(context, "/manageProductPage");
        break;
      case 4:
        debugPrint("report");
        Navigator.pushReplacementNamed(context, "/salesReportPage");
        break;
      case 5:
        debugPrint("logout");
        Navigator.pushNamedAndRemoveUntil(context, '/adminLogin', (Route<dynamic> route) => false);
        break;
      default:
        break;
    }
  }

  // 获取所有用户
  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('Users').get();

      List<Map<String, dynamic>> users = querySnapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          'userId': doc['userId'],
          'name': doc['name'],
          'phone': doc['phone'],
          'email': doc['email'],
          'profile_picture': doc['profile_Picture'],
        };
      }).toList();

      // 用 Dart 本地排序（忽略大小写）
      users.sort((a, b) => a[_sortBy].toString().toLowerCase().compareTo(
        b[_sortBy].toString().toLowerCase(),
      ));

      return users;
    } catch (e) {
      print("Error fetching users: $e");
      return [];
    }
  }

  // 搜索用户
  Future<List<Map<String, dynamic>>> _searchUsers() async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('Users')
          .where(_searchBy, isGreaterThanOrEqualTo: _searchQuery)
          .where(_searchBy, isLessThanOrEqualTo: _searchQuery + '\uf8ff')
          .orderBy(_searchBy)
          .get();

      return querySnapshot.docs.map((doc) {
        return {
          'uid': doc.id,
          'userId': doc['userId'],
          'name': doc['name'],
          'phone': doc['phone'],
          'email': doc['email'],
          'profile_picture': doc['profile_Picture'],
        };
      }).toList();

    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  // 删除用户
  Future<void> _deleteUser(String uid) async {
    try {
      // 先删除Firestore中的用户数据
      await _firestore.collection('Users').doc(uid).delete();

      // 然后删除Firebase Authentication中的用户
      await FirebaseAuth.instance.currentUser!.delete();

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      print("Error deleting user: $e");
    }
  }

  // 编辑用户信息
  Future<void> _editUser(Map<String, dynamic> user) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditUserPage(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text.trim();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Users',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              DropdownButton<String>(
                value: _searchBy,
                onChanged: (value) {
                  setState(() {
                    _searchBy = value!;
                  });
                },
                items: _searchOptions
                    .map((field) => DropdownMenuItem(
                  value: field,
                  child: Text('Search by ${field[0].toUpperCase()}${field.substring(1)}'),
                ))
                    .toList(),
              ),
              DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                },
                items: _sortOptions
                    .map((field) => DropdownMenuItem(
                  value: field,
                  child: Text('Sort by ${field[0].toUpperCase()}${field.substring(1)}'),
                ))
                    .toList(),
              ),
            ],
          ),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _searchQuery.isEmpty ? _fetchUsers() : _searchUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching users'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No users found.'));
                } else {
                  List<Map<String, dynamic>> users = snapshot.data!;
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      return ListTile(
                        leading: user['profile_picture'] != null
                            ? CircleAvatar(
                          backgroundImage: NetworkImage(user['profile_picture']),
                        )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(user['name']),
                        subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('User ID: ${user['userId']}'),
                          Text('Email: ${user['email']}'),
                        ],
                      ),

                      trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editUser(user);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                _deleteUser(user['uid']);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.5),
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
            _buildNavItem(Icons.person_outline, "User", true),
            _buildNavItem(Icons.local_offer, "Voucher", false),
            _buildNavItem(Icons.home, "Home", false),
            _buildNavItem(Icons.store, "Products", false),
            _buildNavItem(Icons.insert_chart, "Report", false),
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
              changePage(0);
              break;
            case 'User':
              changePage(1);
              break;
            case 'Voucher':
              changePage(2);
              break;
            case 'Products':
              changePage(3);
              break;
            case 'Report':
              changePage(4);
              break;
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: isSelected ? const EdgeInsets.all(8) : EdgeInsets.zero,
              decoration: isSelected
                  ? BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue[100],
              )
                  : null,
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
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
}
