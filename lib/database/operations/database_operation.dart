import 'package:sqflite/sqflite.dart';
import 'package:onechat/database/database_manager.dart';
import 'package:onechat/models/models.dart';

Future<bool> insertUser(UserDetails user) async {
  try {
    final dbClient = await dbMaker.db; // Use the instance
    await dbClient.insert(
      "UserData",
      {
        'id': user.id, // Fixed: Added quotes
        'userName': user.userName,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'password': user.password,
        'dob': user.dob,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true; // Added missing return
  } catch (e) {
    return false;
  }
}

Future<UserDetails?> getUser(String email, String password) async {
  final dbClient = await dbMaker.db;
  List<Map<String, dynamic>> maps = await dbClient.query(
    "UserData",
    where: "email = ? AND password = ?",
    whereArgs: [email, password],
  );
  if (maps.isNotEmpty) {
    return UserDetails(
      id: maps[0]['id'],
      userName: maps[0]['userName'],
      email: maps[0]['email'],
      phoneNumber: maps[0]['phoneNumber'],
      password: maps[0]['password'],
      dob: maps[0]['dob'],
    );
  }
  return null;
}

Future<List<UserDetails>> getAllUsers() async {
  final dbClient = await dbMaker.db;

  final List<Map<String, dynamic>> maps =
      await dbClient.query("UserData");

  return List.generate(maps.length, (i) {
    return UserDetails(
      id: maps[i]['id'],
      userName: maps[i]['userName'],
      email: maps[i]['email'],
      phoneNumber: maps[i]['phoneNumber'],
      password: maps[i]['password'],
      dob: maps[i]['dob'],
    );
  });
}

Future<bool> updatePassDataBase(String email, String newPassword) async {
  try {
    final dbClient = await dbMaker.db;
    int count = await dbClient.update(
      "UserData",
      {'password': newPassword}, // The column to update
      where: "email = ?",        // The condition
      whereArgs: [email],
    );
    return count > 0; // Returns true if a row was updated
  } catch (e) {
    return false;
  }
}


Future<bool> updateEmailDataBase(String phonenumber, String newEmail) async {
  try {
    final dbClient = await dbMaker.db;
    int count = await dbClient.update(
      "UserData",
      {'email': newEmail},
      where: "phoneNumber = ?",
      whereArgs: [phonenumber],
    );
    return count > 0;
  } catch (e) {
    return false;
  }
}

Future<bool> insertSyncedContact(SyncedContact contact) async {
  try {
    final dbClient = await dbMaker.db;
    await dbClient.insert(
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
  } catch (e) {
    return false;
  }
}

// Fetch only contacts belonging to the logged-in user
Future<List<SyncedContact>> getLocalSyncedContacts(String currentUserPhone) async {
  final dbClient = await dbMaker.db;
  final List<Map<String, dynamic>> maps = await dbClient.query(
    "synedContacts",
    where: "currentUserPhone = ?",
    whereArgs: [currentUserPhone],
  );

  return List.generate(maps.length, (i) {
    return SyncedContact(
      id: maps[i]['id'],
      currentUserPhone: maps[i]['currentUserPhone'],
      userName: maps[i]['userName'],
      phoneNumber: maps[i]['phoneNumber'],
    );
  });
}

Future<void> insertMessage(Message msg) async {
  final dbClient = await dbMaker.db;

  await dbClient.insert(
    "messages",
    msg.toMap(),
    conflictAlgorithm: ConflictAlgorithm.ignore, // ✅ IMPORTANT
  );
}

Future<List<Message>> getMessages(String myPhone, String otherPhone) async {
  final dbClient = await dbMaker.db;

  final result = await dbClient.query(
    "messages",
    where: "(sender=? AND receiver=?) OR (sender=? AND receiver=?)",
    whereArgs: [myPhone, otherPhone, otherPhone, myPhone],
    orderBy: "time DESC",
  );

  return result.map((e) => Message(
    id: e["id"] as String,
    sender: e["sender"] as String,
    receiver: e["receiver"] as String,
    message: e["message"] as String,
    time: e["time"] as String,
    type: e["type"] as String,
    isMe: e["sender"] == myPhone,
  )).toList();
}

Future<List<Map<String, dynamic>>> getChatList(String myPhone) async {
  final dbClient = await dbMaker.db;

  final result = await dbClient.rawQuery("""
    SELECT 
      CASE 
        WHEN m.sender = ? THEN m.receiver 
        ELSE m.sender 
      END as user,
      sc.userName as name,
      m.message,
      MAX(m.time) as lastTime
    FROM messages m
    LEFT JOIN synedContacts sc
      ON sc.phoneNumber = (
        CASE 
          WHEN m.sender = ? THEN m.receiver 
          ELSE m.sender 
        END
      )
      AND sc.currentUserPhone = ?
    WHERE m.sender = ? OR m.receiver = ?
    GROUP BY user
    ORDER BY lastTime DESC
  """, [myPhone, myPhone, myPhone, myPhone, myPhone]);

  return result;
}
