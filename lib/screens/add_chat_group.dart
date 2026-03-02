import 'package:flutter/material.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/screens/home_screen.dart'; // Import where your HomeScreen/Starter is

class AddChatGroupPage extends StatefulWidget {
  const AddChatGroupPage({super.key});

  @override
  State<AddChatGroupPage> createState() => _AddChatGroupPageState();
}


class _AddChatGroupPageState extends State<AddChatGroupPage> {
  // CHANGED: Use SyncedContact to match your functions and models
  List<SyncedContact> matchedContacts = []; 
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatchedContacts();
  }

  void _loadMatchedContacts() async {
    var users = await getMatchedContacts(); // This returns List<SyncedContact>
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
          _buildAddContactHeader("New Chat", context),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.group, color: Colors.green),
            ),
            title: const Text("New Group", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              // FIXED: Navigate to the selection page you created
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const SelectParticipantsPage())
              );
            },
          ),
          const Divider(thickness: 0.5),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : matchedContacts.isEmpty
                    ? const Center(child: Text("Invite friends to OneChat!"))
                    : ListView.builder(
                        itemCount: matchedContacts.length,
                        itemBuilder: (context, index) {
                          final user = matchedContacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green,
                              child: Text(user.userName[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(user.userName),
                            subtitle: Text(user.phoneNumber),
                            onTap: () {
                              // Start 1-on-1 Chat logic
                            },
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
class SelectParticipantsPage extends StatefulWidget {
  const SelectParticipantsPage({super.key});

  @override
  State<SelectParticipantsPage> createState() => _SelectParticipantsPageState();
}

class _SelectParticipantsPageState extends State<SelectParticipantsPage> {
  List<SyncedContact> contacts = [];
  List<SyncedContact> selectedContacts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    var list = await getMatchedContacts();
    setState(() {
      contacts = list;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Participants"),
        actions: [
          if (selectedContacts.isNotEmpty)
            TextButton(
              onPressed: () => _showGroupNameDialog(),
              child: const Text("NEXT", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              final isSelected = selectedContacts.contains(contact);

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(child: Text(contact.userName[0])),
                    if (isSelected)
                      const Positioned(bottom: 0, right: 0, child: Icon(Icons.check_circle, color: Colors.green, size: 18)),
                  ],
                ),
                title: Text(contact.userName),
                subtitle: Text(contact.phoneNumber),
                onTap: () {
                  setState(() {
                    isSelected ? selectedContacts.remove(contact) : selectedContacts.add(contact);
                  });
                },
              );
            },
          ),
    );
  }

  void _showGroupNameDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Group Name"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter group name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              String? err = await createGroupLogic(controller.text, selectedContacts.map((e) => e.id).toList());
              if (err == null) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to home
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group Created!")));
              }
            }, 
            child: const Text("CREATE")
          ),
        ],
      ),
    );
  }
}
