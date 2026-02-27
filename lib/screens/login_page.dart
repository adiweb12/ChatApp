import 'package:flutter/material.dart';
import 'package:onechat/screens/home_screen.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _loginInfoChecker(bool loginInfo, BuildContext context) async {
    if (loginInfo) {
      isLoggedIn = true;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed, check credentials...")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOGIN....", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(hintText: 'Enter Email')),
            const SizedBox(height: 20),
            TextField(controller: passwordController, decoration: const InputDecoration(hintText: 'Enter your password'), obscureText: true),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                bool success = await loginLogic(
                  email: emailController.text,
                  password: passwordController.text,
                  allUsers: globalUserList,
                );
                await _loginInfoChecker(success, context);
              },
              child: const Text('Authenticate'),
            ),
          ],
        ),
      ),
    );
  }
}
