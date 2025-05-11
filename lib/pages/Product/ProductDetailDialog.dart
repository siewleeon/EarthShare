import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';

class ProductEditDialog extends StatefulWidget {
  final Product product;

  const ProductEditDialog({super.key, required this.product});

  @override
  State<ProductEditDialog> createState() => _ProductEditDialogState();
}

class _ProductEditDialogState extends State<ProductEditDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  late TextEditingController descriptionController;
  late String productCategory;
  late int degreeOfNewness;
  late List<String> imageUrls;
  List<File> newImageFiles = [];
  bool _isEditing = false;

  final picker = ImagePicker();
  final List<String> categories = [
    'Electronics',
    'Clothing',
    'Books',
    'Home & Kitchen',
    'Toys',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    quantityController = TextEditingController(text: widget.product.quantity.toString());
    descriptionController = TextEditingController(text: widget.product.description);
    productCategory = widget.product.productCategory;
    degreeOfNewness = widget.product.degreeOfNewness;
    imageUrls = List.from(widget.product.imageId);
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        newImageFiles.add(File(picked.path));
      });
    }
  }

  Future<String> uploadImage(File imageFile) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('product_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Failed to delete image from storage: $e');
    }
    setState(() {
      imageUrls.remove(imageUrl);
    });
  }

  void _toggleEditMode() {
    print('Toggling edit mode: current _isEditing = $_isEditing');
    setState(() {
      _isEditing = !_isEditing;
    });
    print('After toggle: _isEditing = $_isEditing');
  }

  void _cancelChanges() {
    print('Canceling changes');
    setState(() {
      _isEditing = false;
      nameController.text = widget.product.name;
      priceController.text = widget.product.price.toString();
      quantityController.text = widget.product.quantity.toString();
      descriptionController.text = widget.product.description;
      productCategory = widget.product.productCategory;
      degreeOfNewness = widget.product.degreeOfNewness;
      imageUrls = List.from(widget.product.imageId);
      newImageFiles.clear();
    });
  }

  String? _validateInputs() {
    if (nameController.text.isEmpty) return 'Product name cannot be empty';
    if (priceController.text.isEmpty || double.tryParse(priceController.text) == null) {
      return 'Invalid price';
    }
    if (quantityController.text.isEmpty || int.tryParse(quantityController.text) == null) {
      return 'Invalid quantity';
    }
    if (productCategory.isEmpty) return 'Please select a category';
    return null;
  }

  void _saveChanges() async {
    print('Starting save changes for product ID: ${widget.product.id}');
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final validationError = _validateInputs();
    if (validationError != null) {
      print('Validation error: $validationError');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    List<String> finalImageUrls = List.from(imageUrls);
    try {
      print('Uploading ${newImageFiles.length} new images');
      for (var imageFile in newImageFiles) {
        final newImageUrl = await uploadImage(imageFile);
        finalImageUrls.add(newImageUrl);
      }

      final updatedProduct = widget.product.copyWith(
        id: widget.product.id, // Always use original ID
        name: nameController.text,
        price: double.parse(priceController.text),
        quantity: int.parse(quantityController.text),
        productCategory: productCategory,
        imageId: finalImageUrls,
        description: descriptionController.text,
        degreeOfNewness: degreeOfNewness,
        editTime: DateTime.now(),
      );

      print('Updated product data: ${updatedProduct.toMap()}');
      final success = await productProvider.updateProduct(updatedProduct);
      print('Update result: $success');
      if (success) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated')),
        );
        Navigator.pop(context);
        await productProvider.fetchProducts();
      } else {
        print('Update failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update product')),
        );
      }
    } catch (e) {
      print('Error in saveChanges: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _deleteProduct() async {
    print('Deleting product ID: ${widget.product.id}');
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    try {
      final success = await productProvider.deleteProduct(widget.product.id);
      print('Delete result: $success');
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
        Navigator.pop(context);
        await productProvider.fetchProducts();
      } else {
        print('Delete failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete product')),
        );
      }
    } catch (e) {
      print('Error in deleteProduct: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM d, yyyy, hh:mm a');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    print('Building ProductEditDialog, _isEditing: $_isEditing');
    return AlertDialog(
      title: Text('Edit Product - ${widget.product.id}'),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 200,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                width: MediaQuery.of(context).size.width * 0.8,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...imageUrls.map((url) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Image.network(
                            url,
                            width: 120,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 120,
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(child: Text('Image Error')),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteImage(url),
                              ),
                            ),
                        ],
                      ),
                    )),
                    ...newImageFiles.map((file) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Image.file(
                            file,
                            width: 120,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                          if (_isEditing)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    newImageFiles.remove(file);
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    )),
                    if (_isEditing)
                      GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 120,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('ID: ${widget.product.id}'), // Always display as Text
              const SizedBox(height: 8),
              _isEditing
                  ? TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              )
                  : Text('Name: ${widget.product.name}'),
              const SizedBox(height: 8),
              _isEditing
                  ? TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price'),
              )
                  : Text('Price: ${widget.product.price}'),
              const SizedBox(height: 8),
              _isEditing
                  ? TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              )
                  : Text('Quantity: ${widget.product.quantity}'),
              const SizedBox(height: 8),
              _isEditing
                  ? DropdownButton<String>(
                value: productCategory,
                isExpanded: true,
                hint: const Text('Select Category'),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => productCategory = value);
                  }
                },
                items: categories
                    .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                    .toList(),
              )
                  : Text('Category: ${widget.product.productCategory}'),
              const SizedBox(height: 8),
              _isEditing
                  ? TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              )
                  : Text('Description: ${widget.product.description}'),
              const SizedBox(height: 8),
              _isEditing
                  ? DropdownButton<int>(
                value: degreeOfNewness,
                isExpanded: true,
                hint: const Text('Select Condition'),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => degreeOfNewness = value);
                  }
                },
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Brand New')),
                  DropdownMenuItem(value: 2, child: Text('Almost New')),
                  DropdownMenuItem(value: 3, child: Text('Good Condition')),
                  DropdownMenuItem(value: 4, child: Text('Heavily Used')),
                ],
              )
                  : Text(
                  'Condition: ${degreeOfNewness == 1 ? 'Brand New' : degreeOfNewness == 2 ? 'Almost New' : degreeOfNewness == 3 ? 'Good Condition' : 'Heavily Used'}'),
              const SizedBox(height: 8),
              Text('Last Updated: ${_formatDateTime(widget.product.editTime)}'),
            ],
          ),
        ),
      ),
      actions: [
        if (!_isEditing)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        if (!_isEditing)
          ElevatedButton(
            onPressed: () {
              print('Edit button pressed');
              _toggleEditMode();
            },
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
            onPressed: _deleteProduct,
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
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    quantityController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}