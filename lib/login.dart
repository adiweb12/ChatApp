import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'signup.dart';
import 'home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_email.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "password": _pass.text,
        }),
      );

      if (response.statusCode == 200) {
        // ONLY navigate if backend says OK
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage()));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Email or Password")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Server Error. Check Render connection.")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("ChatApp", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF075E54))),
            const SizedBox(height: 40),
            TextField(controller: _email, decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator(color: Color(0xFF075E54))
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _handleLogin, child: const Text("LOGIN")),
                ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SignUpPage())),
              child: const Text("New here? Create account", style: TextStyle(color: Color(0xFF075E54))),
            ),
          ],
        ),
      ),
    );
  }
}
