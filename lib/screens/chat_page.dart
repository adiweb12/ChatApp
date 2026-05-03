import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:onechat/constant/api_urls.dart';
import 'package:onechat/models/models.dart';
import 'package:onechat/database/operations/database_operation.dart';
import 'package:onechat/backend/ws_services.dart';
import 'package:uuid/uuid.dart';

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
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Message> _messages = [];
  bool _isLoading = true;

  // URL regex
  static final _urlRegex = RegExp(
    r'(https?://[^\s]+)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupWS();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupWS() {
    WSService().onMessageReceived = (msg) {
      if (msg.sender == widget.receiverPhone ||
          msg.receiver == widget.receiverPhone) {
        if (mounted) {
          setState(() {
            if (!_messages.any((m) => m.id == msg.id)) {
              _messages.insert(0, msg);
            }
          });
          _scrollToBottom();
          // Send read receipt
          WSService().sendReadReceipt(msg.id, msg.sender);
        }
      }
    };

    WSService().onStatusUpdate = (msgId, status) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msgId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(status: status);
          }
        });
      }
    };
  }

  Future<void> _loadMessages() async {
    final data = await getMessages(
      currentUser!.phoneNumber,
      widget.receiverPhone,
    );

    // Mark incoming messages as read
    await markAllAsRead(widget.receiverPhone);
    await resetUnread(widget.receiverPhone);

    // Send read receipts for unread messages
    for (final m in data.where((m) => !m.isMe && m.status != MessageStatus.read)) {
      WSService().sendReadReceipt(m.id, m.sender);
    }

    if (mounted) {
      setState(() {
        _messages = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    final msgType = _urlRegex.hasMatch(text) ? "link" : "text";

    final msg = Message(
      id: const Uuid().v4(),
      sender: currentUser!.phoneNumber,
      receiver: widget.receiverPhone,
      message: text,
      time: DateTime.now().toIso8601String(),
      type: msgType,
      isMe: true,
      status: MessageStatus.sent,
    );

    setState(() => _messages.insert(0, msg));
    _scrollToBottom();

    await insertMessage(msg);
    await addNewChat(ChatList(
      id: widget.receiverPhone,
      receiverName: widget.receiverName,
      receiverNum: widget.receiverPhone,
      lastMessage: text,
      time: msg.time,
    ));
    WSService().sendMessage(msg);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── BUILD ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 8),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _buildBubble(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF075E54),
      titleSpacing: 0,
      leading: BackButton(
        color: Colors.white,
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            child: Text(
              widget.receiverName.isNotEmpty
                  ? widget.receiverName[0].toUpperCase()
                  : "?",
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.receiverName,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
              const Text(
                "tap here for contact info",
                style: TextStyle(fontSize: 11, color: Colors.white60),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  // ── Message Bubble ───────────────────────────────────────────

  Widget _buildBubble(Message msg) {
    return Align(
      alignment:
          msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: msg.isMe
              ? const Color(0xFFDCF8C6) // WhatsApp green tint for sent
              : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: msg.isMe
                ? const Radius.circular(16)
                : const Radius.circular(2),
            bottomRight: msg.isMe
                ? const Radius.circular(2)
                : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: msg.isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Message content (text or link)
            msg.type == "link"
                ? _buildLinkText(msg.message)
                : SelectableText(
                    msg.message,
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 15.5, height: 1.3),
                  ),
            const SizedBox(height: 4),
            // Time + status ticks
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.time),
                  style: const TextStyle(
                      fontSize: 11, color: Colors.black45),
                ),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  _buildStatusTick(msg.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// WhatsApp-style single / double / blue ticks
  Widget _buildStatusTick(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.check,
            size: 15, color: Colors.black38);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all,
            size: 15, color: Colors.black38);
      case MessageStatus.read:
        return const Icon(Icons.done_all,
            size: 15, color: Color(0xFF34B7F1)); // blue
    }
  }

  /// Renders text with clickable hyperlinks
  Widget _buildLinkText(String text) {
    final spans = <InlineSpan>[];
    int last = 0;
    for (final match in _urlRegex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
          text: text.substring(last, match.start),
          style: const TextStyle(
              color: Colors.black87, fontSize: 15.5),
        ));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: const TextStyle(
          color: Color(0xFF0057D9),
          fontSize: 15.5,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) launchUrl(uri);
          },
      ));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
        text: text.substring(last),
        style: const TextStyle(color: Colors.black87, fontSize: 15.5),
      ));
    }
    return RichText(text: TextSpan(children: spans));
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            "Messages are end-to-end secured",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ────────────────────────────────────────────────

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        color: const Color(0xFFECE5DD),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4)
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: 5,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: "Message",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file,
                          color: Colors.grey),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A86B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
