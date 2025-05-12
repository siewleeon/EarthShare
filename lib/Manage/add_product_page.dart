import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/product_provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  final _categoryController = TextEditingController();
  final _sellerIdController = TextEditingController();
  final _degreeOfNewnessController = TextEditingController();
  List<String> _imageIds = [];
  DateTime _uploadTime = DateTime.now();
  DateTime _editTime = DateTime.now();
  bool _isAutoGenerateId = true;
  bool _isLoading = false;
  bool _canAutoGenerate = true;
  String? _autoGenerateError;
  bool _useSmallestId = false;

  @override
  void initState() {
    super.initState();
    _checkAutoGeneratePossibility();
    if (_isAutoGenerateId && _canAutoGenerate) {
      _generateProductId();
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _sellerIdController.dispose();
    _degreeOfNewnessController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoGeneratePossibility() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final nextId = await (_useSmallestId
        ? productProvider.generateSmallestNonTakenProductId()
        : productProvider.generateNextProductId());
    final numberPart = nextId.substring(1);
    final number = int.tryParse(numberPart) ?? 0;
    setState(() {
      if (number > 9999) {
        _canAutoGenerate = false;
        _autoGenerateError = 'Max ID (P9999) reached';
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

  Future<void> _generateProductId() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final newId = await (_useSmallestId
        ? productProvider.generateSmallestNonTakenProductId()
        : productProvider.generateNextProductId());
    setState(() {
      _idController.text = newId;
    });
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final product = Product(
        id: _idController.text,
        name: _nameController.text,
        price: double.parse(_priceController.text),
        description: _descriptionController.text,
        quantity: int.parse(_quantityController.text),
        productCategory: _categoryController.text,
        sellerId: _sellerIdController.text,
        imageId: _imageIds,
        uploadTime: _uploadTime,
        editTime: _editTime,
        degreeOfNewness: int.parse(_degreeOfNewnessController.text),
      );

      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      try {
        final success = await productProvider.addProduct(product);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product added successfully')),
          );
          Navigator.pop(context);
          productProvider.fetchProducts();
        } else {
          throw Exception('Product ID ${product.id} is already taken');
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
        title: const Text('Add New Product'),
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
                              labelText: 'Product ID (e.g., P0001)',
                            ),
                            enabled: !_isAutoGenerateId,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a product ID';
                              }
                              if (_isAutoGenerateId) return null;
                              if (!value.startsWith('P') || value.length != 5) {
                                return 'Product ID must start with "P" followed by 4 digits (e.g., P0001)';
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
                                        _generateProductId();
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
                                        _generateProductId();
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
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Price must be a positive number';
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
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a quantity';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null || quantity < 0) {
                          return 'Quantity must be a non-negative number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sellerIdController,
                      decoration: const InputDecoration(labelText: 'Seller ID'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a seller ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _degreeOfNewnessController,
                      decoration: const InputDecoration(labelText: 'Degree of Newness (1-4)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter degree of newness';
                        }
                        final degree = int.tryParse(value);
                        if (degree == null || degree < 1 || degree > 4) {
                          return 'Degree must be between 1 and 4';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addProduct,
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
                            : const Text('Add Product'),
                      ),
                    ),
                  ],
                ),
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