import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBmaker {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  initDb() async {
    String path = join(await getDatabasesPath(), "onechat_user_info_bycrypt12.db");
    return await openDatabase(path, version: 1, onCreate: (db, version) async {
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
    });
  }
}

// Create a global instance to use in operations
final dbMaker = DBmaker();
