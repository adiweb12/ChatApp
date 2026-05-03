import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBmaker {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String path = join(await getDatabasesPath(), "onechat_v2.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // ── UserData ──
        await db.execute('''
          CREATE TABLE UserData(
            id TEXT PRIMARY KEY,
            userName TEXT,
            email TEXT,
            phoneNumber TEXT,
            password TEXT,
            dob TEXT
          )
        ''');

        // ── Synced Contacts ──
        await db.execute('''
          CREATE TABLE synedContacts(
            id TEXT,
            currentUserPhone TEXT,
            userName TEXT,
            phoneNumber TEXT,
            PRIMARY KEY (id, currentUserPhone)
          )
        ''');

        // ── Messages (+ status column) ──
        await db.execute('''
          CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            sender TEXT,
            receiver TEXT,
            message TEXT,
            time TEXT,
            type TEXT,
            status TEXT DEFAULT 'sent',
            currentUserPhone TEXT
          )
        ''');

        // ── Chat List (+ unreadCount) ──
        await db.execute('''
          CREATE TABLE chatList(
            id TEXT,
            currentUserPhone TEXT,
            receiverName TEXT,
            receiverNum TEXT,
            lastMessage TEXT,
            time TEXT,
            unreadCount INTEGER DEFAULT 0,
            PRIMARY KEY (id, currentUserPhone)
          )
        ''');
      },
    );
  }
}

final dbMaker = DBmaker();
