import 'package:flutter/material.dart';

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
          Navigator.pushReplacementNamed(context, "/adminPage");
          break;
        }
      case 1:
        {
          debugPrint("user");
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
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EarthManage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () {changePage(5);},
                  ),
                ],
              ),
            ),
            // Menu Buttons in Grid
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2, // 2 columns
                shrinkWrap: true, // Fit content within the parent
                physics: const NeverScrollableScrollPhysics(), // Disable scrolling
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5, // Adjust the aspect ratio for wider buttons
                children: [
                  _buildMenuButton(
                    icon: Icons.people,
                    label: 'Manage Users',
                    color: Colors.yellow[100]!,
                    onTap: () => changePage(1),
                  ),
                  _buildMenuButton(
                    icon: Icons.store,
                    label: 'Manage Products',
                    color: Colors.blue[100]!,
                    onTap: () => changePage(3),
                  ),
                  _buildMenuButton(
                    icon: Icons.local_offer,
                    label: 'Manage Voucher',
                    color: Colors.pink[100]!,
                    onTap: () => changePage(2),
                  ),
                  _buildMenuButton(
                    icon: Icons.bar_chart,
                    label: 'Sales Report',
                    color: Colors.blue[100]!,
                    onTap: () => changePage(4),
                  ),
                ],
              ),
            ),
            // Weekly Summary
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Sales Completed', style: TextStyle(color: Colors.white)),
                      Text('23', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Profit Earned', style: TextStyle(color: Colors.white)),
                      Text('21', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Product In Stock', style: TextStyle(color: Colors.white)),
                      Text('02', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
            // Total User
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Average Purchase Per User', style: TextStyle(color: Colors.white)),
                      Text('23', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Average Profit Per User', style: TextStyle(color: Colors.white)),
                      Text('21', style: TextStyle(color: Colors.white, fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
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