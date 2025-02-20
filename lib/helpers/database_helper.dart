import 'dart:async';
import 'package:lgpokemon/models/card.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    // Create the socialcards table.
    await db.execute('''
      CREATE TABLE socialcards (
        id $idType,
        title $textType,
        grade $textType,
        imagePath $textType
      )
    ''');

    // Seed socialcards with default cards.
    final defaultSocialCards = [
      {
        'title': 'Charizard',
        'grade': '10',
        'imagePath': 'lib/images/Charizard.jpg'
      },
      {
        'title': 'Blastoise',
        'grade': '9',
        'imagePath': 'lib/images/Blastoise.jpg'
      },
      {
        'title': 'Venusaur',
        'grade': '8',
        'imagePath': 'lib/images/Venusaur.jpg'
      },
      {
        'title': 'Charmander',
        'grade': '10',
        'imagePath': 'lib/images/Charmander.jpg'
      },
      {
        'title': 'Squirtle',
        'grade': '9',
        'imagePath': 'lib/images/Squirtle.jpg'
      },
      {
        'title': 'Bulbasaur',
        'grade': '8',
        'imagePath': 'lib/images/Bulbasaur.jpg'
      },
    ];

    for (var card in defaultSocialCards) {
      await db.insert('socialcards', card);
    }

    // Create the usercards table with a username column.
    await db.execute('''
      CREATE TABLE usercards (
        id $idType,
        title $textType,
        grade $textType,
        imagePath $textType,
        username $textType
      )
    ''');

    // (Optionally seed usercards with initial data here.)

    // Create the accounts table.
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        username $textType,
        password $textType
      )
    ''');

    // Seed the accounts table with two accounts.
    await db.insert('accounts', {
      'username': 'Username',
      'password': 'Password',
    });
    await db.insert('accounts', {
      'username': 'username1',
      'password': 'password1',
    });
  }

  // ----- Social Cards CRUD -----
  Future<int> insertSocialCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert('socialcards', card);
  }

  Future<Map<String, dynamic>?> getSocialCardById(int id) async {
    final db = await instance.database;
    final result =
        await db.query('socialcards', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getSocialCards() async {
    final db = await instance.database;
    return await db.query('socialcards');
  }

  Future<int> updateSocialCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    final id = card['id'];
    return await db
        .update('socialcards', card, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteSocialCard(int id) async {
    final db = await instance.database;
    return await db.delete('socialcards', where: 'id = ?', whereArgs: [id]);
  }

  // ----- User Cards CRUD -----
  Future<int> insertUserCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert('usercards', card);
  }

  Future<Map<String, dynamic>?> getUserCardById(int id) async {
    final db = await instance.database;
    final result =
        await db.query('usercards', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getUserCards() async {
    final db = await instance.database;
    return await db.query('usercards');
  }

  Future<int> updateUserCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    final id = card['id'];
    return await db.update('usercards', card, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUserCard(int id) async {
    final db = await instance.database;
    return await db.delete('usercards', where: 'id = ?', whereArgs: [id]);
  }

  // Other existing methods…
  Future<Map<String, dynamic>?> getAccount() async {
    final db = await instance.database;
    final result = await db.query('accounts', limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
