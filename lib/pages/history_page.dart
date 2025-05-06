import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/models/cart.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 在构建页面时加载交易数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
      transactionProvider.loadUserTransactions('user1'); // 使用小写的 user1
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[100],
        elevation: 0,
        title: const Text(
          'My Orders History',
          style: TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, transactionProvider, child) {
          if (transactionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactionProvider.error != null) {
            return Center(
              child: Text(
                '加载失败: ${transactionProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final transactions = transactionProvider.transactions;
          
          if (transactions.isEmpty) {
            return const Center(
              child: Text('no transactions records'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildOrderCard(context, transaction, index + 1);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildOrderCard(BuildContext context, Transaction transaction, int orderNumber) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#Order $orderNumber',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  transaction.createdAt.toString().substring(0, 16),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price:',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'RM ${transaction.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildDetailItem('Transaction ID:', transaction.id),
                            _buildDetailItem('Date:', transaction.createdAt.toString().substring(0, 16)),
                            _buildDetailItem('Status:', transaction.status.toString().split('.').last),
                            _buildDetailItem('Payment Method:', transaction.paymentMethod.toString().split('.').last),
                            _buildDetailItem('Shipping Address:', transaction.shippingAddress),
                            _buildDetailItem('Total Amount:', 'RM ${transaction.totalAmount.toStringAsFixed(2)}'),

                            const SizedBox(height: 16),
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            ...transaction.items.map((item) => _buildItemDetail(item)),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Order',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(CartItem item) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        return FutureBuilder<Product?>(
          future: productProvider.getProductById(item.product.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Text('Product not found');
            }

            final product = snapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Image.asset(
                    product.imageUrl,  // 这里已经正确获取了 imageUrl
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,  // 这里已经正确获取了 name
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Quantity: ${item.quantity} x RM ${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            _buildNavItem(context, Icons.home, 'Home', false),
            _buildNavItem(context, Icons.search, 'Search', false),
            _buildAddButton(),
            _buildNavItem(context, Icons.history, 'History', true),
            _buildNavItem(context, Icons.person, 'Profile', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        switch (label) {
          case 'Home':
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 'Search':
            // TODO: 实现搜索页面导航
            break;
          case 'History':
            Navigator.pushReplacementNamed(context, '/history');
            break;
          case 'Profile':
            Navigator.pushReplacementNamed(context, '/profile');
            break;
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
    );
  }

  Widget _buildAddButton() {
    return Container(
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
    );
  }
}