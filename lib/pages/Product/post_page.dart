import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

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

  List<String> selectedCategories = [];

  Future<void> _pickImages() async {
    final List<XFile>? selected = await _picker.pickMultiImage();
    if (selected != null && selected.isNotEmpty) {
      setState(() {
        _images.addAll(selected);
      });
    }
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
              const Text('选择图片来源', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照'),
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
                title: const Text('相册'),
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
    String productID = "P${DateTime.now().millisecondsSinceEpoch}";
    String name = _nameController.text.trim();
    double price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    int quantity = int.tryParse(_quantityController.text.trim()) ?? 0;
    String description = _descriptionController.text.trim();
    String sellerID = "U0001"; // 你可以根据需要动态生成
    int Condition = 0;

    if (name.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有信息并选择图片')),
      );
      return;
    }
     if(_selectedCondition == "brand new"){
       Condition = 1;
     }
     else if(_selectedCondition == "Almost new"){
       Condition = 2;
     }
     else if(_selectedCondition == "Good Condition"){
       Condition = 3;
     }
     else{
       Condition = 4;
     }



    List<String> imageUrls = [];

    for (var image in _images) {
      final file = File(image.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('product/${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      imageUrls.add(downloadUrl);
    }

    await FirebaseFirestore.instance.collection('product').add({
      "product_ID": productID,
      "product_Name": name,
      "product_Price": price,
      "product_Quantity": quantity,
      "product_Description": description,
      "product_Cetogory": selectedCategories,
      "product_SallerID": sellerID,
      "images": imageUrls,
      'degree_of_Newness': Condition,
      "product_Uplode_Time": FieldValue.serverTimestamp(),
      "product_Edit_Time": FieldValue.serverTimestamp(),
    });



    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product Has Been Posted !')),
    );

    setState(() {
      _images.clear();
      _nameController.clear();
      _priceController.clear();
      _quantityController.clear();
      _descriptionController.clear();
      selectedCategories.clear();
    });
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
            const SizedBox(height: 20),
            _buildTextField(_nameController, 'Product Name'),
            _buildTextField(_priceController, 'Price (RM)', keyboard: TextInputType.number),
            _buildTextField(_quantityController, 'Quantity', keyboard: TextInputType.number),
            const SizedBox(height: 10),
            _buildCategorySelector(),
            const SizedBox(height: 10),
            _adddegree_of_Newness(),
            _buildTextField(_descriptionController, 'Discribe', maxLines: 3),
            ElevatedButton.icon(
              onPressed: _uploadProduct,
              icon: const Icon(Icons.upload),
              label: const Text('Uplode'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = ['Shoes', 'Fashion', 'Toy', 'Furniture','Beauty','Health','Game','Camera','Other'];
    return Wrap(
      spacing: 8,
      children: categories.map((category) {
        final selected = selectedCategories.contains(category);
        return FilterChip(
          label: Text(category),
          selected: selected,
          onSelected: (value) {
            setState(() {
              if (value) {
                selectedCategories.add(category);
              } else {
                selectedCategories.remove(category);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _adddegree_of_Newness (){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Text(
            'Newness : ',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedCondition,
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
            ? const Text('On Picture')
            : SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return Padding(
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
              );
            },
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showImageSourceSelector,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('Add Picture'),
        ),
      ],
    );
  }
}
