// splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/org_provider.dart';
import 'login_screen.dart';
import 'org_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    navigateNext();
  }

  void navigateNext() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orgProvider = Provider.of<OrgProvider>(context, listen: false);

    await authProvider.loadToken();
    await orgProvider.loadSelectedOrg(); // load previously selected org

    await Future.delayed(const Duration(seconds: 1));

    if (authProvider.isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrgSelectionScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
