import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/screens/home_screen.dart';
import 'package:onechat/constant/constants.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';



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
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;
    await checkLoginStatus(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset("assets/images/splash.png", width: 180),
                const SizedBox(height: 20),
                const Text(
                  "OneChat",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 50, left: 0, right: 0,
            child: Center(child: CircularProgressIndicator(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}

Future<void> checkLoginStatus(BuildContext context) async {
    
   String? loginStatus = await storage.read(key: SECRET_LOGIN_KEY);
   String? savedId = await storage.read(key: User_Id);
   
   bool isLoggedIn = loginStatus == 'true';

  if (isLoggedIn && savedId != null) {
    final dbClient = await dbMaker.db; 
    List<Map<String, dynamic>> maps = await dbClient.query(
      "UserData",
      where: "id = ?",
      whereArgs: [savedId],
    );

    if (maps.isNotEmpty) {
      currentUser = UserDetails(
        id: maps[0]['id'],
        userName: maps[0]['userName'],
        email: maps[0]['email'],
        phoneNumber: maps[0]['phoneNumber'],
        password: maps[0]['password'],
        dob: maps[0]['dob'],
      );
    }
  }

  if (!context.mounted) return;
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => (isLoggedIn && currentUser != null)
          ? const HomeScreen()
          : const LoginPage(),
    ),
  );
}
