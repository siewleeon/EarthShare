import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';

class ManageVoucherList extends StatefulWidget {
  const ManageVoucherList({super.key});

  @override
  State<ManageVoucherList> createState() => _ListPageState();
}

class _ListPageState extends State<ManageVoucherList>
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
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoucherProvider>(context, listen: false).fetchVoucher();
    });

    return Scaffold(
      body: SafeArea(child: Row(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              _buildAddButton(),
            ],
          ),
          Expanded(child: _buildVoucherGrid()),
          _buildBottomNavigationBar(),
        ],
      )),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search products',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.public, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            // todo add a voucher function
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
            ),
          ),
        )
    );
  }

  Widget _buildVoucherGrid() {
    return Consumer<VoucherProvider>(
      builder: (context, voucherProvider, child) {
        if (voucherProvider.isLoading) {
          return const Center(child:  CircularProgressIndicator(),);
        }

        if (voucherProvider.error != null) {
          return Center(
            child: Text(
              'load failed ${voucherProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final vouchers = voucherProvider.vouchers;
        debugPrint('voucher.length = ${vouchers.length}');

        if (vouchers.isEmpty) {
          return const Center(child: Text("no voucher found"));
        }

        return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: vouchers.length,
            itemBuilder: (context, index){
              final voucher = vouchers[index];
              return GestureDetector(
                onTap: () {

                },
                child: ListBody(
                  children: [
                    Column(
                      children: [
                        Text(
                          voucher.id,
                          maxLines: 2,
                        ),
                        Text(
                          voucher.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            });
      },
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