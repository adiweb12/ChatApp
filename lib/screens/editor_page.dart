import 'package:flutter/material.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/screens/login_page.dart';

Future<void> goLogin(BuildContext context, bool userChoice) async {
  if (userChoice) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Something went wrong...")),
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
      appBar: AppBar(title: const Text("Edit Email")),
      body: Column(
        children: [
          TextField(controller: phoneController, decoration: const InputDecoration(hintText: 'PHONE')),
          TextField(controller: emailController, decoration: const InputDecoration(hintText: 'New Email')),
          ElevatedButton(
            onPressed: () async {
              bool success = await editMail(phonenumber: phoneController.text, newMail: emailController.text, allUsers: globalUserList);
              goLogin(context, success);
            },
            child: const Text("Update"),
          )
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Password")),
      body: Column(
        children: [
          TextField(controller: emailController, decoration: const InputDecoration(hintText: 'Email')),
          TextField(controller: passwordController, decoration: const InputDecoration(hintText: 'New Password')),
          ElevatedButton(
            onPressed: () async {
              bool success = await updatePassword(email: emailController.text, newPassword: passwordController.text, allUsers: globalUserList);
              goLogin(context, success);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}
