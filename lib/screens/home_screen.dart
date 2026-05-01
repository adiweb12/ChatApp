import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:flutter/material.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/screens/bottom_bar.dart';
import 'package:onechat/screens/add_chat_group.dart';
import 'package:onechat/screens/chat_page.dart';
import 'package:onechat/constant/api_urls.dart';
import 'package:onechat/backend/api_services.dart';
import 'package:dio/dio.dart';
import 'package:onechat/backend/ws_services.dart';
import 'package:onechat/functions/web_functions.dart';

class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensuring the login state is checked directly from the global variable
    bool logData = isLoggedIn; 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OneChat",
      theme: AppTheme.mainTheme, 
      home: logData ? const HomeScreen() : const LoginPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  List<SyncedContact> activeChats = [];
  bool isListLoading = true;

@override
void initState() {
  super.initState();
  _init();
}

Future<void> _init() async {
  await chatLoader();

  // Listen for real-time updates
  WSService().onMessageReceived = (msg) {
    _loadActiveChats(); // refresh UI
  };
 await syncChatsFromServer();  
  await _loadActiveChats();
}

Future<void> _loadActiveChats() async {
  final chats = await getAllChats(currentUser!.phoneNumber);

  setState(() {
    activeChats = chats.map((c) => SyncedContact(
      id: c.id,
      currentUserPhone: currentUser!.phoneNumber,
      userName: c.receiverName,
      phoneNumber: c.receiverNum,
    )).toList();

    isListLoading = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader("OneChat", context),
              Expanded(
                child: isListLoading 
                ? const Center(child: CircularProgressIndicator())
                : activeChats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: activeChats.length,
                    itemBuilder: (context, index) {
                      final chat = activeChats[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(chat.userName[0])),
                        title: Text(chat.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text("Tap to view messages"),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (context) => ChatPage(receiverPhone: chat.phoneNumber, receiverName: chat.userName)
                          ));
                        },
                      );
                    },
                  ),
              ),
            ],
          ),
          // Floating Add Button
          Positioned(
            bottom: 30,
            right: 30,
            child: Container(
              decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddChatGroupPage())).then((_) => _loadActiveChats()),
                icon: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 100, color: Colors.grey),
          Text("No Conversations Yet", style: TextStyle(fontSize: 18, color: Colors.grey)),
          Text("Tap the + button to start chatting", style: TextStyle(fontSize: 14, color: Colors.black45)),
        ],
      ),
    );
  }
}


// Reusable Header function
Widget _buildHeader(String title, BuildContext context) {
  return Container(
    height: 180,
    width: double.infinity,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.green, Color(0xFF1B5E20)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
    ),
    child: SafeArea(
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 50, color: Colors.white),
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
          ),
          Positioned(
            right: 15,
            top: 15,
            child: PopupMenuButton<String>(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              color: Colors.white,
              elevation: 10,
              icon: const Icon(Icons.more_vert, color: Colors.white, size: 30),
              onSelected: (value) => dropDownLogic(value, context),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'editMail',
                  child: ListTile(
                    leading: Icon(Icons.email, color: Colors.green),
                    title: Text('Edit Email'),
                  ),
                ),
                PopupMenuItem(
                  value: 'editPass',
                  child: ListTile(
                    leading: Icon(Icons.lock, color: Colors.green),
                    title: Text('Edit Password'),
                  ),
                ),
                PopupMenuItem(
                  value: 'logOut',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Logout'),
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
