import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/home_screen.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.mainTheme,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isLoggedIn ? const HomeScreen() : const LoginPage(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Changed background to white
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Centered Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Keeps column tight around children
              children: [
                Image.asset(
                  "assets/images/splash.png",
                  width: 180, // Slightly larger for better presence
                ),
                const SizedBox(height: 20),
                const Text(
                  "OneChat",
                  style: TextStyle(
                    color: Colors.green, // Changed text to green
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Barrio",
                  ),
                ),
              ],
            ),
          ),
          // Loading Indicator at the bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.green.shade700,
                strokeWidth: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
