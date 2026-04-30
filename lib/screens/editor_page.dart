import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/widgets/bubble_loading_widget.dart';
import 'package:onechat/constant/constants.dart';

// ==========================================
// UPDATE EMAIL PAGE
// ==========================================

class EditMailPage extends StatefulWidget {
  const EditMailPage({super.key});
  @override
  State<EditMailPage> createState() => _EditMailPageState();
}

class _EditMailPageState extends State<EditMailPage> {
  final emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleUpdateMail() async {
    if (emailController.text.isEmpty) {
      _showSnackBar("Please fill all fields", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    // Calling the function from functions.dart
String? errorMessage = await editMail(
  newMail: emailController.text,
);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      _showSnackBar("Mail updated! Please login again.", Colors.green);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      _showSnackBar(errorMessage, Colors.redAccent);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleUpdateMail,
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

// ==========================================
// UPDATE PASSWORD PAGE
// ==========================================

class EditPassPage extends StatefulWidget {
  const EditPassPage({super.key});
  @override
  State<EditPassPage> createState() => _EditPassPageState();
}

class _EditPassPageState extends State<EditPassPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  Future<void> _handleUpdatePass() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showErrorSnackBar("Please fill all fields");
      return;
    }

    setState(() => _isLoading = true);

String? errorMessage = await updatePassword(
  newPassword: passwordController.text,
);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (errorMessage == null) {
      _showSuccessSnackBar("Password updated! Please login again.");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

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
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleUpdatePass,
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

// ==========================================
// REUSABLE WIDGETS (HELPER METHODS)
// ==========================================

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

Widget _buildSubmitButton({
  required String label,
  required VoidCallback? onPressed,
  required bool isLoading,
}) {
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
      child: isLoading
          ? const BubbleLoading() // Your custom animated widget
          : Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    ),
  );
}
