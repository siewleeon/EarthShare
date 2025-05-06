import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool agreeToTerms = false;
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  String avatarUrl = 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  Future<String> _generateNewUserId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .orderBy('userId', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'U0001';
    } else {
      final lastId = snapshot.docs.first['userId'].toString(); // e.g., U0012
      final number = int.parse(lastId.substring(1)); // 12
      final newId = 'U${(number + 1).toString().padLeft(4, '0')}';
      return newId;
    }
  }

  Future<void> _saveProfile(String userId) async {
    try {
      //save personal information to firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userId)
          .set({
        'userId': userId,
        'name': nameController.text,
        'phone': phoneController.text,
        'email': emailController.text,
        'address': addressController.text,
        'password':passwordController.text,
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

  Future<int> _getNextUserId() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('Users')
        .orderBy('userId', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return 1; // first user
    }

    final lastUserId = querySnapshot.docs.first['userId'];
    return lastUserId + 1;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/register_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Form content
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 60),
                const Text(
                  "Let's Create an Account!",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField('Full Name',controllerName: nameController),
                      _buildTextField('Address',controllerName: addressController),
                      _buildTextField('Phone Number',controllerName: phoneController),
                      _buildTextField('Email Address',controllerName: emailController),
                      _buildTextField('Password', isObscure: true,controllerName: passwordController),
                      _buildTextField('Confirm Password', isObscure: true,controllerName: confirmPasswordController),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: agreeToTerms,
                            onChanged: (value) {
                              setState(() {
                                agreeToTerms = value!;
                              });
                            },
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to our ',
                                style: const TextStyle(color: Colors.black),
                                children: [
                                  TextSpan(
                                    text: 'EarthShare’s Terms of Use',
                                    style: const TextStyle(
                                        color: Colors.blueAccent,
                                        decoration: TextDecoration.underline),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(
                                        color: Colors.blueAccent,
                                        decoration: TextDecoration.underline),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate() && agreeToTerms) {
                            try {
                              // 1. 注册 Firebase Auth 帐号
                              final credential = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim());

                              final userId = await _generateNewUserId();

                              // 2. 保存 Firestore 中的资料（使用 Firebase uid 作 document ID）
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(credential.user!.uid)
                                  .set({
                                'userId': userId,
                                'name': nameController.text.trim(),
                                'phone': phoneController.text.trim(),
                                'email': emailController.text.trim(),
                                'address': addressController.text.trim(),
                                'profile_Picture': avatarUrl,
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Registration successful!")),
                              );

                              Navigator.pushNamed(context, '/emailLogin');
                            } on FirebaseAuthException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Auth Error: ${e.message}")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Registration failed: $e")),
                              );
                            }
                          } else if (!agreeToTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please agree to terms before registering.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Register'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                          backgroundColor: Colors.lightGreenAccent,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(12),

                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/emailLogin');
                        },
                        child: const Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label,{bool isObscure = false,required TextEditingController controllerName} ){
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          TextFormField(
            obscureText: isObscure,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blue[50],
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: controllerName,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}