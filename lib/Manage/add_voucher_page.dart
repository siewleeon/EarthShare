import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';

class AddVoucherPage extends StatefulWidget {
  const AddVoucherPage({super.key});

  @override
  State<AddVoucherPage> createState() => _AddVoucherPageState();
}

class _AddVoucherPageState extends State<AddVoucherPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _pointsController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime? _expiredDate;
  bool _isAutoGenerateId = true;
  bool _isLoading = false;
  bool _canAutoGenerate = true;
  String? _autoGenerateError;
  bool _useSmallestId = false; // False: use largest ID, True: use smallest ID

  @override
  void initState() {
    super.initState();
    _checkAutoGeneratePossibility();
    if (_isAutoGenerateId && _canAutoGenerate) {
      _generateVoucherId();
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _pointsController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoGeneratePossibility() async {
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final nextId = await (_useSmallestId
        ? voucherProvider.generateSmallestNonTakenVoucherId()
        : voucherProvider.generateNextVoucherId());
    final numberPart = nextId.substring(1);
    final number = int.tryParse(numberPart) ?? 0;
    setState(() {
      if (number > 9999) {
        _canAutoGenerate = false;
        _autoGenerateError = 'Max ID (V9999) reached';
        if (_isAutoGenerateId) {
          _isAutoGenerateId = false;
          _idController.clear();
        }
      } else {
        _canAutoGenerate = true;
        _autoGenerateError = null;
      }
    });
  }

  Future<void> _generateVoucherId() async {
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final newId = await (_useSmallestId
        ? voucherProvider.generateSmallestNonTakenVoucherId()
        : voucherProvider.generateNextVoucherId());
    setState(() {
      _idController.text = newId;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiredDate ?? now,
      firstDate: now,
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiredDate) {
      setState(() {
        _expiredDate = picked;
      });
    }
  }

  void _addVoucher() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final voucher = Voucher(
        id: _idController.text,
        description: _descriptionController.text,
        discount: double.parse(_discountController.text),
        points: int.parse(_pointsController.text),
        total: int.parse(_totalController.text),
        expired_date: _expiredDate ?? DateTime.now(),
      );

      final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
      try {
        final success = await voucherProvider.addVoucher(voucher);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voucher added successfully')),
          );
          Navigator.pop(context);
          voucherProvider.fetchVoucher();
        } else {
          throw Exception('Voucher ID ${voucher.id} is already taken');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Add New Voucher'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _idController,
                            decoration: const InputDecoration(
                              labelText: 'Voucher ID (e.g., V0001)',
                            ),
                            enabled: !_isAutoGenerateId,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a voucher ID';
                              }
                              if (_isAutoGenerateId) return null;
                              if (!value.startsWith('V') || value.length != 5) {
                                return 'Voucher ID must start with "V" followed by 4 digits (e.g., V0001)';
                              }
                              final numberPart = value.substring(1);
                              final number = int.tryParse(numberPart);
                              if (number == null || number <= 0) {
                                return 'The number part must be a positive integer';
                              }
                              if (numberPart.length != 4) {
                                return 'The number part must be exactly 4 digits';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Text('Auto ID'),
                                Switch(
                                  value: _isAutoGenerateId,
                                  onChanged: _canAutoGenerate
                                      ? (value) {
                                    setState(() {
                                      _isAutoGenerateId = value;
                                      if (value) {
                                        _generateVoucherId();
                                      } else {
                                        _idController.clear();
                                      }
                                    });
                                  }
                                      : null,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(_useSmallestId ? 'Use Largest ID' : 'Use Smallest ID'),
                                Switch(
                                  value: _useSmallestId,
                                  onChanged: _isAutoGenerateId && _canAutoGenerate
                                      ? (value) {
                                    setState(() {
                                      _useSmallestId = value;
                                      _checkAutoGeneratePossibility();
                                      if (_isAutoGenerateId) {
                                        _generateVoucherId();
                                      }
                                    });
                                  }
                                      : null,
                                ),
                              ],
                            ),
                            if (_autoGenerateError != null)
                              Container(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  _autoGenerateError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.end,
                                  softWrap: true,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Discount (%)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a discount';
                        }
                        final discount = double.tryParse(value);
                        if (discount == null || discount <= 0 || discount > 1) {
                          return 'Discount must be between 0 and 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(labelText: 'Points'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points';
                        }
                        final points = int.tryParse(value);
                        if (points == null || points <= 0) {
                          return 'Points must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _totalController,
                      decoration: const InputDecoration(labelText: 'Total'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter total';
                        }
                        final total = int.tryParse(value);
                        if (total == null || total <= 0) {
                          return 'Total must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _expiredDate == null
                                ? 'Select Expired Date'
                                : 'Expired Date: ${_expiredDate!.toString().split(' ')[0]}',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    if (_expiredDate == null)
                      const Text(
                        'Please select an expired date',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addVoucher,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Add Voucher'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}