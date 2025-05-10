import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../localStorage/UserDataDatabaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Accounts'),
        backgroundColor: Colors.green,
      ),
      body: _bankAccounts.isEmpty
          ? const Center(
              child: Text('No bank accounts added yet'),
            )
          : ListView.builder(
              itemCount: _bankAccounts.length,
              itemBuilder: (context, index) {
                return _buildCardTile(_bankAccounts[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCardDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
    );
  }
  final dbHelper = UserDataDatabaseHelper();
  List<Map<String, dynamic>> _bankAccounts = [];
  String userID = '';
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _loadUserID();
    await _loadAccounts();
  }

  Future<void> _loadUserID() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final UID = currentUser.uid;

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('Users').doc(UID).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      setState(() {
        userID = data['userId'] ?? '';
      });
    } else {
      print("User data not found in Firestore");
    }
  }

  Future<void> _loadAccounts() async {
    final accounts = await dbHelper.getBankAccountsByUserID(userID);
    setState(() {
      _bankAccounts = accounts;
    });
  }

  void _submitForm() async {
    try {
      if (_formKey.currentState!.validate()) {
        final data = {
          'userID': userID,
          'bankName': _bankNameController.text.trim(),
          'cardNumber': _cardNumberController.text.trim(),
          'cardHolder': _cardHolderController.text.trim(),
          'expiryDate': _expiryDateController.text.trim(),
          'cvv': _cvvController.text.trim(),
        };

        // Insert the new bank account into the database
        final result = await dbHelper.insertBankAccount(data);

        if (result != -1) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank account successfully bound!')),
          );

          // Reload the list of bank accounts to update the UI
          _loadAccounts();

          // Close the dialog
          Navigator.pop(context);
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to bind bank account.')),
          );
        }
      }
    } catch (e, stack) {
      print('Error during form submission: $e');
      print('Stack trace: $stack');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to bind bank account. Please try again.')),
      );
    }
  }

  void _showAddCardDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Bank Account'),
        content: SizedBox(
          width: 300,
          height: 350,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter bank name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(labelText: 'Card Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.length < 16 ? 'Enter a valid card number' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cardHolderController,
                  decoration: const InputDecoration(labelText: 'Card Holder', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Enter cardholder name' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)', border: OutlineInputBorder()),
                  validator: (value) => value == null || !RegExp(r'^\d{2}/\d{2}$').hasMatch(value)
                      ? 'Enter expiry date like 12/25'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  obscureText: true, // 安全考虑，隐藏 CVV
                  maxLength: 4, // 大多数卡的 CVV 是 3-4 位
                  validator: (value) => value == null || value.length < 3 ? 'Enter a valid CVV' : null,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Bind bank'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bank Account'),
        content: const Text('Are you sure you want to delete this bank account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await dbHelper.deleteBankAccount(id);
              Navigator.pop(context);
              _loadAccounts(); // Reload the list
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _obscureCard(String cardNumber) {
    if (cardNumber.length < 4) return '****';
    return '*${cardNumber.substring(cardNumber.length - 4)}';
  }

  Widget _buildCardTile(Map<String, dynamic> account) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account['bankName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(_obscureCard(account['cardNumber']), style: const TextStyle(fontSize: 12)),
                // 不显示 CVV，出于安全考虑
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _confirmDelete(account['id']),
          ),
        ],
      ),
    );
  }
}