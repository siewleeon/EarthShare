import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../dashboardpage.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});
  @override
  _PostPageState createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  String _selectedCondition = 'Brand new';

  final List<String> _conditions = [
    'Brand new',
    'Almost new',
    'Good Condition',
    'Heavily Used Condition',
  ];

  // 控制器
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? selectedCategory;

  Future<void> _pickImages() async {
    final List<XFile>? selected = await _picker.pickMultiImage();
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _images.addAll(selected);
      });
    }
  }

  Future<String> _generateProductID() async {
    final counterRef = FirebaseFirestore.instance.collection('counters').doc('product_counter');
    final snapshot = await counterRef.get();

    int latestNumber = 0;
    if (snapshot.exists && snapshot.data()!.containsKey('latest_product_number')) {
      latestNumber = snapshot.data()!['latest_product_number'];
    }

    final newNumber = latestNumber + 1;
    await counterRef.set({'latest_product_number': newNumber});

    return 'P${newNumber.toString().padLeft(4, '0')}';
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              const Text('Image Source', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () async {
              Navigator.pop(context);
              final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
              if (photo != null) {
                setState(() => _images.add(photo));
              }
            },
          ),
          ListTile(
              leading: const Icon(Icons.photo_library),
          title: const Text('Gallery'),
          onTap: () async {
            Navigator.pop(context);
            final List<XFile>? selected = await _picker.pickMultiImage();
            if (selected != null && selected.isNotEmpty) {
              setState(() => _images.addAll(selected));
            }
          },
        ),
        ],
        ),
        );
      },
    );
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _images.add(photo);
      });
    }
  }

  Future<void> _uploadProduct() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading product...'),
          ],
        ),
      ),
    );

    try {
      String productID = await _generateProductID(); // 获取格式化好的 ID
      String name = _nameController.text.trim();
      double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
      int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
      String description = _descriptionController.text.trim();

      String? firebaseUID = FirebaseAuth.instance.currentUser?.uid;
      if (firebaseUID == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('用户未登录，无法上传商品')),
        );
        return;
      }

      // 从 Firestore 获取用户 User_ID 字段
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('Users').doc(firebaseUID).get();
      final data = userDoc.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('userId')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法获取用户 ID')),
        );
        return;
      }

      String sellerID = data['userId'];

      int condition = 0;

      if (name.isEmpty || _images.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请填写所有信息并选择图片')),
        );
        return;
      }
      if (_selectedCondition == "Brand new") {
        condition = 1;
      } else if (_selectedCondition == "Almost new") {
        condition = 2;
      } else if (_selectedCondition == "Good Condition") {
        condition = 3;
      } else {
        condition = 4;
      }

      List<Future<String>> uploadFutures = _images.map((image) async {
        final file = File(image.path);
        final ref = FirebaseStorage.instance
            .ref()
            .child('product/${DateTime.now().millisecondsSinceEpoch}_${image.name}');
        await ref.putFile(file);
        return await ref.getDownloadURL();
      }).toList();

      List<String> imageUrls = await Future.wait(uploadFutures);

      await FirebaseFirestore.instance.collection('products').add({
        "product_ID": productID,
        "product_Name": name,
        "product_Price": price,
        "product_Quantity": quantity,
        "product_Description": description,
        "product_Category": selectedCategory ?? '',
        "product_SellerID": sellerID,
        "images": imageUrls,
        'degree_of_Newness': condition,
        "product_Upload_Time": FieldValue.serverTimestamp(),
        "product_Edit_Time": FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product Has Been Posted !')),
      );

      setState(() {
        _images.clear();
        _nameController.clear();
        _priceController.clear();
        _quantityController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      // Close loading dialog in case of error
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading product: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.lightGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _addPicture(),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'Product Name'),
            const SizedBox(height: 12),
            _buildTextField(_priceController, 'Price (RM)', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _buildTextField(_quantityController, 'Quantity', keyboard: TextInputType.number),
            const SizedBox(height: 16),
            _buildCategorySelector(),
            const SizedBox(height: 16),
            _adddegree_of_Newness(),
            const SizedBox(height: 16),
            _buildTextField(_descriptionController, 'Description', maxLines: 3),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: _uploadProduct,
                icon: const Icon(Icons.upload),
                label: const Text('Upload'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.lightGreen, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'label': 'Shoes', 'icon': Icons.directions_run},
      {'label': 'Fashion', 'icon': Icons.checkroom},
      {'label': 'Electronic', 'icon': Icons.computer},
      {'label': 'Toy', 'icon': Icons.toys},
      {'label': 'Furniture', 'icon': Icons.chair},
      {'label': 'Beauty', 'icon': Icons.brush},
      {'label': 'Health', 'icon': Icons.health_and_safety},
      {'label': 'Game', 'icon': Icons.sports_esports},
      {'label': 'Camera', 'icon': Icons.photo_camera},
      {'label': 'Other', 'icon': Icons.category},
    ];

    return Wrap(
      spacing: 5,
      runSpacing: 8,
      children: categories.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        final label = category['label'] as String;
        final icon = category['icon'] as IconData;
        final selected = selectedCategory == label;

        return AnimatedCategoryItem(
          delay: Duration(milliseconds: index * 100),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedCategory = label;
                });
              },
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                        ),
                      ],
                      border: selected
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      color: selected ? Colors.black : Colors.grey,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _adddegree_of_Newness() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Text(
            'Newness: ',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedCondition,
                underline: const SizedBox(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCondition = newValue!;
                  });
                },
                items: _conditions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addPicture() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _images.isEmpty
            ? const Text('No picture selected')
            : SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_images[index].path),
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _images.removeAt(index);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _showImageSourceSelector,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Picture'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ],
    );
  }
}