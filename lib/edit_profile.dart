import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  String _passwordStrength = '';

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
    try {
      //upload to firestore and download profile picture
      if (_selectedImage != null) {
        await _uploadImage();
      }
      //save personal information to firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userUid)
          .update({
        'name': nameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'profile_Picture': avatarUrl,
      });

      print("Save success");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Succeed to save profile！")),
      );
      Navigator.pop(context, true);

    } catch (e) {
      print("Save failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile: $e")),
      );
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
            String checkPasswordStrength(String password) {
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

            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: !showCurrentPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        suffixIcon: IconButton(
                          icon: Icon(showCurrentPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => showCurrentPassword = !showCurrentPassword),
                        ),
                      ),
                    ),
                    TextField(
                      controller: newPasswordController,
                      obscureText: !showNewPassword,
                      onChanged: (val) {
                        setState(() {
                          passwordStrength = checkPasswordStrength(val);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        suffixIcon: IconButton(
                          icon: Icon(showNewPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => showNewPassword = !showNewPassword),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Strength: $passwordStrength"),
                    ),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !showConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: IconButton(
                          icon: Icon(showConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                        ),
                      ),
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
                  onPressed: () async {
                    final currentPassword = currentPasswordController.text.trim();
                    final newPassword = newPasswordController.text.trim();
                    final confirmPassword = confirmPasswordController.text.trim();

                    if (newPassword != confirmPassword) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New passwords do not match')),
                      );
                      return;
                    }

                    try {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) throw 'No user signed in';

                      final cred = EmailAuthProvider.credential(
                        email: user.email!,
                        password: currentPassword,
                      );

                      // Re-authenticate
                      await user.reauthenticateWithCredential(cred);

                      // Update password
                      await user.updatePassword(newPassword);

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully. Logging out...')),
                      );

                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst); // return to login
                      }
                    } catch (e) {
                      Navigator.pop(context);

                      String errorMsg = 'Failed to update password.';
                      if (e is FirebaseAuthException) {
                        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
                          errorMsg = 'Incorrect current password.';
                        } else {
                          errorMsg = 'Error: ${e.message}';
                        }
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(errorMsg)),
                      );
                    }
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
}
