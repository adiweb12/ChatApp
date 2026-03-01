import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/widgets/bubble_loading_widget.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phonenumberController = TextEditingController();
  final usernameController = TextEditingController();
  final dobController = TextEditingController(); // Added missing controller
  bool _isPasswordVisible = false;
  bool _isLoading = false;

Future<void> _handleSignup() async {
    setState(() => _isLoading = true);
    
    String? errorMessage = await signupLogic(
      username: usernameController.text,
      email: emailController.text,
      phonenumber: phonenumberController.text,
      dob: dobController.text,
      password: passwordController.text,
      allUsers: globalUserList,
    );

    if (!mounted) return;
    setState(() => _isLoading = false); // Important: Stop loading on error!

    if (errorMessage == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              height: 190,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color(0xFF1B5E20)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.person_add_outlined, size: 70, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "OneChat",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Barrio',
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text("Fill in your details to get started", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  
                  // Username Field
                  _buildTextField(usernameController, Icons.person_outlined, 'Username', 'Adith@developer'),
                  const SizedBox(height: 15),

                  // Email Field
                  _buildTextField(emailController, Icons.email_outlined, 'Email Address', 'name@example.com', keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),

                  // Phone Field
                  _buildTextField(phonenumberController, Icons.phone_outlined, 'Phone Number', '+91 1234567890', keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),

                  // DOB Field
                  _buildTextField(dobController, Icons.calendar_today_outlined, 'Date of Birth', '09/12/2008'),
                  const SizedBox(height: 15),

                  // Password Field
                  TextField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _handleSignup,
                      child: _isLoading 
                        ? const BubbleLoading() 
                        : const Text('REGISTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Login Link
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      child: const Text(
                        "Already have an Account? Login here",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                      ),
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

  // Reusable TextField builder to keep code clean
  Widget _buildTextField(TextEditingController controller, IconData icon, String label, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
