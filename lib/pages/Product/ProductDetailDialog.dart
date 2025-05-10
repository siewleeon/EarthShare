import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/product.dart';

class ProductDetailDialog extends StatefulWidget {
  final Product product;

  const ProductDetailDialog({super.key, required this.product});

  @override
  State<ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<ProductDetailDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  late TextEditingController descriptionController;
  late int degreeOfNewness;
  late String productCategory;
  late List<String> imageUrls;
  late String productID;
  late String sellerId;


  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController = TextEditingController(text: widget.product.price.toString());
    quantityController = TextEditingController(text: widget.product.quantity.toString());
    descriptionController = TextEditingController(text: widget.product.description);
    degreeOfNewness = widget.product.degreeOfNewness;
    productCategory = widget.product.productCategory;
    imageUrls = List<String>.from(widget.product.imageId);
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        imageUrls.add(url);
      });
    }
  }

  void _saveChanges() async {
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one image is required.")),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.product.id)
        .update({
      'product_Name': nameController.text,
      'product_Price': double.tryParse(priceController.text),
      'product_Quantity': int.tryParse(quantityController.text),
      'product_Category': productCategory,
      'images': imageUrls,
      'product_Description': descriptionController.text,
      'degree_of_Newness': degreeOfNewness,
      'product_Edit_Time': DateTime.now(),

    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Product"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price"), keyboardType: TextInputType.number),
            TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Quantity"), keyboardType: TextInputType.number),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Description")),
            const SizedBox(height: 10),

            DropdownButtonFormField<int>(
              value: degreeOfNewness,
              decoration: const InputDecoration(labelText: 'Condition'),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Brand New')),
                DropdownMenuItem(value: 2, child: Text('Almost New')),
                DropdownMenuItem(value: 3, child: Text('Good Condition')),
                DropdownMenuItem(value: 4, child: Text('Heavily Used Condition')),
              ],
              onChanged: (value) => setState(() => degreeOfNewness = value ?? degreeOfNewness),
            ),

            DropdownButtonFormField<String>(
              value: productCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Shoes', 'Fashion', 'Toy', 'Furniture','Beauty','Health','Game','Camera','Other'
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (value) => setState(() => productCategory = value ?? productCategory),
            ),

            const SizedBox(height: 10),
            const Text("Images (at least one):"),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...imageUrls.map((url) => Stack(
                  children: [
                    Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: imageUrls.length <= 1
                            ? null
                            : () => setState(() => imageUrls.remove(url)),
                      ),
                    ),
                  ],
                )),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.add_a_photo),
                  ),
                )
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
        ElevatedButton(onPressed: _saveChanges, child: const Text("Save")),
      ],
    );
  }
}
