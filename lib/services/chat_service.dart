import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'].toString(),
        senderId: json['sender_id'].toString(),
        receiverId: json['receiver_id'].toString(),
        content: json['content'],
        timestamp: DateTime.parse(json['timestamp']),
        isRead: json['is_read'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'is_read': isRead,
      };
}

class ChatPreview {
  final String userId;
  final String name;
  final String phone;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;

  ChatPreview({
    required this.userId,
    required this.name,
    required this.phone,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
  });

  factory ChatPreview.fromJson(Map<String, dynamic> json) => ChatPreview(
        userId: json['user_id'].toString(),
        name: json['name'] ?? json['phone'],
        phone: json['phone'],
        lastMessage: json['last_message'] ?? '',
        lastTime: DateTime.parse(json['last_time']),
        unreadCount: json['unread_count'] ?? 0,
      );
}

class ChatService extends ChangeNotifier {
  static const String baseUrl = 'http://10.0.2.2:5000';

  List<ChatPreview> _chats = [];
  List<Message> _currentMessages = [];
  bool _isLoading = false;

  List<ChatPreview> get chats => _chats;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;

  Future<void> loadChats() async {
    _isLoading = true;
    notifyListeners();
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.get(Uri.parse('$baseUrl/chat/list'), headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _chats = (data['chats'] as List).map((c) => ChatPreview.fromJson(c)).toList();
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages(String otherUserId) async {
    final box = Hive.box('messages');
    final cached = box.get('chat_$otherUserId');
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      _currentMessages = list.map((m) => Message.fromJson(m)).toList();
      notifyListeners();
    }
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.get(
        Uri.parse('$baseUrl/chat/messages/$otherUserId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentMessages = (data['messages'] as List).map((m) => Message.fromJson(m)).toList();
        await box.put('chat_$otherUserId', jsonEncode(data['messages']));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> sendMessage(String receiverId, String content) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/chat/send'),
        headers: headers,
        body: jsonEncode({'receiver_id': receiverId, 'content': content}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearChat(String otherUserId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/chat/clear/$otherUserId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        _currentMessages = [];
        final box = Hive.box('messages');
        await box.delete('chat_$otherUserId');
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteChat(String otherUserId) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.delete(
        Uri.parse('$baseUrl/chat/delete/$otherUserId'),
        headers: headers,
      );
      if (res.statusCode == 200) {
        _chats.removeWhere((c) => c.userId == otherUserId);
        final box = Hive.box('messages');
        await box.delete('chat_$otherUserId');
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>> checkContacts(List<String> phones) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/contacts/check'),
        headers: headers,
        body: jsonEncode({'phones': phones}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return List<Map<String, dynamic>>.from(data['contacts']);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> createGroup(String name, List<String> memberIds) async {
    try {
      final headers = await AuthService.getAuthHeaders();
      final res = await http.post(
        Uri.parse('$baseUrl/group/create'),
        headers: headers,
        body: jsonEncode({'name': name, 'members': memberIds}),
      );
      return jsonDecode(res.body);
    } catch (_) {
      return {'success': false};
    }
  }
}
