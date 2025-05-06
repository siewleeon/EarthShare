import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneLoginPage extends StatefulWidget {
  const PhoneLoginPage({Key? key}) : super(key: key);

  @override
  _PhoneLoginPageState createState() => _PhoneLoginPageState();
}

class _PhoneLoginPageState extends State<PhoneLoginPage> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String? verificationId;
  bool codeSent = false;

  Future<void> verifyPhoneNumber() async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {

        await FirebaseAuth.instance.signInWithCredential(credential);
        await _checkAndCreateUser();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification failed: ${e.message}")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          codeSent = true;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  Future<void> signInWithOtp() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      await _checkAndCreateUser();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  Future<void> _checkAndCreateUser() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance.collection('Users').doc(uid).get();

    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('Users').doc(uid).set({
        'userId': await _generateNewUserId(),
        'name': '',
        'phone': phoneController.text.trim(),
        'email': '',
        'address': '',
        'profile_Picture': 'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
      });
    }

    Navigator.pushReplacementNamed(context, '/home'); // 登录成功跳转页面
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
      final lastId = snapshot.docs.first['userId'].toString();
      final number = int.parse(lastId.substring(1));
      return 'U${(number + 1).toString().padLeft(4, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            if (codeSent)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: codeSent ? signInWithOtp : verifyPhoneNumber,
              child: Text(codeSent ? "Login" : "Send OTP"),
            )
          ],
        ),
      ),
    );
  }
}
