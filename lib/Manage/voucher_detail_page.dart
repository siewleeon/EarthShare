import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/voucher.dart';
import '../providers/voucher_provider.dart';

class VoucherDetailPage extends StatefulWidget {
  final Voucher voucher;

  const VoucherDetailPage({super.key, required this.voucher});

  @override
  State<VoucherDetailPage> createState() => _VoucherDetailPageState();
}

class _VoucherDetailPageState extends State<VoucherDetailPage> {
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  late TextEditingController _pointsController;
  late TextEditingController _totalController;
  late TextEditingController _expiredDateController;

  bool _isEditing = false;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.voucher.description);
    _discountController = TextEditingController(text: widget.voucher.discount.toString());
    _pointsController = TextEditingController(text: widget.voucher.points.toString());
    _totalController = TextEditingController(text: widget.voucher.total.toString());
    _expiredDateController = TextEditingController(text: widget.voucher.expired_date.toString());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _discountController.dispose();
    _pointsController.dispose();
    _totalController.dispose();
    _expiredDateController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final updatedVoucher = widget.voucher.copyWith(
      description: _descriptionController.text,
      discount: double.tryParse(_discountController.text) ?? widget.voucher.discount,
      points: int.tryParse(_pointsController.text) ?? widget.voucher.points,
      total: int.tryParse(_totalController.text) ?? widget.voucher.total,
      expired_date: DateTime.tryParse(_expiredDateController.text) ?? widget.voucher.expired_date,
    );

    try {
      final success = await voucherProvider.updateVoucher(updatedVoucher);
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher updated')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update voucher')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _deleteVoucher() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
      final success = await voucherProvider.deleteVoucher(widget.voucher.id);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voucher deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete voucher')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  void _cancelChanges() {
    setState(() {
      _isEditing = false;
      _descriptionController.text = widget.voucher.description;
      _discountController.text = widget.voucher.discount.toString();
      _pointsController.text = widget.voucher.points.toString();
      _totalController.text = widget.voucher.total.toString();
      _expiredDateController.text = widget.voucher.expired_date.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Voucher Details - ${widget.voucher.id}'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${widget.voucher.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  )
                      : Text('Description: ${widget.voucher.description}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(labelText: 'Discount (%)'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Discount: ${widget.voucher.discount}%'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _pointsController,
                    decoration: const InputDecoration(labelText: 'Points'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Points: ${widget.voucher.points}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _totalController,
                    decoration: const InputDecoration(labelText: 'Total'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Total: ${widget.voucher.total}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _expiredDateController,
                    decoration: const InputDecoration(labelText: 'Expired Date'),
                  )
                      : Text('Expired Date: ${widget.voucher.expired_date.toString()}'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (!_isEditing)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _toggleEditMode,
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
                              : const Text('Edit'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
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
                              : const Text('Save'),
                        ),
                      if (!_isEditing)
                        ElevatedButton(
                          onPressed: _isLoading ? null : _deleteVoucher,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Delete'),
                        )
                      else
                        ElevatedButton(
                          onPressed: _isLoading ? null : _cancelChanges,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Cancel'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
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