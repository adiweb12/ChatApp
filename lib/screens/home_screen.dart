import 'package:flutter/material.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/functions/functions.dart';
import 'package:onechat/screens/login_page.dart';
import 'package:onechat/screens/bottom_bar.dart';
import 'package:onechat/screens/add_chat_group.dart';
import 'package:onechat/screens/chat_page.dart';
import 'package:onechat/backend/ws_services.dart';
import 'package:onechat/backend/api_services.dart';
import 'package:onechat/themes/theme.dart';
import 'package:onechat/functions/web_functions.dart';

// ─── App Entry ──────────────────────────────────────────────────
class Starter extends StatelessWidget {
  const Starter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "OneChat",
      theme: AppTheme.mainTheme,
      home: isLoggedIn ? const HomeScreen() : const LoginPage(),
    );
  }
}

// ─── Home Screen ────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<_ChatDisplayItem> _chats = [];
  bool _isLoading = true;
  // Map phoneNumber → displayName (resolved once)
  final Map<String, String> _nameCache = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await chatLoader(); // connects WS
    await syncChatsFromServer();
    await _buildNameCache();
    await _loadChats();

    // Real-time: incoming message → refresh list + show alert banner
    WSService().onMessageReceived = (msg) async {
      await _buildNameCache();
      await _loadChats();
      if (mounted) {
        _showNewMessageBanner(msg);
      }
    };
  }

  /// Populate _nameCache from local synced contacts.
  Future<void> _buildNameCache() async {
    if (currentUser == null) return;
    final contacts =
        await getLocalSyncedContacts(currentUser!.phoneNumber);
    for (final c in contacts) {
      _nameCache[c.phoneNumber] = c.userName;
    }
  }

  String _resolveName(String phoneNumber) =>
      _nameCache[phoneNumber] ?? phoneNumber;

  Future<void> _loadChats() async {
    if (currentUser == null) return;
    final raw = await getAllChats(currentUser!.phoneNumber);

    final items = raw.map((c) {
      return _ChatDisplayItem(
        id: c.id,
        name: _resolveName(c.receiverNum),
        phone: c.receiverNum,
        lastMessage: c.lastMessage,
        time: _formatTime(c.time),
        unread: c.unreadCount,
      );
    }).toList();

    if (mounted) {
      setState(() {
        _chats = items;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      if (dt.day == now.day &&
          dt.month == now.month &&
          dt.year == now.year) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  void _showNewMessageBanner(Message msg) {
    final senderName = _resolveName(msg.sender);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: Colors.green.shade800,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(senderName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  Text(
                    msg.message.length > 60
                        ? "${msg.message.substring(0, 60)}…"
                        : msg.message,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "OPEN",
          textColor: Colors.greenAccent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  receiverPhone: msg.sender,
                  receiverName: senderName,
                ),
              ),
            ).then((_) => _loadChats());
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.green))
                : _chats.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: Colors.green,
                        onRefresh: _loadChats,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _chats.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            indent: 72,
                            color: Colors.grey.shade200,
                          ),
                          itemBuilder: (ctx, i) =>
                              _buildChatTile(_chats[i], ctx),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddChatGroupPage()),
        ).then((_) => _loadChats()),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      bottomNavigationBar: const BottomNavigationWidget(),
    );
  }

  // ── Chat Tile ─────────────────────────────────────────────────
  Widget _buildChatTile(_ChatDisplayItem chat, BuildContext ctx) {
    return InkWell(
      onTap: () async {
        await resetUnread(chat.phone);
        if (!mounted) return;
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              receiverPhone: chat.phone,
              receiverName: chat.name,
            ),
          ),
        ).then((_) => _loadChats());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.green.shade100,
              child: Text(
                chat.name.isNotEmpty
                    ? chat.name[0].toUpperCase()
                    : "?",
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          style: TextStyle(
                            fontWeight: chat.unread > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 15.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.time,
                        style: TextStyle(
                          fontSize: 12,
                          color: chat.unread > 0
                              ? Colors.green
                              : Colors.grey,
                          fontWeight: chat.unread > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: chat.unread > 0
                                ? Colors.black87
                                : Colors.grey.shade600,
                            fontWeight: chat.unread > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (chat.unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            chat.unread > 99
                                ? "99+"
                                : chat.unread.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00A86B), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Row(
            children: [
              const Text(
                "OneChat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                color: Colors.white,
                elevation: 8,
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) => dropDownLogic(v, context),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'editMail',
                    child: ListTile(
                      leading: Icon(Icons.email_outlined,
                          color: Colors.green),
                      title: Text('Edit Email'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'editPass',
                    child: ListTile(
                      leading: Icon(Icons.lock_outline,
                          color: Colors.green),
                      title: Text('Edit Password'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logOut',
                    child: ListTile(
                      leading:
                          Icon(Icons.exit_to_app, color: Colors.red),
                      title: Text('Logout',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 90, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Conversations Yet",
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text("Tap the chat button to start",
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// ─── Data class ──────────────────────────────────────────────────
class _ChatDisplayItem {
  final String id;
  final String name;
  final String phone;
  final String lastMessage;
  final String time;
  final int unread;

  const _ChatDisplayItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.lastMessage,
    required this.time,
    required this.unread,
  });
}
