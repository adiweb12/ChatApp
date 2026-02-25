import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _otp = TextEditingController();
  bool _isLoading = false;

  // Step 1: Submit Details to Backend
  Future<void> _requestOtp() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/signup-request"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text,
          "phone": _phone.text,
          "password": _pass.text,
        }),
      );

      if (response.statusCode == 200) {
        _showOtpDialog();
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Step 2: Verify OTP
  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Email"),
        content: TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter OTP sent to email"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: _verifyAndFinish, child: const Text("Verify")),
        ],
      ),
    );
  }

  Future<void> _verifyAndFinish() async {
    // Send OTP to backend to confirm registration
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/verify-otp"),
      body: jsonEncode({"email": _email.text, "otp": _otp.text}),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 80, color: Color(0xFF075E54)),
            const SizedBox(height: 20),
            TextField(controller: _email, decoration: const InputDecoration(hintText: "Email", prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 15),
            TextField(controller: _phone, decoration: const InputDecoration(hintText: "Phone Number", prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 15),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(hintText: "Password", prefixIcon: Icon(Icons.lock))),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator()
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _requestOtp, child: const Text("SEND OTP")),
                ),
          ],
        ),
      ),
    );
  }
}
