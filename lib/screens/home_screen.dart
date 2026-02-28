import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    bool logData = isLoggedIn; 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OneChat",
      theme: AppTheme.mainTheme, 
      home: logData ? const HomeScreen() : const LoginPage(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar removed to allow the green container to hit the top
      body: Column(
        children: [
          // The green container now serves as the Header/AppBar
          _buildHeader("OneChat", context),
          const Expanded(
            child: Center(
              child: Text(
                "Chat Section",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Header function modified to include the Menu button
Widget _buildHeader(String title, BuildContext context) {
  return Container(
    height: 150, // Increased height slightly since it now covers the top area
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green, Color(0xFF1B5E20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(0.1)),
    ),
    child: SafeArea( // Ensures content stays below the status bar (time/battery)
      child: Stack(
        children: [
          // Centered Logo and Title
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontFamily: 'FontDiner',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          // Repositioned PopupMenuButton to the top right of the green area
          Positioned(
            right: 10,
            top: 10,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              elevation: 8,
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                dropDownLogic(value, context);
              },
              itemBuilder: (BuildContext context) {
                return const [
                  PopupMenuItem<String>(
                    value: 'editMail',
                    child: ListTile(
                      leading: Icon(Icons.email, color: Colors.green),
                      title: Text('Edit Email'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'editPass',
                    child: ListTile(
                      leading: Icon(Icons.lock, color: Colors.green),
                      title: Text('Edit Password'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'logOut',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.red),
                      title: Text('Logout'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ];
              },
            ),
          ),
        ],
      ),
    ),
  );
}
