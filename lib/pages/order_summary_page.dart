import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import 'payment_page.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  bool _expressShipping = false;
  final _addressController = TextEditingController();
  List<String> _savedAddresses = [];  // 用于存储历史地址

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();  // 加载保存的地址
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // 加载保存的地址
  Future<void> _loadSavedAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedAddresses = prefs.getStringList('saved_addresses') ?? [];
    });
  }

  // 保存新地址
  Future<void> _saveAddress(String address) async {
    if (address.isNotEmpty && !_savedAddresses.contains(address)) {
      final prefs = await SharedPreferences.getInstance();
      final updatedAddresses = [..._savedAddresses, address];
      await prefs.setStringList('saved_addresses', updatedAddresses);
      setState(() {
        _savedAddresses = updatedAddresses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[100],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'EarthShare',
          style: TextStyle(
            color: Colors.green,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.green),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          return Column(
            children: [
              _buildProgressIndicator(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCartItems(cart),
                      const SizedBox(height: 16),
                      _buildShippingAddress(),
                      const SizedBox(height: 16),
                      _buildExpressShipping(),
                      const SizedBox(height: 16),
                      _buildPaymentDetails(cart),
                    ],
                  ),
                ),
              ),
              _buildBottomNavBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              _buildProgressStep(1, 'Review\nCart', true),
              _buildProgressLine(true),
              _buildProgressStep(2, 'Order\nSummary', true),
              _buildProgressLine(false),
              _buildProgressStep(3, 'Payment', false),
              _buildProgressLine(false),
              _buildProgressStep(4, 'Order\nCompleted', false),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int number, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey[600],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 1,
      width: 20,
      margin: const EdgeInsets.only(bottom: 20),
      color: isActive ? Colors.blue : Colors.grey[300],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, 'Home', true),
              _buildNavItem(Icons.search, 'Search', false),
              _buildCenterNavItem(),
              _buildNavItem(Icons.history, 'History', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.green : Colors.grey,
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCenterNavItem() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  Widget _buildCartItems(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cart.items.values.map((item) => _buildCartItem(item)).toList(),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'per unit',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'QTY:${item.quantity}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'RM${item.product.price}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your Shipping Address',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_savedAddresses.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                fillColor: Colors.grey[100],
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              hint: const Text('Select saved address'),
              items: _savedAddresses.map((address) {
                return DropdownMenuItem(
                  value: address,
                  child: Text(address),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _addressController.text = value;
                }
              },
            ),
            const SizedBox(height: 8),
          ],
          TextField(
            controller: _addressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Shipping Address',
              fillColor: Colors.grey[100],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 在 proceed payment 按钮点击时调用此方法
  Future<void> _saveCurrentAddress() async {
    final address = _addressController.text.trim();
    if (address.isNotEmpty && !_savedAddresses.contains(address)) {
      final prefs = await SharedPreferences.getInstance();
      final updatedAddresses = [..._savedAddresses, address];
      await prefs.setStringList('saved_addresses', updatedAddresses);
      setState(() {
        _savedAddresses = updatedAddresses;
      });
    }
  }

  Widget _buildExpressShipping() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Express Ship (Optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: _expressShipping,
            onChanged: (value) {
              setState(() {
                _expressShipping = value;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(CartProvider cart) {
    final productTotal = cart.totalAmount;
    final expressShipFee = _expressShipping ? 10.0 : 0.0;
    final shippingFee = 10.0;
    final memberDiscount = productTotal * 0.1; // 10% discount
    final salesTax = productTotal * 0.06; // 6% tax
    final totalPayment = productTotal + expressShipFee + shippingFee - memberDiscount + salesTax;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentRow('Product Total Price', productTotal),
          _buildPaymentRow('Express Ship Fee', expressShipFee),
          _buildPaymentRow('Shipping Fee', shippingFee),
          _buildPaymentRow('Member Discount (10%)', memberDiscount, isDiscount: true),
          _buildPaymentRow('Sales Tax (6%)', salesTax, isTax: true),
          const SizedBox(height: 8),
          _buildVoucherInput(),
          const SizedBox(height: 16),
          _buildPaymentRow('Total Payment', totalPayment, isTotal: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 保存当前地址
                _saveCurrentAddress();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      shippingAddress: _addressController.text,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Proceed Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount, {
    bool isDiscount = false,
    bool isTax = false,
    bool isTotal = false,
  }) {
    final formattedAmount = isDiscount
        ? '-RM ${amount.toStringAsFixed(2)}'
        : 'RM ${amount.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.black : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              color: isDiscount
                  ? Colors.green
                  : isTax
                      ? Colors.red
                      : isTotal
                          ? Colors.black
                          : Colors.grey[600],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Enter voucher code',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现验证优惠券逻辑
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text(
              'Apply',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}