import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<AdminProfile>
{
  // For ease of manage, page 0 is Home page, then is Manage User, Voucher, Products, Sales Report and last will be log out page
  void changePage(int page)
  {
    switch(page)
        {
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
          // Change page to Manage User
          break;
        }
      case 2:
        {
          debugPrint("voucher");
          // Change page to Manage Voucher
          Navigator.pushNamed(context, "/manageVoucherPage");
          break;
        }
      case 3:
        {
          debugPrint("product");
          // Change page to Manage Products
          break;
        }
      case 4:
        {
          debugPrint("report");
          // Change page to Sales Report
          break;
        }
      case 5:
        {
          debugPrint("logout");
          // Change page to Admin Login Page
          Navigator.pushNamedAndRemoveUntil(context, '/adminLogin', (Route<dynamic> route) => false);
          break;
        }
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Row(
              children: [
                // This button is log out
                ElevatedButton(
                  onPressed: () {changePage(5);},
                  child: const Text('Log Out'),
                ),
              ],
            ),
            Row(
              children: [
                // This button is Manage User
                ElevatedButton(
                  onPressed: () {changePage(1);},
                  child: const Text('Manage User'),
                ),
                // This button is Manage Voucher
                ElevatedButton(
                  onPressed: () {changePage(2);},
                  child: const Text('Manage Voucher'),
                ),
              ],
            ),
            Row(
              children: [
                // This button is Manage Products
                ElevatedButton(
                  onPressed: () {changePage(3);},
                  child: const Text('Manage Products'),
                ),
                // This button is Sales Report
                ElevatedButton(
                  onPressed: () {changePage(4);},
                  child: const Text('Sales Report'),
                ),
              ],
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar()
  {
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
            _buildNavItem(Icons.account_circle_outlined, "Manage User", false),
            _buildNavItem(Icons.abc, "Manage Voucher", false),
            _buildNavItem(Icons.home, 'Home', true),
            _buildNavItem(Icons.account_balance_outlined, "Manage Products", false),
            _buildNavItem(Icons.insert_chart_outlined, "Sales Report", false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected)
  {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          switch (label) {
            case 'Home':
              {
                changePage(0);
                break;
              }
            case 'Manage User':
              {
                changePage(1);
                break;
              }
            case 'Manage Voucher':
              {
                changePage(2);
                break;
              }
            case 'Manage Products':
              {
                changePage(3);
                break;
              }
            case 'Sales Report':
              {
                changePage(4);
                break;
              }
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
}