import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:second_hand_shop/pages/Product/post_page.dart';
import 'providers/point_provider.dart';
import 'pages/home_page.dart';
import 'profile.dart';  
import 'register.dart';  
import 'emailLogin.dart'; 
import 'phoneLogin.dart';  
import 'pages/history_page.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'providers/transaction_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}




class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => ProductProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TransactionProvider(),
        ),
        ChangeNotifierProvider(
          create: (ctx) => PointProvider(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'EarthShare',
        initialRoute: '/home',
        routes: {  
          '/home': (context) => const HomePage(),
          '/history': (context) => const HistoryPage(),
          '/post': (context) => const PostPage(),
          '/profile': (context) => const ProfilePage(),
          '/register': (context) => const RegisterPage(),
          '/emailLogin': (context) => const EmailLoginPage(),
          '/phoneLogin': (context) => const PhoneLoginPage(),
        },
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
