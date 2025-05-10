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
    final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
    final updatedVoucher = widget.voucher.copyWith(
      description: _descriptionController.text,
      discount: double.tryParse(_discountController.text) ?? widget.voucher.discount,
      points: int.tryParse(_pointsController.text) ?? widget.voucher.points,
      total: int.tryParse(_totalController.text) ?? widget.voucher.total,
      expired_date: DateTime.tryParse(_expiredDateController.text) ?? widget.voucher.expired_date,
    );

    await voucherProvider.updateVoucher(updatedVoucher);
    setState(() {
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voucher updated')),
    );
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
      resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
      appBar: AppBar(
        title: Text('Voucher Details - ${widget.voucher.id}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView( // Make content scrollable
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
                      onPressed: _toggleEditMode,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Edit'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: const Text('Save'),
                    ),
                  if (!_isEditing)
                    ElevatedButton(
                      onPressed: () async {
                        final voucherProvider = Provider.of<VoucherProvider>(context, listen: false);
                        await voucherProvider.deleteVoucher(widget.voucher.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voucher deleted')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _cancelChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cancel'),
                    ),
                ],
              ),
              const SizedBox(height: 16), // Add extra space at the bottom to prevent cutoff
            ],
          ),
        ),
      ),
    );
  }
}