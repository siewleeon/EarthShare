import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalesReport extends StatefulWidget {
  const SalesReport({super.key});

  @override
  State<SalesReport> createState() => _SalesReportState();
}

class _SalesReportState extends State<SalesReport> {
  // Sorting state
  int _sortBy = 0; // 0: userID, 1: quantity, 2: profit
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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

  void _toggleSort(int sortType) {
    setState(() {
      if (_sortBy == sortType) {
        _isAscending = !_isAscending; // Toggle order if same button is pressed
      } else {
        _sortBy = sortType; // Switch to new sort type
        _isAscending = true; // Default to ascending for new sort
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,

        title: const Text('Sales Report'),

      ),
      body: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSortButtons(),
              ],
            ),
            Expanded(child: _buildSalesReportList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSortButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSortButton(Icons.person, 'UserID', 0),
        const SizedBox(width: 8),
        _buildSortButton(Icons.format_list_numbered, 'Quantity', 1),
        const SizedBox(width: 8),
        _buildSortButton(Icons.attach_money, 'Profit', 2),
      ],
    );
  }

  Widget _buildSortButton(IconData icon, String label, int sortType) {
    final isSelected = _sortBy == sortType;
    return GestureDetector(
      onTap: () => _toggleSort(sortType),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.grey,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSelected ? Colors.green : Colors.grey).withValues(alpha: 0.3),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 15, // Increased size for visibility
                  color: Colors.black, // Changed color for visibility
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesReportList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionSnapshot.hasError) {
          return Center(child: Text('Error: ${transactionSnapshot.error}'));
        }

        final transactions = transactionSnapshot.data?.docs ?? [];

        // Aggregate data by user
        Map<String, Map<String, dynamic>> userSales = {};
        for (var doc in transactions) {
          final data = doc.data() as Map<String, dynamic>;
          final userId = data['userId'] as String;
          final items = (data['items'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
          final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;

          if (!userSales.containsKey(userId)) {
            userSales[userId] = {'quantity': 0, 'totalProfit': 0.0};
          }

          userSales[userId]!['quantity'] += items.length;
          userSales[userId]!['totalProfit'] += totalAmount;
        }

        // Fetch user details to map userId to names
        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('Users').get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError) {
              return Center(child: Text('Error: ${userSnapshot.error}'));
            }

            final users = userSnapshot.data?.docs ?? [];
            final userMap = {for (var doc in users) doc['userId']: doc['name']};

            // No filtering, use all data
            var filteredUsers = userSales.entries.toList();

            // Sort based on selected criteria
            filteredUsers.sort((a, b) {
              final aValue = _sortBy == 0 ? a.key : (_sortBy == 1 ? a.value['quantity'] : a.value['totalProfit']);
              final bValue = _sortBy == 0 ? b.key : (_sortBy == 1 ? b.value['quantity'] : b.value['totalProfit']);
              return _isAscending
                  ? Comparable.compare(aValue, bValue)
                  : Comparable.compare(bValue, aValue);
            });

            if (filteredUsers.isEmpty) {
              return const Center(child: Text('No sales data found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final userId = filteredUsers[index].key;
                final salesData = filteredUsers[index].value;
                final userName = userMap[userId] ?? 'Unknown';

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(flex: 2, child: Text('User')),
                        Expanded(flex: 1, child: Text('Quantity')),
                        Expanded(flex: 1, child: Text('Total Profit')),
                      ],
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(flex: 2, child: Text(userName)),
                        Expanded(flex: 1, child: Text(salesData['quantity'].toString())),
                        Expanded(flex: 1, child: Text('\$${salesData['totalProfit'].toStringAsFixed(2)}')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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
            _buildNavItem(Icons.home, "Home", false),
            _buildNavItem(Icons.store, "Products", false),
            _buildNavItem(Icons.insert_chart, "Report", true),
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