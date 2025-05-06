import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:EarthShareApp/phoneLogin.dart';
import 'package:EarthShareApp/profile.dart';
import 'package:EarthShareApp/register.dart';
import 'package:EarthShareApp/emailLogin.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Profile App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/register',
      routes: {
        '/profile': (context) => const ProfilePage(),
        '/register': (context) => const RegisterPage(),
        '/emailLogin': (context) => const EmailLoginPage(),
        '/phoneLogin': (context) => const PhoneLoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
