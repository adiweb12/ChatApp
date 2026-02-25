import 'package:flutter/material.dart';
import 'signup.dart';
import 'home.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
            const TextField(decoration: InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            const TextField(obscureText: true, decoration: InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const HomePage())),
                child: const Text("LOGIN"),
              ),
            ),
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
