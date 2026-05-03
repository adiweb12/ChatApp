import 'dart:async';
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
  Timer? _pingTimer;
  bool _connected = false;

  // Callbacks
  Function(Message msg)? onMessageReceived;
  Function(String msgId, MessageStatus status)? onStatusUpdate;

  // ── Connect ───────────────────────────────────────────────────
  Future<void> connect(String myPhone) async {
    if (_connected) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(webSocketIp));

      // Register with JWT
      final token = await getToken();
      _channel!.sink.add(jsonEncode({
        "type": "register",
        "token": token,
      }));

      _connected = true;

      // Keep-alive ping every 30 s
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        _channel?.sink.add(jsonEncode({"type": "ping"}));
      });

      _channel!.stream.listen(
        _onData,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
      );
    } catch (e) {
      _connected = false;
    }
  }

  // ── Handle incoming data ──────────────────────────────────────
  Future<void> _onData(dynamic raw) async {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = json["type"] as String? ?? "message";

      // ── STATUS UPDATE (delivered / read) ──
      if (type == "status") {
        final msgId = json["id"] as String;
        final status = _statusFromString(json["status"] as String);
        await updateMessageStatus(msgId, status);
        onStatusUpdate?.call(msgId, status);
        return;
      }

      // ── INCOMING MESSAGE ──
      if (type == "message" || type == null) {
        final msg = Message(
          id: json["id"] as String,
          sender: json["from"] as String,
          receiver: json["to"] as String,
          message: json["message"] as String,
          time: json["time"] as String,
          type: _detectType(json["message"] as String),
          isMe: false,
          status: MessageStatus.delivered, // receiver got it → delivered
        );

        await insertMessage(msg);
        await addNewChat(ChatList(
          id: msg.sender,
          receiverName: msg.sender,
          receiverNum: msg.sender,
          lastMessage: msg.message,
          time: msg.time,
          unreadCount: 1,
        ));
        await incrementUnread(msg.sender);

        // Tell sender: delivered
        _sendStatus(msg.id, msg.sender, "delivered");

        onMessageReceived?.call(msg);
      }
    } catch (_) {}
  }

  // ── Send a chat message ───────────────────────────────────────
  Future<void> sendMessage(Message msg) async {
    final token = await getToken();
    _channel?.sink.add(jsonEncode({
      "type": "message",
      "token": token,
      "id": msg.id,
      "from": msg.sender,
      "to": msg.receiver,
      "message": msg.message,
      "msgType": msg.type,
    }));
  }

  // ── Tell sender that we read their message ────────────────────
  void sendReadReceipt(String msgId, String toPhone) {
    _sendStatus(msgId, toPhone, "read");
  }

  void _sendStatus(String msgId, String toPhone, String status) {
    _channel?.sink.add(jsonEncode({
      "type": "status",
      "id": msgId,
      "to": toPhone,
      "status": status,
    }));
  }

  // ── Reconnect on disconnect ───────────────────────────────────
  void _onDisconnect() {
    _connected = false;
    _pingTimer?.cancel();
    Future.delayed(const Duration(seconds: 5), () {
      if (currentUser != null) connect(currentUser!.phoneNumber);
    });
  }

  void disconnect() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    _connected = false;
  }

  // ── Helpers ───────────────────────────────────────────────────
  String _detectType(String text) {
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    return urlRegex.hasMatch(text) ? "link" : "text";
  }

  MessageStatus _statusFromString(String s) {
    switch (s) {
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      default:
        return MessageStatus.sent;
    }
  }
}
