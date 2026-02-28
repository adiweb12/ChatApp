import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/screens/bottom_bar.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring the login state is checked directly from the global variable
    bool logData = isLoggedIn; 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OneChat",
      theme: AppTheme.mainTheme, 
      home: logData ? const HomeScreen() : const LoginPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Stack allows us to place the Floating "Add" button precisely
      body: Stack(
        children: [
          Column(
            children: [
              // Custom Green Header
              _buildHeader("OneChat", context),
              
              // Main Content Area
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey),
                      SizedBox(height: 20),
                      Text(
                        "No Conversations Yet",
                        style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "Tap the + button to start chatting",
                        style: TextStyle(fontSize: 14, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Custom "Coming Soon" Button (The IconButton logic you wanted)
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Feature Coming Soon!"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
      // Integrating your Bottom Bar widget
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }
}

// Reusable Header function
Widget _buildHeader(String title, BuildContext context) {
  return Container(
    height: 180,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green, Color(0xFF1B5E20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: SafeArea(
      child: Stack(
        children: [
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 15,
            top: 15,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              elevation: 10,
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              onSelected: (value) => dropDownLogic(value, context),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'editMail',
                  child: ListTile(
                    leading: Icon(Icons.email, color: Colors.green),
                    title: Text('Edit Email'),
                  ),
                ),
                PopupMenuItem(
                  value: 'editPass',
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Colors.green),
                    title: Text('Edit Password'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logOut',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Logout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
