import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/note_model.dart';
import '../models/user_model.dart';

class DBHelper {
  static Database? _database;

  static const String userTable = 'users';
  static const String noteTable = 'notes';

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await initDB();
    return _database!;
  }

  static Future<Database> initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'uas_my_notes.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $userTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $noteTable(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            category TEXT NOT NULL,
            isPinned INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _createUsersTableIfNotExists(db);
        await _createNotesTableIfNotExists(db);

        await _addColumnIfNotExists(
          db,
          noteTable,
          'isPinned',
          'INTEGER NOT NULL DEFAULT 0',
        );
      },
      onOpen: (db) async {
        await _createUsersTableIfNotExists(db);
        await _createNotesTableIfNotExists(db);

        await _addColumnIfNotExists(
          db,
          noteTable,
          'isPinned',
          'INTEGER NOT NULL DEFAULT 0',
        );
      },
    );
  }

  static Future<void> _createUsersTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $userTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createNotesTableIfNotExists(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $noteTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        isPinned INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  static Future<void> _addColumnIfNotExists(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final result = await db.rawQuery('PRAGMA table_info($table)');

    final columnExists = result.any((row) => row['name'] == column);

    if (!columnExists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  // =========================
  // USER / REGISTER / LOGIN
  // =========================

  static Future<int> insertUser(UserModel user) async {
    final db = await database;

    return await db.insert(
      userTable,
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  static Future<int> registerUser(UserModel user) async {
    return await insertUser(user);
  }

  static Future<UserModel?> loginUser(
    String username,
    String password,
  ) async {
    final db = await database;

    final result = await db.query(
      userTable,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return UserModel.fromMap(result.first);
    }

    return null;
  }

  static Future<bool> checkUsernameExists(String username) async {
    final db = await database;

    final result = await db.query(
      userTable,
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<List<UserModel>> getUsers() async {
    final db = await database;

    final result = await db.query(userTable);

    return result.map((map) => UserModel.fromMap(map)).toList();
  }

  // =========================
  // NOTES
  // =========================

  static Future<int> insertNote(Note note) async {
    final db = await database;

    return await db.insert(
      noteTable,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Note>> getNotes() async {
    final db = await database;

    final result = await db.query(
      noteTable,
      orderBy: 'id DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  static Future<int> updateNote(Note note) async {
    final db = await database;

    return await db.update(
      noteTable,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  static Future<int> deleteNote(int id) async {
    final db = await database;

    return await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}