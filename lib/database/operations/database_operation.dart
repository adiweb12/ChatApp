import 'package:sqflite/sqflite.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:onechat/models/models.dart';

// ================================================================
//  USER OPERATIONS
// ================================================================

Future<bool> insertUser(UserDetails user) async {
  try {
    final db = await dbMaker.db;
    await db.insert(
      "UserData",
      {
        'id': user.id,
        'userName': user.userName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'password': user.password,
        'dob': user.dob,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Future<UserDetails?> getUser(String email, String password) async {
  final db = await dbMaker.db;
  final maps = await db.query(
    "UserData",
    where: "email = ? AND password = ?",
    whereArgs: [email, password],
  );
  if (maps.isNotEmpty) {
    return _mapToUser(maps[0]);
  }
  return null;
}

Future<List<UserDetails>> getAllUsers() async {
  final db = await dbMaker.db;
  final maps = await db.query("UserData");
  return maps.map(_mapToUser).toList();
}

Future<bool> updateEmailDataBase(String phoneNumber, String newEmail) async {
  try {
    final db = await dbMaker.db;
    final count = await db.update(
      "UserData",
      {'email': newEmail},
      where: "phoneNumber = ?",
      whereArgs: [phoneNumber],
    );
    return count > 0;
  } catch (_) {
    return false;
  }
}

Future<bool> updatePassDataBase(String email, String newPassword) async {
  try {
    final db = await dbMaker.db;
    final count = await db.update(
      "UserData",
      {'password': newPassword},
      where: "email = ?",
      whereArgs: [email],
    );
    return count > 0;
  } catch (_) {
    return false;
  }
}

UserDetails _mapToUser(Map<String, dynamic> m) => UserDetails(
      id: m['id'],
      userName: m['userName'],
      email: m['email'],
      phoneNumber: m['phoneNumber'],
      password: m['password'],
      dob: m['dob'],
    );

// ================================================================
//  SYNCED CONTACTS
// ================================================================

Future<bool> insertSyncedContact(SyncedContact contact) async {
  try {
    final db = await dbMaker.db;
    await db.insert(
      "synedContacts",
      {
        'id': contact.id,
        'currentUserPhone': contact.currentUserPhone,
        'userName': contact.userName,
        'phoneNumber': contact.phoneNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  } catch (_) {
    return false;
  }
}

Future<List<SyncedContact>> getLocalSyncedContacts(
    String currentUserPhone) async {
  final db = await dbMaker.db;
  final maps = await db.query(
    "synedContacts",
    where: "currentUserPhone = ?",
    whereArgs: [currentUserPhone],
  );
  return maps
      .map((m) => SyncedContact(
            id: m['id'] as String,
            currentUserPhone: m['currentUserPhone'] as String,
            userName: m['userName'] as String,
            phoneNumber: m['phoneNumber'] as String,
          ))
      .toList();
}

// ================================================================
//  MESSAGES
// ================================================================

Future<void> insertMessage(Message msg) async {
  final db = await dbMaker.db;
  await db.insert(
    "messages",
    {
      ...msg.toMap(),
      "currentUserPhone": currentUser!.phoneNumber,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

/// Update the delivery/read status of a single message.
Future<void> updateMessageStatus(String msgId, MessageStatus status) async {
  final db = await dbMaker.db;
  await db.update(
    "messages",
    {'status': status.name},
    where: "id = ?",
    whereArgs: [msgId],
  );
}

/// Mark all messages from [senderPhone] as read.
Future<void> markAllAsRead(String senderPhone) async {
  final db = await dbMaker.db;
  await db.update(
    "messages",
    {'status': MessageStatus.read.name},
    where:
        "sender = ? AND currentUserPhone = ? AND status != ?",
    whereArgs: [
      senderPhone,
      currentUser!.phoneNumber,
      MessageStatus.read.name,
    ],
  );
}

Future<List<Message>> getMessages(
    String myPhone, String otherPhone) async {
  final db = await dbMaker.db;
  final result = await db.query(
    "messages",
    where:
        "currentUserPhone=? AND ((sender=? AND receiver=?) OR (sender=? AND receiver=?))",
    whereArgs: [myPhone, myPhone, otherPhone, otherPhone, myPhone],
    orderBy: "time DESC",
  );
  return result
      .map((e) => Message(
            id: e["id"] as String,
            sender: e["sender"] as String,
            receiver: e["receiver"] as String,
            message: e["message"] as String,
            time: e["time"] as String,
            type: e["type"] as String,
            isMe: e["sender"] == myPhone,
            status: _statusFromString(e["status"] as String? ?? 'sent'),
          ))
      .toList();
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

// ================================================================
//  CHAT LIST
// ================================================================

Future<bool> addNewChat(ChatList ctl) async {
  try {
    final db = await dbMaker.db;
    await db.insert(
      "chatList",
      {
        'id': ctl.id,
        'currentUserPhone': currentUser!.phoneNumber,
        'receiverName': ctl.receiverName,
        'receiverNum': ctl.receiverNum,
        'lastMessage': ctl.lastMessage,
        'time': ctl.time,
        'unreadCount': ctl.unreadCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  } catch (_) {
    return false;
  }
}

/// Increment unread count for [receiverNum] (called on incoming message).
Future<void> incrementUnread(String receiverNum) async {
  final db = await dbMaker.db;
  await db.rawUpdate(
    "UPDATE chatList SET unreadCount = unreadCount + 1 WHERE id = ? AND currentUserPhone = ?",
    [receiverNum, currentUser!.phoneNumber],
  );
}

/// Reset unread count to 0 when user opens the chat.
Future<void> resetUnread(String receiverNum) async {
  final db = await dbMaker.db;
  await db.update(
    "chatList",
    {'unreadCount': 0},
    where: "id = ? AND currentUserPhone = ?",
    whereArgs: [receiverNum, currentUser!.phoneNumber],
  );
}

Future<List<ChatList>> getAllChats(String myPhone) async {
  final db = await dbMaker.db;
  final maps = await db.query(
    "chatList",
    where: "currentUserPhone = ?",
    whereArgs: [myPhone],
    orderBy: "time DESC",
  );
  return maps
      .map((m) => ChatList(
            id: m['id'] as String,
            receiverName: m['receiverName'] as String,
            receiverNum: m['receiverNum'] as String,
            lastMessage: m['lastMessage'] as String,
            time: m['time'] as String,
            unreadCount: (m['unreadCount'] as int?) ?? 0,
          ))
      .toList();
}
