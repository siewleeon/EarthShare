import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/point_provider.dart';
import '../models/point.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';

class OrderCompletedPage extends StatelessWidget {
  final String paymentMethod;
  final String shippingAddress;
  final DateTime purchaseTime;
  
  const OrderCompletedPage({
    super.key,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.purchaseTime,
  });

  @override
  Widget build(BuildContext context) {
    // 在页面构建时加载交易历史
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final UID = currentUser.uid;
      final doc = await firestore.FirebaseFirestore.instance
          .collection('Users')
          .doc(UID)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'] ?? '';
        
        final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
        transactionProvider.loadUserTransactions(userId);
      }
    });
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
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPaymentDetails(),
                  const SizedBox(height: 24),
                  _buildDoneButton(context),
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
              _buildProgressLine(true),
              _buildProgressStep(4, 'Order\nCompleted', true),
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

  Widget _buildPaymentDetails() {
    return Consumer<TransactionProvider>(
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
        
        // 打印调试信息
        debugPrint('交易列表长度: ${transactionProvider.transactions.length}');
        debugPrint('交易列表内容: ${transactionProvider.transactions}');
        
        final transactions = transactionProvider.transactions;
        final latestTransaction = transactions.isNotEmpty ? transactions.first : null;
        
        // 使用传入的总金额作为备选
        final totalAmount = latestTransaction?.totalAmount ?? 0.00;
        debugPrint('显示的总金额: $totalAmount');
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Payment Detail',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Transaction number:', latestTransaction?.id ?? '-'),
              _buildDetailRow('Payment Method:', paymentMethod),
              _buildDetailRow(
                'Total Payment:',
                'RM ${totalAmount.toStringAsFixed(2)}',
                valueColor: Colors.green,
              ),
              _buildDetailRow('Shipping Address:', shippingAddress),
              _buildDetailRow('Time Purchase:', purchaseTime.toString().substring(0, 16)),
              _buildDetailRow('Estimate Date Receive:', '3-5 working days'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // 显示积分奖励对话框
          _showPointRewardDialog(context);
          
          // 打印最新的交易历史
          // Import the TransactionProvider first at the top of the file
          final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
          debugPrint('最新交易历史:');
          for (var transaction in transactionProvider.transactions) {
            debugPrint('交易ID: ${transaction.id}');
            debugPrint('总金额: ${transaction.totalAmount}');
            debugPrint('状态: ${transaction.status}');
            debugPrint('创建时间: ${transaction.createdAt}');
            debugPrint('-------------------');
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Done',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showPointRewardDialog(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final UID = currentUser.uid;
    final doc = await firestore.FirebaseFirestore.instance
        .collection('Users')
        .doc(UID)
        .get();

    if (!doc.exists) return;

    final data = doc.data() as Map<String, dynamic>;
    final userId = data['userId'] ?? '';

    // 获取最新的积分记录
    final pointsQuery = await firestore.FirebaseFirestore.instance
        .collection('points')
        .where('user_ID', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    // 获取交易金额
    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final transactions = transactionProvider.transactions;
    final pointsEarned = transactions.isNotEmpty ? (transactions.first.totalAmount * 10).round() : 0;
    
    // 检查最新积分记录的 is_increase
    final displayPoints = pointsQuery.docs.isNotEmpty && 
                        pointsQuery.docs.first.data()['is_increase'] == true ? 
                        pointsEarned : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/point_leaf.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Congrats u got a reward!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '+$displayPoints points',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Thank you for purchasing!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text(
              'done',
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      width: double.infinity,  // 添加这行确保宽度填充
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16), // 减小水平内边距
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // 改为 spaceEvenly
            children: [
              Flexible(child: _buildNavItem(Icons.home_outlined, 'Home', true)),
              Flexible(child: _buildNavItem(Icons.search, 'Search', false)),
              Flexible(child: _buildCenterNavItem()),
              Flexible(child: _buildNavItem(Icons.history, 'History', false)),
              Flexible(child: _buildNavItem(Icons.person_outline, 'Profile', false)),
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