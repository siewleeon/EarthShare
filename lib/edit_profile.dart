import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'main.dart';

class EditProfilePage extends StatefulWidget {
  final String userUid;

  const EditProfilePage({Key? key, required this.userUid}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;

  File? _selectedImage;
  String avatarUrl = '';
  String sampleAvatarUrl =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
  bool _isUploading = false;
  bool _isChangingPassword = false;
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    try {
      if (_selectedImage == null || !_selectedImage!.existsSync()) {
        print('No valid image selected');
        return;
      }

      setState(() => _isUploading = true);

      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${widget.userUid}.jpg');

      print('Uploading image...');
      await ref.putFile(_selectedImage!);
      print('Upload complete');

      final url = await ref.getDownloadURL();
      print('Download URL: $url');

      setState(() {
        avatarUrl = url;
      });

    } catch (e) {
      print('Upload failed: $e');
      rethrow;
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _loadUserProfile() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userUid)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          nameController.text = data['name'] ?? '';
          phoneController.text = data['phone'] ?? '';
          emailController.text = data['email'] ?? '';
          avatarUrl = data['profile_Picture'] ?? '';
          _isLoading = false;

        });
      }else {
        setState(() => _isLoading = false);}
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final isUnique = await _isEmailUnique(emailController.text.trim());
    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ This email is already registered to another account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 显示 loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (_selectedImage != null) {
        await _uploadImage();
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userUid)
          .update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'profile_Picture': avatarUrl,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to save profile: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _isEmailUnique(String email) async {
    final query = await FirebaseFirestore.instance
        .collection('Users')
        .where('email', isEqualTo: email)
        .get();

    for (var doc in query.docs) {
      if (doc.id != widget.userUid) {
        return false; // 有其他用户用了这个 email
      }
    }
    return true;
  }

  String _checkPasswordStrength(String password) {
    if (password.length < 6) return "Too short";
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\\$&*~]'));

    int strength = [hasUpper, hasLower, hasDigit, hasSpecial].where((e) => e).length;
    switch (strength) {
      case 4:
        return "Strong";
      case 3:
        return "Medium";
      case 2:
        return "Weak";
      default:
        return "Very weak";
    }
  }

  Color getStrengthColor(String strength) {
    return switch (strength) {
      "Strong" => Colors.green,
      "Medium" => Colors.orange,
      "Weak" => Colors.redAccent,
      _ => Colors.red
    };
  }

  Future<void> _showLoadingDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $msg'), backgroundColor: Colors.red),
    );
  }

  Future<void> _handlePasswordChange(String current, String newPass, String confirm) async {
    if (_isChangingPassword) return;
    setState(() => _isChangingPassword = true);

    try {
      if (newPass != confirm) {
        _showError('New passwords do not match');
        return;
      }

      if (current == newPass) {
        _showError('New password cannot be the same as the current password');
        return;
      }

      String strength = _checkPasswordStrength(newPass);
      if (strength == "Too short" || strength == "Very weak") {
        _showError('The new password is too weak, please choose a stronger password');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showError('No user signed in');
        return;
      }

      // 显示加载框
      await _showLoadingDialog('Updating password...');

      // 重新验证身份
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);

      await user.updatePassword(newPass);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully, logging out...')),
      );

      await _showLoadingDialog('Logging out...');
      await FirebaseAuth.instance.signOut();

      Navigator.pop(context);
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/emailLogin', (route) => false);

    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // 关闭加载框
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _showError('The current password is incorrect');
          break;
        case 'weak-password':
          _showError('The new password is too weak');
          break;
        default:
          _showError('Firebase error: ${e.message}');
      }
    } catch (e) {
      Navigator.pop(context); // 关闭加载框
      _showError(e.toString());
    } finally {
      setState(() => _isChangingPassword = false);
    }
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showCurrentPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;
    String passwordStrength = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPasswordField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      isVisible: showCurrentPassword,
                      onToggle: () => setState(() => showCurrentPassword = !showCurrentPassword),
                    ),
                    _buildPasswordField(
                      controller: newPasswordController,
                      label: 'New Password',
                      isVisible: showNewPassword,
                      onToggle: () => setState(() => showNewPassword = !showNewPassword),
                      onChanged: (val) => setState(() => passwordStrength = _checkPasswordStrength(val)),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Strength: $passwordStrength",
                        style: TextStyle(color: getStrengthColor(passwordStrength)),
                      ),
                    ),
                    _buildPasswordField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      isVisible: showConfirmPassword,
                      onToggle: () => setState(() => showConfirmPassword = !showConfirmPassword),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _handlePasswordChange(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                      confirmPasswordController.text.trim(),
                    );
                  },
                  child: const Text('Change'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegExp = RegExp(r'^\+?[0-9]{7,15}$');
    if (!phoneRegExp.hasMatch(value)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(screenHeight * 0.1),
        child: AppBar(
          backgroundColor: const Color(0xFFCCFF66),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          leading: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: screenWidth * 0.2, // 头像更大一点
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl) as ImageProvider
                          : NetworkImage(sampleAvatarUrl)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap to change profile picture",
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF66CCFF),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Name input
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      labelStyle: TextStyle(color: const Color(0xFF66CCFF),fontSize: 22),
                      hintText: 'Enter your name',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF66CCFF), width: 2),
                      ),
                    ),
                    validator: validateName,
                  ),
                  const SizedBox(height: 16),

                  // Phone input
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      labelStyle: TextStyle(color: const Color(0xFF66CCFF),fontSize: 22),
                      hintText: 'Enter your phone number',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF66CCFF), width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: validatePhone,
                  ),
                  const SizedBox(height: 16),

                  // Email input
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: const Color(0xFF66CCFF),fontSize: 22),
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFF66CCFF), width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 24),

                  // Change Password button
                  ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF66CCFF), // 按钮颜色
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Change Password',

                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Profile button
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  const Color(0xFFCCFF66), // 按钮颜色
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16,color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }
}