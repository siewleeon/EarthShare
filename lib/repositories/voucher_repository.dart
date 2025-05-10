import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';

class VoucherRepository {
  final CollectionReference _vouchersCollection = FirebaseFirestore.instance.collection('voucher');

  Future<List<Voucher>> getAllVoucher() async {
    try {
      debugPrint('start getting all voucher');
      debugPrint('path: ${_vouchersCollection.path}');

      final QuerySnapshot snapshot = await _vouchersCollection.get();
      debugPrint('numbers of doc: ${snapshot.docs.length}');

      final voucher = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        debugPrint('docs\'s ID: ${doc.id}');
        debugPrint('doc\'s data: $data');

        return Voucher.fromMap({...data, 'id': doc.id});
      }).toList();
      debugPrint('done transform: ${voucher.length}');
      return voucher;
    }
    catch (e, stackTrace) {
      debugPrint('get voucher failed: $e');
      debugPrint('error stack: $stackTrace');
      return [];
    }
  }

  Future<Voucher?> getVoucherById(String voucherID) async {
    try{
      final DocumentSnapshot doc = await _vouchersCollection.doc(voucherID).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return Voucher.fromMap({...data, 'id': doc.id});
    }
    catch (e) {
      debugPrint('failed to get voucher: $e');
      return null;
    }
  }

  Future<String?> addVoucher(Voucher voucher) async {
    try {
      final docRef = await _vouchersCollection.add(voucher.toMap());
      return docRef.id;
    }
    catch (e) {
      debugPrint('failed to add voucher: $e');
      return null;
    }
  }

  Future<bool> updateVoucher(Voucher voucher) async {
    try {
      await _vouchersCollection.doc(voucher.id).update(voucher.toMap());
      return true;
    }
    catch (e) {
      debugPrint('update voucher failed: $e');
      return false;
    }
  }

  Future<bool> deleteVoucher(String voucherId) async {
    try {
      await _vouchersCollection.doc(voucherId).delete();
      return true;
    } catch (e) {
      debugPrint('delete voucher failed: $e');
      return false;
    }
  }
}