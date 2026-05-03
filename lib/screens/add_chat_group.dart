import 'package:flutter/material.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/screens/home_screen.dart';
import 'package:onechat/screens/chat_page.dart';

class AddChatGroupPage extends StatefulWidget {
  const AddChatGroupPage({super.key});

  @override
  State<AddChatGroupPage> createState() => _AddChatGroupPageState();
}

class _AddChatGroupPageState extends State<AddChatGroupPage> {
  List<SyncedContact> matchedContacts = []; 
  bool isLoading = true;

@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadMatchedContacts();
  });
}

  void _loadMatchedContacts() async {
  var synced = await getMatchedContacts(context);

  // Use synced contacts from local DB instead of getAllUsers
  var localContacts = await getLocalSyncedContacts(currentUser!.phoneNumber);

  // Merge without duplicates
  final Map<String, SyncedContact> uniqueMap = {};
  for (var c in synced) {
    uniqueMap[c.phoneNumber] = c;
  }
  for (var c in localContacts) {
    uniqueMap[c.phoneNumber] = c;
  }

  if (mounted) {
    setState(() {
      matchedContacts = uniqueMap.values.toList();
      isLoading = false;
    });
  }
}

 void _showAddByNumberDialog() {
  final controller = TextEditingController();
  bool searching = false;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Enter Phone Number"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: "e.g. 9876543210",
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL"),
            ),
            ElevatedButton(
              onPressed: searching
                  ? null
                  : () async {
                      if (controller.text.isEmpty) return;

                      setDialogState(() => searching = true);

                      SyncedContact? result =
                          await findUserByNumber(controller.text);

                      setDialogState(() => searching = false);

                      if (result != null) {
                        // ✅ SAVE USER LOCALLY
                        await insertUser(UserDetails(
                          id: result.id,
                          userName: result.userName,
                          email: "",
                          phoneNumber: result.phoneNumber,
                          password: "",
                          dob: "",
                        ));

                        Navigator.pop(context);

                        // 🔥 REFRESH CONTACT LIST
                        _loadMatchedContacts();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              receiverPhone: result.phoneNumber,
                              receiverName: result.userName,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User not found")),
                        );
                      }
                    },
              child: searching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("FIND"),
            ),
          ],
        );
      },
    ),
  );
} 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildAddContactHeader("New Chat", context),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.group, color: Colors.green)),
            title: const Text("New Group", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectParticipantsPage())),
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFFE3F2FD), child: Icon(Icons.phone_android, color: Colors.blue)),
            title: const Text("New Chat by Number", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => _showAddByNumberDialog(),
          ),
          const Divider(thickness: 0.5),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : ListView.builder(
                    itemCount: matchedContacts.length,
                    itemBuilder: (context, index) {
                      final user = matchedContacts[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green, 
                          child: Text(user.userName[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                        ),
                        title: Text(user.userName),
                        subtitle: Text(user.phoneNumber),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ChatPage(receiverPhone: user.phoneNumber, receiverName: user.userName)
                          ));
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

// Header helper
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

// --- SELECT PARTICIPANTS PAGE ---
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
  var synced = await getMatchedContacts(context);
  var localContacts = await getLocalSyncedContacts(currentUser!.phoneNumber);

  final Map<String, SyncedContact> uniqueMap = {};
  for (var c in synced) {
    uniqueMap[c.phoneNumber] = c;
  }
  for (var c in localContacts) {
    uniqueMap[c.phoneNumber] = c;
  }

  if (mounted) {
    setState(() {
      contacts = uniqueMap.values.toList();
      isLoading = false;
    });
  }
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
                Navigator.pop(context); // Back to AddChatGroupPage
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
