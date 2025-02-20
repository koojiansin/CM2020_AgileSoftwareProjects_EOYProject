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

    // Create the accounts table.
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        username $textType,
        password $textType,
        friendCode $textType
      )
    ''');

    // Seed the accounts table with two accounts.
    await db.insert('accounts', {
      'username': 'Username',
      'password': 'Password',
      'friendCode': 'A00A00A00',
    });
    await db.insert('accounts', {
      'username': 'Username1',
      'password': 'Password1',
      'friendCode': 'A00A00A01',
    });

    // Create the friends table.
    await db.execute('''
  CREATE TABLE friends (
    id $idType,
    sender $textType,
    recipientFriendCode $textType,
    status $textType DEFAULT 'pending'
  )
''');
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

  // Account related methods.

  // Get an account based on username and password.
  Future<Map<String, dynamic>?> getAccountByCredentials(
      String username, String password) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Insert an account record.
  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await instance.database;
    return await db.insert('accounts', account);
  }

  // Generate the next ascending friend code.
  Future<String> generateNextFriendCode() async {
    final db = await instance.database;
    final result = await db.rawQuery(
        "SELECT friendCode FROM accounts ORDER BY friendCode DESC LIMIT 1");
    if (result.isEmpty) {
      return "A00A00A00";
    }
    final String lastCode = result.first['friendCode'] as String;
    int lastNumber = int.parse(lastCode.substring(lastCode.length - 2));
    lastNumber++;
    String newSuffix = lastNumber.toString().padLeft(2, '0');
    return "A00A00A$newSuffix";
  }

  // ----- Friends CRUD -----
  Future<int> insertFriendRequest(
      String sender, String recipientFriendCode) async {
    final db = await instance.database;
    return await db.insert('friends', {
      'sender': sender,
      'recipientFriendCode': recipientFriendCode,
      'status': 'pending',
    });
  }

// Get incoming friend requests for a given recipient friend code.
  Future<List<Map<String, dynamic>>> getIncomingFriendRequests(
      String recipientFriendCode) async {
    final db = await instance.database;
    return await db.query(
      'friends',
      where: 'recipientFriendCode = ?',
      whereArgs: [recipientFriendCode],
    );
  }

  // Get an account by friend code.
  Future<Map<String, dynamic>?> getAccountByFriendCode(
      String friendCode) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'friendCode = ?',
      whereArgs: [friendCode],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Accept a friend request by updating its status.
  Future<int> acceptFriendRequest(int requestId) async {
    final db = await instance.database;
    return await db.update(
      'friends',
      {'status': 'accepted'},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  // Get an account by username.
  Future<Map<String, dynamic>?> getAccountByUsername(String username) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Get friend requests sent by owner.
  Future<List<Map<String, dynamic>>> getFriendRequestsByOwner(
      String owner) async {
    final db = await instance.database;
    return await db.query(
      'friends',
      where: 'sender = ?',
      whereArgs: [owner],
    );
  }

  // Get a friend request by its ID.
  Future<Map<String, dynamic>?> getFriendRequestById(int requestId) async {
    final db = await instance.database;
    final result = await db.query(
      'friends',
      where: 'id = ?',
      whereArgs: [requestId],
      limit: 1,
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Decline a friend request by deleting it.
  Future<int> declineFriendRequest(int requestId) async {
    final db = await instance.database;
    return await db.delete(
      'friends',
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
