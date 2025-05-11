import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  String avatarUrl = 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png';

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
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

  Color getStrengthColor(String strength) {
    return switch (strength) {
      "Strong" => Colors.green,
      "Medium" => Colors.orange,
      "Weak" => Colors.redAccent,
      _ => Colors.red
    };
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

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate() && agreeToTerms) {
      try {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final userId = await _generateNewUserId();

        await FirebaseFirestore.instance
            .collection('Users')
            .doc(credential.user!.uid)
            .set({
          'userId': userId,
          'name': nameController.text.trim(),
          'phone': phoneController.text.trim(),
          'email': emailController.text.trim(),
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
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
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
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
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
                              _buildTextField('Full Name', controllerName: nameController, validator: validateName),
                              _buildTextField('Phone Number', controllerName: phoneController, validator: validatePhone),
                              _buildTextField('Email Address', controllerName: emailController, validator: validateEmail),
                              _buildPasswordField('Password'),
                              _buildConfirmPasswordField('Confirm Password'),
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
                                onPressed: _handleRegister,
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
                ),
              );
            },
          ),

        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, {
        TextEditingController? controllerName,
        bool isObscure = false,
        String? Function(String?)? validator, // 新增参数
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controllerName,
        obscureText: isObscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.blue[50],
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: validator, // 使用外部传入的验证函数
      ),
    );
  }


  Widget _buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blue[50],
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: passwordController,
            validator: (value) {
              String passwordStrength = checkPasswordStrength(value ?? '');
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              } else if (passwordStrength == 'Too short') {
                return 'Password is too short';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),
          Text(
            checkPasswordStrength(passwordController.text),
            style: TextStyle(color: getStrengthColor(checkPasswordStrength(passwordController.text))),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 4),
          TextFormField(
            obscureText: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.blue[50],
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            controller: confirmPasswordController,
            validator: validateConfirmPassword,
          ),
        ],
      ),
    );
  }
}
