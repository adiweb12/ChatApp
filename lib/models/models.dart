// ====================== USER MODEL ======================
class UserDetails {
  final String id;
  final String userName;
  String phoneNumber;
  String email;
  String password;
  final String dob;

  UserDetails({
    required this.id,
    required this.userName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.dob,
  });
}

// ====================== SYNCED CONTACT ======================
class SyncedContact {
  final String id;
  final String currentUserPhone;
  final String userName;
  final String phoneNumber;

  SyncedContact({
    required this.id,
    required this.currentUserPhone,
    required this.userName,
    required this.phoneNumber,
  });
}

// ====================== MESSAGE STATUS ======================
// sent    → stored locally, sent over WS
// delivered → receiver's device got it
// read    → receiver opened the chat
enum MessageStatus { sent, delivered, read }

// ====================== MESSAGE MODEL ======================
class Message {
  final String id;
  final String sender;
  final String receiver;
  final String message;
  final String time;
  final String type; // "text" | "link"
  final bool isMe;
  MessageStatus status;

  Message({
    required this.id,
    required this.sender,
    required this.receiver,
    required this.message,
    required this.time,
    required this.type,
    required this.isMe,
    this.status = MessageStatus.sent,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "sender": sender,
      "receiver": receiver,
      "message": message,
      "time": time,
      "type": type,
      "status": status.name,
    };
  }

  Message copyWith({MessageStatus? status}) {
    return Message(
      id: id,
      sender: sender,
      receiver: receiver,
      message: message,
      time: time,
      type: type,
      isMe: isMe,
      status: status ?? this.status,
    );
  }
}

// ====================== CHAT LIST MODEL ======================
class ChatList {
  final String id;
  final String receiverName;
  final String receiverNum;
  final String time;
  final String lastMessage;
  int unreadCount;

  ChatList({
    required this.id,
    required this.receiverName,
    required this.receiverNum,
    required this.time,
    required this.lastMessage,
    this.unreadCount = 0,
  });
}

// ====================== GLOBALS ======================
bool isLoggedIn = false;
UserDetails? currentUser;
List<UserDetails> globalUserList = []; // kept for backward compatibility
