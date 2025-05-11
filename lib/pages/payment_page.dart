import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import '../localStorage/UserDataDatabaseHelper.dart';
import 'order_completed_page.dart';
import '../models/transaction.dart' as trans_model;
import '../providers/transaction_provider.dart';

class PaymentPage extends StatefulWidget {
  final String shippingAddress;
  final double finalAmount;
  const PaymentPage({
    super.key,
    required this.shippingAddress,
    required this.finalAmount
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPaymentMethod = 'CARD';
  final _formKey = GlobalKey<FormState>();
  
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardMonthController = TextEditingController();
  final _cardYearController = TextEditingController();
  final _cvvController = TextEditingController();
  final _dbHelper = UserDataDatabaseHelper();
  String _userID = '';

  @override
  void initState() {
    super.initState();
    _loadUserID();
  }

  Future<void> _loadUserID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final UID = currentUser.uid;
    final doc = await FirebaseFirestore.instance.collection('Users').doc(UID).get();
    
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _userID = data['userId'] ?? '';
      _loadBankDetails();
    }
  }

  List<Map<String, dynamic>> _bankAccounts = [];
  int _selectedCardIndex = 0;

  Future<void> _loadBankDetails() async {
    if (_userID.isEmpty) return;
    
    final accounts = await _dbHelper.getBankAccountsByUserID(_userID);
    setState(() {
      _bankAccounts = accounts;
      if (accounts.isNotEmpty) {
        _selectedCardIndex = 0;
        _updateCardFields(accounts[0]);
      }
    });
  }

  void _updateCardFields(Map<String, dynamic> account) {
    _cardNameController.text = account['cardHolder'] ?? '';
    _cardNumberController.text = account['cardNumber'] ?? '';
    
    // 处理过期日期
    final expiryDate = account['expiryDate'] ?? '';
    if (expiryDate.length >= 4) {
      _cardMonthController.text = expiryDate.substring(0, 2);
      _cardYearController.text = expiryDate.substring(3, 5);
    }
    
    _cvvController.text = account['cvv'] ?? '';
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardMonthController.dispose();
    _cardYearController.dispose();
    _cvvController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalPayment(),
                  const SizedBox(height: 16),
                  _buildPaymentMethodSelection(),
                  const SizedBox(height: 16),
                  if (_selectedPaymentMethod == 'CARD') _buildCardForm(),
                  const SizedBox(height: 24),
                  _buildConfirmButton(),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(),
        ],
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
              _buildProgressLine(true),
              _buildProgressStep(3, 'Payment', true),
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

  Widget _buildTotalPayment() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Payments:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Text(
                'RM${widget.finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedPaymentMethod,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'CARD',
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, color: Colors.blue[300]),
                        const SizedBox(width: 8),
                        const Text('Credit/Debit Card'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'COD',
                    child: Row(
                      children: [
                        Icon(Icons.money, color: Colors.green[300]),
                        const SizedBox(width: 8),
                        const Text('Cash on Delivery'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_bankAccounts.isNotEmpty) ...[
              const Text(
                'Select Card',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCardIndex,
                    isExpanded: true,
                    items: List.generate(_bankAccounts.length, (index) {
                      final account = _bankAccounts[index];
                      return DropdownMenuItem(
                        value: index,
                        child: Text(
                          '${account['cardHolder']} - ${account['cardNumber'].toString().substring(account['cardNumber'].toString().length - 4)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCardIndex = value;
                          _updateCardFields(_bankAccounts[value]);
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(
              controller: _cardNameController,
              label: 'Card Name',
              hint: 'Name on card',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cardNumberController,
              label: 'Card Digit (16 digits)',
              hint: 'XXXX XXXX XXXX XXXX',
              maxLength: 19,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cardMonthController,
                    label: 'Card Month',
                    hint: 'MM',
                    maxLength: 2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cardYearController,
                    label: 'Card Year',
                    hint: 'YY',
                    maxLength: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cvvController,
              label: 'CVV',
              hint: 'XXX',
              maxLength: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          maxLength: maxLength,
        ),
      ],
    );
  }

  void _showPaymentSuccess(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      'assets/images/success_leaf.png',
                      width: 80,
                      height: 80,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 关闭对话框
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderCompletedPage(
                          paymentMethod: _selectedPaymentMethod,
                          shippingAddress: widget.shippingAddress,
                          purchaseTime: DateTime.now(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[300],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Confirm',
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
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (_selectedPaymentMethod == 'CARD' && !_formKey.currentState!.validate()) {
                return;
              }

              // 创建交易记录
              final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
              final timestamp = DateTime.now();
              final transaction = trans_model.Transaction(
                id: 'T${timestamp.millisecondsSinceEpoch}',
                userId: _userID, // 使用已加载的用户ID
                items: cart.items.values.toList(),
                totalAmount: widget.finalAmount,
                status: trans_model.TransactionStatus.shipped,
                paymentMethod: _selectedPaymentMethod == 'CARD' 
                    ? trans_model.PaymentMethod.creditCard 
                    : trans_model.PaymentMethod.cashOnDelivery,
                shippingAddress: widget.shippingAddress,
                createdAt: DateTime.now(),
              );

              final transactionId = await transactionProvider.createTransaction(transaction);
              
              if (transactionId != null) {
                // 清空购物车
                await cart.clear();
                
                // 加载用户交易历史并打印
                await transactionProvider.loadUserTransactions(_userID); // 使用已加载的用户ID
                debugPrint('用户 ${_userID} 的所有交易:');
                for (var t in transactionProvider.transactions) {
                  debugPrint('交易ID: ${t.id}');
                  debugPrint('总金额: ${t.totalAmount}');
                  debugPrint('状态: ${t.status}');
                  debugPrint('创建时间: ${t.createdAt}');
                  debugPrint('-------------------');
                }

                // 在 PaymentPage 中的导航代码
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderCompletedPage(
                        paymentMethod: _selectedPaymentMethod,
                        shippingAddress: widget.shippingAddress,
                        purchaseTime: DateTime.now(),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
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
}