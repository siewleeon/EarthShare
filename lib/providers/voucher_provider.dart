import 'package:flutter/foundation.dart';
import '../models/voucher.dart';
import '../repositories/voucher_repository.dart';

class VoucherProvider extends ChangeNotifier {
  final VoucherRepository _voucherRepository = VoucherRepository();
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String? _error;

  List<Voucher> get vouchers => [..._vouchers];

  bool get isLoading => _isLoading;

  String? get error => _error;

  Future<void> fetchVoucher() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final voucher = await _voucherRepository.getAllVoucher();
      _vouchers = voucher;
      debugPrint(voucher.toString());
    }
    catch (e) {
      _error = 'failed to load: $e';
      debugPrint(_error);
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Voucher?> getVoucherById(String voucherID) async {
    try {
      return await _voucherRepository.getVoucherById(voucherID);
    }
    catch (e) {
      debugPrint('failed to get voucher: $e');
      return null;
    }
  }

  Future<bool> addVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if voucher_ID is already taken
      if (_vouchers.any((v) => v.id == voucher.id)) {
        throw Exception('Voucher ID ${voucher.id} is already taken');
      }

      final voucherID = await _voucherRepository.addVoucher(voucher);
      if (voucherID != null) {
        final newVoucher = voucher.copyWith(id: voucherID);
        _vouchers.add(newVoucher);
        notifyListeners();
        return true;
      }
      return false;
    }
    catch (e) {
      debugPrint('failed to add voucher: $e');
      return false;
    }
    finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateVoucher(Voucher voucher) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _voucherRepository.updateVoucher(voucher);
      if (success) {
        final index = _vouchers.indexWhere((v) => v.id == voucher.id);
        if (index >= 0) {
          _vouchers[index] = voucher;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('failed to update voucher: $e');
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
      final success = await _voucherRepository.deleteVoucher(voucherID);
      if (success) {
        _vouchers.removeWhere((v) => v.id == voucherID);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('failed to delete voucher: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}