import 'package:flutter/material.dart';
import 'package:onechat/screen/login_page.dart';
import 'package:onechat/theme/theme.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    bool logData = isLoggedIn; // added missing semicolon

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OneChat",
      theme: AppTheme.mainTheme, // fixed class name capitalization
      home: logData ? const HomeScreen() : const LoginPage(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: Colors.black, width: 0.5),
            ),
            color: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.more_vert, color: Colors.green),
            onSelected: (value) {
              dropDownLogic(value, context);
            },
            itemBuilder: (BuildContext context) {
              return const [
                PopupMenuItem<String>(
                  value: 'editMail',
                  child: Text('Edit Email'),
                ),
                PopupMenuItem<String>(
                  value: 'editPass',
                  child: Text('Edit Password'),
                ),
              ];
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: Colors.green,
        ),
        title: const Text(
          "OneChat",
          style: TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'FontDiner', // fixed font family case
          ),
        ),
      ),
      body: const Center(
        child: Text("Welcome Home!"),
      ),
    );
  }
}