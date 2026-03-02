import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String receiverPhone;
  final String receiverName;

  const ChatPage({super.key, required this.receiverPhone, required this.receiverName});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  late IOWebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket (Replace with your IP)
    _channel = IOWebSocketChannel.connect('ws://YOUR_IP:5000');
    
    // Join your own room to listen for messages
    _channel.sink.add(jsonEncode({
      'event': 'join',
      'data': {'phone': currentUser!.phoneNumber}
    }));

    // Listen for incoming messages
    _channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['sender_phone'] == widget.receiverPhone) {
        setState(() => _messages.add(data));
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;
    
    final msgData = {
      'sender_phone': currentUser!.phoneNumber,
      'receiver_phone': widget.receiverPhone,
      'message': _messageController.text,
      'time': DateTime.now().toString(),
    };

    _channel.sink.add(jsonEncode({'event': 'send_message', 'data': msgData}));
    setState(() => _messages.add(msgData));
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.receiverName), backgroundColor: Colors.green),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isMe = _messages[index]['sender_phone'] == currentUser!.phoneNumber;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.green[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_messages[index]['message']),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _messageController)),
                IconButton(icon: const Icon(Icons.send, color: Colors.green), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
