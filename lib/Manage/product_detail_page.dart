import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  late TextEditingController _sellerIdController;
  late TextEditingController _degreeOfNewnessController;
  late TextEditingController _uploadTimeController;
  late TextEditingController _editTimeController;

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _categoryController = TextEditingController(text: widget.product.productCategory);
    _sellerIdController = TextEditingController(text: widget.product.sellerId);
    _degreeOfNewnessController = TextEditingController(text: widget.product.degreeOfNewness.toString());
    _uploadTimeController = TextEditingController(text: widget.product.uploadTime.toString());
    _editTimeController = TextEditingController(text: widget.product.editTime.toString());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _sellerIdController.dispose();
    _degreeOfNewnessController.dispose();
    _uploadTimeController.dispose();
    _editTimeController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final updatedProduct = widget.product.copyWith(
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? widget.product.price,
      description: _descriptionController.text,
      quantity: int.tryParse(_quantityController.text) ?? widget.product.quantity,
      productCategory: _categoryController.text,
      sellerId: _sellerIdController.text,
      degreeOfNewness: int.tryParse(_degreeOfNewnessController.text) ?? widget.product.degreeOfNewness,
      uploadTime: DateTime.tryParse(_uploadTimeController.text) ?? widget.product.uploadTime,
      editTime: DateTime.now(),
    );

    try {
      final success = await productProvider.updateProduct(updatedProduct);
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _deleteProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(widget.product.id);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _cancelChanges() {
    setState(() {
      _isEditing = false;
      _nameController.text = widget.product.name;
      _priceController.text = widget.product.price.toString();
      _descriptionController.text = widget.product.description;
      _quantityController.text = widget.product.quantity.toString();
      _categoryController.text = widget.product.productCategory;
      _sellerIdController.text = widget.product.sellerId;
      _degreeOfNewnessController.text = widget.product.degreeOfNewness.toString();
      _uploadTimeController.text = widget.product.uploadTime.toString();
      _editTimeController.text = widget.product.editTime.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Product Details - ${widget.product.id}'),
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
                  Text('ID: ${widget.product.id}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  )
                      : Text('Name: ${widget.product.name}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _priceController,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Price: ${widget.product.price}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  )
                      : Text('Description: ${widget.product.description}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Quantity: ${widget.product.quantity}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  )
                      : Text('Category: ${widget.product.productCategory}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _sellerIdController,
                    decoration: const InputDecoration(labelText: 'Seller ID'),
                  )
                      : Text('Seller ID: ${widget.product.sellerId}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _degreeOfNewnessController,
                    decoration: const InputDecoration(labelText: 'Degree of Newness (1-4)'),
                    keyboardType: TextInputType.number,
                  )
                      : Text('Condition: ${widget.product.conditionLabel}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _uploadTimeController,
                    decoration: const InputDecoration(labelText: 'Upload Time'),
                  )
                      : Text('Upload Time: ${widget.product.uploadTime}'),
                  const SizedBox(height: 8),
                  _isEditing
                      ? TextField(
                    controller: _editTimeController,
                    decoration: const InputDecoration(labelText: 'Edit Time'),
                  )
                      : Text('Edit Time: ${widget.product.editTime}'),
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
                          onPressed: _isLoading ? null : _deleteProduct,
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
              color: Colors.white.withValues(alpha:0.7),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}