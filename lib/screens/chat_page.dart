import 'dart:convert';
import 'package:onechat/constant/api_urls.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:onechat/models/models.dart';
import 'package:uuid/uuid.dart';

final uuid = Uuid();

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

  List<Map<String, dynamic>> messages = [];
  
  late WebSocketChannel channel;
bool isConnected = false;

@override
void initState() {
  super.initState();
  _loadMessages();

  // ✅ create ONLY ONCE
  channel = WebSocketChannel.connect(Uri.parse(webSocketIp));

  channel.sink.add(jsonEncode({
    "type": "register",
    "from": currentUser!.phoneNumber,
  }));
  channel.stream.listen((data) async {
  if (!mounted) return;

  final msg = jsonDecode(data);
  if (msg["from"] == currentUser!.phoneNumber) return;

  // ✅ Define the missing newMsg variable here
  Message newMsg = Message(
    id: msg["id"] ?? const Uuid().v4(),
    sender: msg["from"],
    receiver: msg["to"],
    message: msg["message"],
    time: msg["time"] ?? DateTime.now().toIso8601String(),
    type: "text",
    isMe: false,
  );

  await insertMessage(newMsg);

  if (mounted) {
    setState(() {
      messages.insert(0, {
        "text": newMsg.message,
        "isMe": false,
        "time": TimeOfDay.fromDateTime(
          DateTime.parse(newMsg.time),
        ).format(context),
      });
    });
  }
});
 
}

void _loadMessages() async {
  final msgs = await getMessages(
    currentUser!.phoneNumber,
    widget.receiverPhone,
  );

  setState(() {
    messages = msgs.map((m) => {
      "text": m.message,
      "isMe": m.isMe,
      "time": TimeOfDay.fromDateTime(DateTime.parse(m.time)).format(context),
    }).toList();
  });

  await Future.delayed(const Duration(milliseconds: 100));
  scrollController.jumpTo(0);
}
 void sendMessage() async {
  if (controller.text.trim().isEmpty) return;

  final msgText = controller.text.trim();

  Message msg = Message(
    id: const Uuid().v4(),
    sender: currentUser!.phoneNumber,
    receiver: widget.receiverPhone,
    message: msgText,
    time: DateTime.now().toIso8601String(),
    type: "text",
    isMe: true,
  );

  controller.clear();

// ✅ show instantly
setState(() {
  messages.insert(0, {
    "text": msg.message,
    "isMe": true,
    "time": TimeOfDay.now().format(context),
  });
});

// ✅ save
await insertMessage(msg);

// ✅ send
channel.sink.add(jsonEncode({
  "id": msg.id,
  "type": "message",
  "from": msg.sender,
  "to": msg.receiver,
  "message": msg.message,
}));
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
    appBar: PreferredSize(
     preferredSize: const Size.fromHeight(60), // Set your desired height
  child: buildAppBar(),
),
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
