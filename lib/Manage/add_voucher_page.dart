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

  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _pointsController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiredDate ?? now,
      firstDate: now, // Restrict to today or later
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
        _isLoading = true; // Show loading indicator
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
            const SnackBar(content: Text('Voucher added successfully'))
          );
          Navigator.pop(context);
          // Refresh the parent page by notifying the provider to fetch updated data
          voucherProvider.fetchVoucher();
        }
        else {
          throw Exception('Voucher ID ${voucher.id} is already taken');
        }
      }
      catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
      finally {
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
                    TextFormField(
                      controller: _idController,
                      decoration: const InputDecoration(labelText: 'Voucher ID'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a voucher ID';
                        }
                        return null;
                      },
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
              color: Colors.white.withValues(alpha: 0.7), // Slightly white overlay
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}