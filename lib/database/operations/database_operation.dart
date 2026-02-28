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
