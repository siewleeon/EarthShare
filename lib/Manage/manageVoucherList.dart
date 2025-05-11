import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/voucher_provider.dart';
import 'voucher_detail_page.dart';
import 'add_voucher_page.dart';

class ManageVoucherList extends StatefulWidget {
  const ManageVoucherList({super.key});

  @override
  State<ManageVoucherList> createState() => _ListPageState();
}

class _ListPageState extends State<ManageVoucherList> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showExpiredOnly = false; // Tracks whether to show only expired vouchers

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
        break;
      case 2:
        debugPrint("voucher");
        Navigator.pushReplacementNamed(context, "/manageVoucherPage");
        break;
      case 3:
        debugPrint("product");
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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VoucherProvider>(context, listen: false).fetchVoucher();
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSortButton(),
                const SizedBox(width: 8),
                _buildAddButton(),
                const SizedBox(width: 8),
                _buildExpiredButton(),
              ],
            ),
            Expanded(child: _buildVoucherList()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.grey),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by description',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Provider.of<VoucherProvider>(context, listen: false).toggleSortVouchersById();
        },
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.sort,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildExpiredButton() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          setState(() {
            _showExpiredOnly = !_showExpiredOnly; // Toggle expired filter
          });
        },
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _showExpiredOnly ? Colors.red[700] : Colors.red,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.history, // Icon to represent expired vouchers
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddVoucherPage(),
            ),
          );
        },
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildVoucherList() {
    return Consumer<VoucherProvider>(
      builder: (context, voucherProvider, child) {
        if (voucherProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (voucherProvider.error != null) {
          return Center(
            child: Text(
              'load failed ${voucherProvider.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Filter vouchers based on search query and expired status
        final now = DateTime.now();
        final vouchers = voucherProvider.vouchers.where((voucher) {
          final matchesSearch = voucher.description.toLowerCase().contains(_searchQuery);
          final isExpired = voucher.expired_date.isBefore(now);
          return matchesSearch && (!_showExpiredOnly || isExpired);
        }).toList();

        if (vouchers.isEmpty) {
          return Center(
            child: Text(_showExpiredOnly ? "No expired vouchers found" : "No vouchers found"),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Text(
                  voucher.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                title: Text(
                  voucher.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VoucherDetailPage(voucher: voucher),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  child: const Text('Detail', style: TextStyle(color: Colors.white)),
                ),
              ),
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
            _buildNavItem(Icons.local_offer, "Voucher", true),
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