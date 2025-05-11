import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class EditUserPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditUserPage({super.key, required this.user});

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  File? _profilePicture;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'] ?? '';
    _phoneController.text = widget.user['phone'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
  }

  // 上传头像到 Firebase Storage
  Future<String?> _uploadProfilePicture(File image) async {
    try {
      String fileName = 'profile_pictures/${widget.user['userId']}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(image);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  // 保存更改到 Firestore
  Future<void> _saveChanges() async {
    String? newImageUrl;
    if (_profilePicture != null) {
      newImageUrl = await _uploadProfilePicture(_profilePicture!);
    }

    try {
      await _firestore.collection('Users').doc(widget.user['uid']).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'profile_Picture': newImageUrl ?? widget.user['profile_picture'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error updating user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update user')),
      );
    }
  }

  // 从相册选择头像
  Future<void> _pickProfilePicture() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profilePicture = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarImage;
    if (_profilePicture != null) {
      avatarImage = FileImage(_profilePicture!);
    } else if (widget.user['profile_picture'] != null &&
        widget.user['profile_picture'].toString().isNotEmpty) {
      avatarImage = NetworkImage(widget.user['profile_picture']);
    } else {
      avatarImage = const AssetImage('assets/default_avatar.png');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickProfilePicture,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: avatarImage,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
