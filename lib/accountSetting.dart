import 'package:flutter/material.dart';
import 'localStorage/UserDataDatabaseHelper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserDataDatabaseHelper dbHelper = UserDataDatabaseHelper();

  @override
  void initState() {
    super.initState();
    _initTestData(); // 可选：测试插入数据
  }

  Future<void> _initTestData() async {
    await dbHelper.insertBankAccount({
      'bankName': 'Bank of Flutter',
      'cardNumber': '1234567890123456',
      'cardHolder': 'John Doe',
      'expiryDate': '12/23',
    });

    await dbHelper.insertContactUs({
      'name': 'John Doe',
      'email': 'johndoe@example.com',
      'message': 'I have an issue with my account.',
      'timestamp': DateTime.now().toString(),
    });

    await dbHelper.insertFeedback({
      'rating': 5,
      'comment': 'Great app!',
      'timestamp': DateTime.now().toString(),
    });
  }

  void _navigateToBankAccounts(BuildContext context) {}
  void _navigateToContactUs(BuildContext context) {}
  void _navigateToRateFeedback(BuildContext context) {}

  void _logout(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/default_background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Bank Accounts / Cards'),
                  onTap: () => _navigateToBankAccounts(context),
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Contact Us'),
                  onTap: () => _navigateToContactUs(context),
                ),
                ListTile(
                  leading: const Icon(Icons.star_border),
                  title: const Text('Rate Us & Feedback'),
                  onTap: () => _navigateToRateFeedback(context),
                ),
                const Spacer(),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
