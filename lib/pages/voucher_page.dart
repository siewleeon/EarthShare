import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoucherModel {
  final String id;
  final String description;
  final double discount;
  final DateTime expiredDate;
  final int point;
  final int total;
  final String voucherId;

  VoucherModel({
    required this.id,
    required this.description,
    required this.discount,
    required this.expiredDate,
    required this.point,
    required this.total,
    required this.voucherId,
  });

  factory VoucherModel.fromMap(Map<String, dynamic> map, String id) {
    return VoucherModel(
      id: id,
      description: map['description'] ?? '',
      discount: (map['discount'] ?? 0.0).toDouble(),
      expiredDate: (map['expired_date'] as Timestamp).toDate(),
      point: map['point'] ?? 0,
      total: map['total'] ?? 0,
      voucherId: map['voucher_ID'] ?? '',
    );
  }
}

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  String userId = '';

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(currentUser.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userId = doc.data()?['userId'] ?? '';
      });
    }
  }

  Widget _buildVoucherCard(VoucherModel voucher) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 根据折扣值选择不同的图片
                Image.asset(
                  _getVoucherImage(voucher.discount),
                  height: 60,
                  width: 60,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.voucherId,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        voucher.description,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Expired until: ${voucher.expiredDate.toString().split(' ')[0]}',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Points required: ${voucher.point}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Available: ${voucher.total}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vouchers'),
        backgroundColor: const Color(0xFFCCFF66),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Voucher')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vouchers = snapshot.data?.docs
              .map((doc) => VoucherModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList() ??
              [];

          if (vouchers.isEmpty) {
            return const Center(child: Text('No vouchers available'));
          }

          return ListView.builder(
            itemCount: vouchers.length,
            itemBuilder: (context, index) => _buildVoucherCard(vouchers[index]),
          );
        },
      ),
    );
  }
}

  String _getVoucherImage(double discount) {
    if (discount == 0.05) {
      return 'assets/images/5_percent.png';
    } else if (discount == 0.10) {
      return 'assets/images/10_percent.png';
    } else if (discount == 0.15) {
      return 'assets/images/15_percent.png';
    }
    return 'assets/images/5_percent.png'; // 默认图片
  }