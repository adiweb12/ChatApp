import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/screens/login_page.dart';

/// Helper to handle navigation and feedback
Future<void> goLogin(BuildContext context, bool userChoice) async {
  if (userChoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Update Successful!"), backgroundColor: Colors.green),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Something went wrong.... Check credentials.."),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}

class EditMailPage extends StatefulWidget {
  const EditMailPage({super.key});
  @override
  State<EditMailPage> createState() => _EditMailPageState();
}

class _EditMailPageState extends State<EditMailPage> {
  final phoneController = TextEditingController();
  final emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Added Stack to place a back button over the header
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader("Update Mail"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Change your account email",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 30),
                      
                      // Phone Field - Changed to Phone Keyboard
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined),
                          labelText: 'Phone Number',
                          hintText: '+91 1234567890',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'New Email',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildSubmitButton(
                        label: 'Update Mail',
                        onPressed: () async {
                          bool success = await editMail(
                            phonenumber: phoneController.text, 
                            newMail: emailController.text, 
                            allUsers: globalUserList
                          );
                          goLogin(context, success);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Clean Back Button
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class EditPassPage extends StatefulWidget {
  const EditPassPage({super.key});
  @override
  State<EditPassPage> createState() => _EditPassPageState();
}

class _EditPassPageState extends State<EditPassPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader("Security"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Update Password",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Text("Secure your account", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 30),

                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          labelText: 'Email',
                          hintText: 'abcd@efg.com',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field - Added obscureText and Toggle
                      TextField(
                        controller: passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline),
                          labelText: 'New Password',
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 40),

                      _buildSubmitButton(
                        label: 'Update Password',
                        onPressed: () async {
                          bool success = await updatePassword(
                            email: emailController.text, 
                            newPassword: passwordController.text, 
                            allUsers: globalUserList
                          );
                          goLogin(context, success);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

// Reusable Header to keep code DRY
Widget _buildHeader(String title) {
  return Container(
    height: 200,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green, Color(0xFF1B5E20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(70)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white),
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
  );
}

// Reusable Button
Widget _buildSubmitButton({required String label, required VoidCallback onPressed}) {
  return SizedBox(
    width: double.infinity,
    height: 55,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
