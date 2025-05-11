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
  File? _selectedImage;
  String avatarUrl = '';
  String sampleAvatarUrl =
      'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';
  late TextEditingController currentPasswordController;
  late TextEditingController newPasswordController;


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
    }
  }

  void _loadUserProfile() async {
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

      });
    }
  }

  void _saveProfile() async {
    // 显示 loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 上传头像（如果有选择）
      if (_selectedImage != null) {
        await _uploadImage();
      }

      // 更新用户信息
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userUid)
          .update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
        'profile_Picture': avatarUrl,
      });

      // 关闭 loading dialog
      Navigator.pop(context);

      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile updated successfully!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // 返回上一页，并标记为已保存成功
      Navigator.pop(context, true);

    } catch (e) {
      // 关闭 loading dialog
      Navigator.pop(context);

      // 显示失败提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to save profile: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _checkPasswordStrength(String password) {
    if (password.length < 6) return "Too short";
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\$&*~]'));

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

  Future<void> _handlePasswordChange(String current, String newPass, String confirm) async {
    // Check if the new password matches the confirmation password
    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    // Check if the old and new passwords are the same
    if (current == newPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password cannot be the same as the current password')),
      );
      return;
    }

    // Check the strength of the new password
    String passwordStrength = _checkPasswordStrength(newPass);
    if (passwordStrength == "Too short" || passwordStrength == "Very weak") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The new password is too weak, please choose a stronger password')),
      );
      return;
    }

    try {
      // Show a loading indicator to inform the user that the process is ongoing
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get the current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'No user signed in';
      }

      // Re-authenticate the user using the current password
      final cred = EmailAuthProvider.credential(email: user.email!, password: current);
      await user.reauthenticateWithCredential(cred);

      // Update the user's password
      await user.updatePassword(newPass);

      // Close the loading indicator
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully, logging out...')),
      );

      // Show a loading indicator while logging out
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Sign the user out
      await FirebaseAuth.instance.signOut();

      // Close the loading indicator and navigate to the login page
      Navigator.pop(context);
      navigatorKey.currentState?.pushNamedAndRemoveUntil('/emailLogin', (route) => false);

    } catch (e) {
      // Catch any errors and close the loading indicator
      Navigator.pop(context);

      String errorMsg = 'Failed to update password';
      if (e is FirebaseAuthException) {
        // Handle different FirebaseAuthException error codes
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          errorMsg = 'The current password is incorrect';
        } else if (e.code == 'weak-password') {
          errorMsg = 'The new password is too weak, please choose a stronger password';
        } else {
          errorMsg = 'Error: ${e.message}';
        }
      } else if (e is String) {
        errorMsg = e; // Handle custom error messages, such as no user signed in
      }

      // Show the detailed error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            //avatar
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl) as ImageProvider
                    : NetworkImage(sampleAvatarUrl)),
              ),
            ),

            const SizedBox(height: 8),
            const Text("Tap to change profile picture"),

            //name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            //phone
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            //email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Change Password'),
            ),


            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Save'),
            ),
          ],
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
        suffixIcon: IconButton(
          icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
      ),
    );
  }

}
