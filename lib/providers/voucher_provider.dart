import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/voucher.dart';
import '../repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherRepository _voucherRepository = VoucherRepository();
  List<Voucher> _vouchers = [];
  Map<String, String> _voucherIdToDocId = {};
  bool _isLoading = false;
  String? _error;
  bool _isDescending = true;

  List<Voucher> get vouchers => [..._vouchers];
  bool get isLoading => _isLoading;
  String? get error => _error;

  final CollectionReference _vouchersCollection = FirebaseFirestore.instance.collection('Voucher');

  Future<void> fetchVoucher() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final snapshot = await _vouchersCollection.get();
      _vouchers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final voucher = Voucher.fromMap(data);
        _voucherIdToDocId[voucher.id] = doc.id;
        return voucher;
      }).toList();
      debugPrint('Vouchers fetched: ${_vouchers.length}');
    } catch (e) {
      _error = 'Failed to load: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> generateNextVoucherId() async {
    try {
      if (_vouchers.isEmpty) {
        await fetchVoucher();
      }

      int maxNumber = 0;
      for (var voucher in _vouchers) {
        final id = voucher.id;
        if (id.startsWith('V') && id.length == 5) {
          final numberPart = id.substring(1);
          final number = int.tryParse(numberPart);
          if (number != null && number > maxNumber) {
            maxNumber = number;
          }
        }
      }

      final nextNumber = maxNumber + 1;
      return 'V${nextNumber.toString().padLeft(4, '0')}';
    } catch (e) {
      debugPrint('Failed to generate voucher ID: $e');
      return 'V0001';
    }
  }

  Future<String> generateSmallestNonTakenVoucherId() async {
    try {
      if (_vouchers.isEmpty) {
        await fetchVoucher();
      }

      // Collect all used numbers
      final usedNumbers = _vouchers
          .map((voucher) {
        final id = voucher.id;
        if (id.startsWith('V') && id.length == 5) {
          return int.tryParse(id.substring(1));
        }
        return null;
      })
          .where((number) => number != null)
          .cast<int>()
          .toSet();

      // Find the smallest non-taken number from 1 to 9999
      for (int i = 1; i <= 9999; i++) {
        if (!usedNumbers.contains(i)) {
          return 'V${i.toString().padLeft(4, '0')}';
        }
      }

      // If all numbers up to 9999 are taken, return V0001 as fallback
      return 'V0001';
    } catch (e) {
      debugPrint('Failed to generate smallest non-taken voucher ID: $e');
      return 'V0001';
    }
  }

  void toggleSortVouchersById() {
    _isDescending = !_isDescending;
    _vouchers.sort((a, b) {
      final aNumber = int.parse(a.id.substring(1));
      final bNumber = int.parse(b.id.substring(1));
      return _isDescending ? bNumber.compareTo(aNumber) : aNumber.compareTo(bNumber);
    });
    notifyListeners();
  }

  Future<Voucher?> getVoucherById(String voucherID) async {
    try {
      return await _voucherRepository.getVoucherById(voucherID);
    } catch (e) {
      debugPrint('Failed to get voucher: $e');
      return null;
    }
  }

  Future<bool> addVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_vouchers.any((v) => v.id == voucher.id)) {
        throw Exception('Voucher ID ${voucher.id} is already taken');
      }

      final docRef = await _vouchersCollection.add(voucher.toMap());
      final newVoucher = voucher.copyWith(id: voucher.id);
      _vouchers.add(newVoucher);
      _voucherIdToDocId[voucher.id] = docRef.id;
      debugPrint('Added voucher with doc ID: ${docRef.id}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to add voucher: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docId = _voucherIdToDocId[voucher.id];
      if (docId == null) {
        throw Exception('Document ID not found for voucher ${voucher.id}');
      }
      await _vouchersCollection.doc(docId).update(voucher.toMap());
      final index = _vouchers.indexWhere((v) => v.id == voucher.id);
      if (index >= 0) {
        _vouchers[index] = voucher;
        notifyListeners();
      }
      debugPrint('Updated voucher with doc ID: $docId');
      return true;
    } catch (e) {
      debugPrint('Failed to update voucher: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVoucher(String voucherID) async {
    _isLoading = true;
    notifyListeners();

    try {
      final docId = _voucherIdToDocId[voucherID];
      if (docId == null) {
        throw Exception('Document ID not found for voucher $voucherID');
      }
      await _vouchersCollection.doc(docId).delete();
      _vouchers.removeWhere((v) => v.id == voucherID);
      _voucherIdToDocId.remove(voucherID);
      debugPrint('Deleted voucher with doc ID: $docId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete voucher: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}