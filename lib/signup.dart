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

  Future<void> _requestOtp() async {
    if (_email.text.isEmpty || _phone.text.isEmpty || _pass.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/signup-request"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "phone": _phone.text.trim(),
          "password": _pass.text,
        }),
      );

      if (response.statusCode == 200) {
        _showOtpDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Signup request failed")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error connecting to Render")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify OTP"),
        content: TextField(
          controller: _otp,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter 6-digit code"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(onPressed: _verifyAndFinish, child: const Text("Verify")),
        ],
      ),
    );
  }

  Future<void> _verifyAndFinish() async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/verify-otp"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": _email.text.trim(), "otp": _otp.text.trim()}),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context); // Close dialog
      Navigator.pop(context); // Go back to login screen
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account verified! Please login.")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
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
              ? const CircularProgressIndicator(color: Color(0xFF075E54))
              : SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(onPressed: _requestOtp, child: const Text("SEND OTP")),
                ),
            const SizedBox(height: 15),
            // THE "HAVE ACCOUNT" OPTION YOU ASKED FOR:
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFF075E54))),
            ),
          ],
        ),
      ),
    );
  }
}
