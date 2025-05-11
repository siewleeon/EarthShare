import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/providers/transaction_provider.dart';
import 'Manage/manageContactMessagesPage.dart';
import 'Manage/manageFeedback_page.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<AdminProfile> {
  void changePage(int page) {
    switch (page) {
      case 0:
        {
          debugPrint("home");
          // Change page to Home(but this page already is home, so it will reload the page only)
          Navigator.pushReplacementNamed(context, "/adminPage");
          break;
        }
      case 1:
        {
          debugPrint("user");
          Navigator.pushNamed(context, "/manageUserPage");
          break;
        }
      case 2:
        {
          debugPrint("voucher");
          Navigator.pushNamed(context, "/manageVoucherPage");
          break;
        }
      case 3:
        {
          debugPrint("product");
          break;
        }
      case 4:
        {
          debugPrint("report");
          Navigator.pushNamed(context, "/salesReportPage");
          break;
        }
      case 5:
        {
          debugPrint("logout");
          Navigator.pushNamedAndRemoveUntil(context, '/adminLogin', (Route<dynamic> route) => false);
          break;
        }
      case 6:
        {
          debugPrint("contact messages");
          // Change page to Admin Login Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageContactMessagesPage()),
          );
          break;
        }
      case 7:
        {
          debugPrint("feedback");
          // Change page to Admin Login Page
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageFeedbackPage()),
          );
          break;
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TransactionProvider(),
      child: Consumer<TransactionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }

          return Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  // Header (unchanged)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('EarthManage', style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(
                            Icons.logout, color: Colors.white), onPressed: () =>
                            changePage(5)),
                      ],
                    ),
                  ),
                  // Menu Buttons (unchanged)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.5,
                      children: [
                        _buildMenuButton(icon: Icons.people,
                            label: 'Manage Users',
                            color: Colors.yellow[100]!,
                            onTap: () => changePage(1)),
                        _buildMenuButton(icon: Icons.store,
                            label: 'Manage Products',
                            color: Colors.blue[100]!,
                            onTap: () => changePage(3)),
                        _buildMenuButton(icon: Icons.local_offer,
                            label: 'Manage Voucher',
                            color: Colors.pink[100]!,
                            onTap: () => changePage(2)),
                        _buildMenuButton(icon: Icons.bar_chart,
                            label: 'Sales Report',
                            color: Colors.blue[100]!,
                            onTap: () => changePage(4)),
                      ],
                    ),
                  ),
                  // Weekly Summary (unchanged for now)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.blue,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Weekly Summary', style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [const Text('Total Sales Completed',
                                style: TextStyle(color: Colors.white)), Text(
                                '23', style: TextStyle(
                                color: Colors.white, fontSize: 20))
                            ]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [const Text('Total Profit Earned',
                                style: TextStyle(color: Colors.white)), Text(
                                '21', style: TextStyle(
                                color: Colors.white, fontSize: 20))
                            ]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [const Text('Product In Stock',
                                style: TextStyle(color: Colors.white)), Text(
                                '02', style: TextStyle(
                                color: Colors.white, fontSize: 20))
                            ]),
                      ],
                    ),
                  ),
                  // Total User with FutureBuilder
                  FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection(
                        'transactions').get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }
                      final transactions = snapshot.data?.docs ?? [];
                      Map<String, Map<String, dynamic>> userSales = {};
                      for (var doc in transactions) {
                        final data = doc.data() as Map<String, dynamic>;
                        final userId = data['userId'] as String;
                        final items = (data['items'] as List<dynamic>?)?.cast<
                            Map<String, dynamic>>() ?? [];
                        final totalAmount = (data['totalAmount'] as num?)
                            ?.toDouble() ?? 0.0;

                        if (!userSales.containsKey(userId)) {
                          userSales[userId] = {
                            'quantity': 0,
                            'totalProfit': 0.0
                          };
                        }
                        userSales[userId]!['quantity'] += items.length;
                        userSales[userId]!['totalProfit'] += totalAmount;
                      }
                      final totalUsers = userSales.length;
                      final totalPurchases = userSales.values.fold(
                          0, (sum, e) => sum + e['quantity'] as int);
                      final totalProfit = userSales.values.fold(
                          0.0, (sum, e) => sum + e['totalProfit']);
                      final averagePurchasePerUser = totalUsers > 0
                          ? (totalPurchases / totalUsers).round()
                          : 0;
                      final averageProfitPerUser = totalUsers > 0
                          ? (totalProfit / totalUsers).toStringAsFixed(2)
                          : '0.00';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.green,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total User', style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Average Purchase Per User',
                                    style: TextStyle(color: Colors.white)),
                                Text(averagePurchasePerUser.toString(),
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 20)),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Average Profit Per User',
                                    style: TextStyle(color: Colors.white)),
                                Text('\$$averageProfitPerUser',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 20)),
                              ],
                            ),
                            Row(
                              children: [
                                // This button is Manage Products
                                ElevatedButton(
                                  onPressed: () {
                                    changePage(6);
                                  },
                                  child: const Text('Contact Messages'),
                                ),
                                // This button is Sales Report
                                ElevatedButton(
                                  onPressed: () {
                                    changePage(7);
                                  },
                                  child: const Text('Feedback'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        },
      ),
    );
  }


  Widget _buildMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
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
            _buildNavItem(Icons.person_outline, "User", false),
            _buildNavItem(Icons.local_offer, "Voucher", false),
            _buildNavItem(Icons.home, 'Home', true),
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