import 'dart:convert';
import 'package:onechat/constant/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:onechat/models/models.dart';
import 'package:uuid/uuid.dart';
import 'package:onechat/backend/ws_services.dart';


class ChatPage extends StatefulWidget {
  final String receiverPhone;
  final String receiverName;

  const ChatPage({
    super.key,
    required this.receiverPhone,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Message> messages = [];

  @override
  void initState() {
    super.initState();
    loadMessages();

    // ✅ Real-time listener
    WSService().onMessageReceived = (msg) {
      if (msg.sender == widget.receiverPhone) {
        setState(() {
          messages.insert(0, msg);
        });
        _scrollToTop();
      }
    };
  }

  // ================= LOAD OLD =================
  Future<void> loadMessages() async {
    final data = await getMessages(
      currentUser!.phoneNumber,
      widget.receiverPhone,
    );

    setState(() {
      messages = data;
    });
  }

  // ================= SEND =================
  void sendMessage() async {
    if (controller.text.trim().isEmpty) return;

    final text = controller.text.trim();
    controller.clear();

    final msg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: currentUser!.phoneNumber,
      receiver: widget.receiverPhone,
      message: text,
      time: DateTime.now().toIso8601String(),
      type: "text",
      isMe: true,
    );

    // UI update
    setState(() {
      messages.insert(0, msg);
    });

    _scrollToTop();

    // DB
    await insertMessage(msg);

    await addNewChat(ChatList(
      id: widget.receiverPhone,
      receiverName: widget.receiverName,
      receiverNum: widget.receiverPhone,
      lastMessage: text,
      time: msg.time,
    ));

    // WS
    WSService().sendMessage(msg);
  }

  void _scrollToTop() {
    Future.delayed(const Duration(milliseconds: 100), () {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),

      // ✅ TOP BAR
      appBar: AppBar(
        backgroundColor: Colors.green,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(widget.receiverName[0]),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName,
                    style: const TextStyle(fontSize: 16)),
                const Text("Online",
                    style: TextStyle(fontSize: 12)),
              ],
            )
          ],
        ),
      ),

      body: Column(
        children: [
          // ✅ MESSAGE LIST
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessageBubble(messages[index]);
              },
            ),
          ),

          // ✅ INPUT BAR
          buildInputBar(),
        ],
      ),
    );
  }

  // ================= MESSAGE UI =================
  Widget buildMessageBubble(Message msg) {
    return Align(
      alignment:
          msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: msg.isMe ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft:
                msg.isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                msg.isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              msg.message,
              style: TextStyle(
                color: msg.isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              msg.time.substring(11, 16),
              style: TextStyle(
                fontSize: 11,
                color: msg.isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= INPUT BAR =================
  Widget buildInputBar() {
    return SafeArea(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              color: Colors.black12,
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: sendMessage,
              ),
            )
          ],
        ),
      ),
    );
  }
}
