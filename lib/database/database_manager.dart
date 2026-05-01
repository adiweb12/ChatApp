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
    String path = join(await getDatabasesPath(), "onechat_v1.db");
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: (db, version) async {
        // Table 1: User Info
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
        // Table 2: Synced Contacts (Linked to current user)
        await db.execute('''
          CREATE TABLE synedContacts(
            id TEXT,
            currentUserPhone TEXT, 
            userName TEXT,
            phoneNumber TEXT,
            PRIMARY KEY (id, currentUserPhone) 
          )
        ''');
        
        //===TABLE 3 MESSAGES======
        await db.execute('''
            CREATE TABLE messages (
            id TEXT PRIMARY KEY,
            sender TEXT,
            receiver TEXT,
            message TEXT,
            time TEXT,
            type TEXT
            )
        ''');
        
        await db.execute('''
        CREATE TABLE chatList(
        id TEXT,
        currentUserPhone TEXT,
        receiverName TEXT,
        receiverNum TEXT,
        lastMessage TEXT,
        time TEXT,
        PRIMARY KEY (id, currentUserPhone)
        )
        ''');
    
      },
    );
  }
}
final dbMaker = DBmaker();
