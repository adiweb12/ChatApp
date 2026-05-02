import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/constant/api_urls.dart';
import 'package:onechat/backend/api_services.dart';

class WSService {
  static final WSService _instance = WSService._internal();
  factory WSService() => _instance;

  WSService._internal();

  WebSocketChannel? _channel;

  Function(Message msg)? onMessageReceived;

  Future<void> connect(String myPhone) async{
    _channel = WebSocketChannel.connect(
      Uri.parse(webSocketIp),
    );

    // REGISTER USER
    _channel!.sink.add(jsonEncode({
      "type": "register",
      "token": await getToken(),
    }));

    // LISTEN
    _channel!.stream.listen((data) async {
  final json = jsonDecode(data);

  Message msg = Message(
    id: json["id"],
    sender: json["from"],
    receiver: json["to"],
    message: json["message"],
    time: json["time"],
    type: "text",
    isMe: false,
  );

  // CRITICAL: Await the database save before triggering the callback
  await insertMessage(msg);

  // Update the chat list so the home screen shows the latest snippet
  await addNewChat(ChatList(
    id: msg.sender,
    receiverName: msg.sender, // The Home Screen mapping logic above will fix this name
    receiverNum: msg.sender,
    lastMessage: msg.message,
    time: msg.time,
  ));

  // Trigger UI update
  if (onMessageReceived != null) {
    onMessageReceived!(msg);
  }
});

  }

  Future<void> sendMessage(Message msg) async{

  final token = await getToken();
    _channel?.sink.add(jsonEncode({
      "type": "message",
       "token": token,
      "id": msg.id,
      "from": msg.sender,
      "to": msg.receiver,
      "message": msg.message,
    }));
  }

  void disconnect() {
    _channel?.sink.close();
  }
}
