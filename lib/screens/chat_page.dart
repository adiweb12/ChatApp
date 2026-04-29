import 'dart:convert';
import 'package:onechat/constant/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onechat/models/models.dart';

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
  late WebSocketChannel channel;
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();

    channel = WebSocketChannel.connect(
      Uri.parse("$webSocketIp"),
    );

    // Register user
    channel.sink.add(jsonEncode({
      "type": "register",
      "from": currentUser!.phoneNumber,
    }));

    // Listen messages
    channel.stream.listen((data) {
      final msg = jsonDecode(data);

      setState(() {
        messages.insert(0, {
          "text": msg["message"],
          "isMe": msg["from"] == currentUser!.phoneNumber,
          "time": TimeOfDay.now().format(context),
        });
      });
    });
  }

  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    final msg = controller.text.trim();

    channel.sink.add(jsonEncode({
      "type": "message",
      "from": currentUser!.phoneNumber,
      "to": widget.receiverPhone,
      "message": msg,
    }));

    setState(() {
      messages.insert(0, {
        "text": msg,
        "isMe": true,
        "time": TimeOfDay.now().format(context),
      });
    });

    controller.clear();
  }

  @override
  void dispose() {
    channel.sink.close();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // ================= UI =================

  Widget buildMessageBubble(Map<String, dynamic> msg) {
    bool isMe = msg["isMe"];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.green : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg["text"],
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              msg["time"],
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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

  Widget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.green,
      elevation: 1,
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
              Text(
                widget.receiverName,
                style: const TextStyle(fontSize: 16),
              ),
              const Text(
                "Online",
                style: TextStyle(fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      backgroundColor: const Color(0xFFECE5DD), // WhatsApp style bg
      body: Column(
        children: [
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
          buildInputBar(),
        ],
      ),
    );
  }
}
