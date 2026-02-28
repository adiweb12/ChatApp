import 'package:flutter/material.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/starter.dart'; // Import where your HomeScreen/Starter is

class AddChatGroupPage extends StatefulWidget {
  const AddChatGroupPage({super.key});

  @override
  State<AddChatGroupPage> createState() => _AddChatGroupPageState();
}

class _AddChatGroupPageState extends State<AddChatGroupPage> {
  List<UserDetails> matchedContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedContacts();
  }

  void _loadMatchedContacts() async {
    var users = await getMatchedContacts(globalUserList);
    if (mounted) {
      setState(() {
        matchedContacts = users;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAddContactHeader("Select Contact", context),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : matchedContacts.isEmpty
                    ? const Center(
                        child: Text("No contacts found on OneChat",
                            style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : ListView.builder(
                        itemCount: matchedContacts.length,
                        padding: const EdgeInsets.only(top: 10),
                        itemBuilder: (context, index) {
                          final user = matchedContacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(user.userName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(user.userName,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(user.phoneNumber),
                            trailing: const Icon(Icons.chat, color: Colors.green),
                            onTap: () {},
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// Renamed to avoid conflict with the other _buildHeader
Widget _buildAddContactHeader(String title, BuildContext context) {
  return Container(
    height: 180,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green, Color(0xFF1B5E20)],
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30),
      ),
    ),
    child: SafeArea(
      child: Stack(
        children: [
          Positioned(
            left: 10, top: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (context) => const HomeScreen())),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_outlined, size: 50, color: Colors.white),
                const SizedBox(height: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
