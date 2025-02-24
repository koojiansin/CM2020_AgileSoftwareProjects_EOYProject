//// filepath: /Users/shaunsevilla/Downloads/CM2020_AgileSoftwareProjects_EOYProject/lib/helpers/database_helper.dart
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

    // Seed the usercards table for "Username1" account with three additional cards.
    await db.insert('usercards', {
      'title': 'Charizard',
      'grade': '9',
      'imagePath': 'lib/images/Charizard.jpg',
      'username': 'Username1',
    });
    await db.insert('usercards', {
      'title': 'Blastoise',
      'grade': '8',
      'imagePath': 'lib/images/Blastoise.jpg',
      'username': 'Username1',
    });
    await db.insert('usercards', {
      'title': 'Venusaur',
      'grade': '8',
      'imagePath': 'lib/images/Venusaur.jpg',
      'username': 'Username1',
    });

    // Seed the usercards table for "Username" account with three additional cards.
    await db.insert('usercards', {
      'title': 'Charmeleon',
      'grade': '9',
      'imagePath': 'lib/images/Charmeleon.jpg',
      'username': 'Username',
    });
    await db.insert('usercards', {
      'title': 'Ivysaur',
      'grade': '8',
      'imagePath': 'lib/images/Ivysaur.jpg',
      'username': 'Username',
    });
    await db.insert('usercards', {
      'title': 'Wartortle',
      'grade': '8',
      'imagePath': 'lib/images/Wartortle.jpg',
      'username': 'Username',
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

    // Make Username and Username1 friends at the start.
    // Insert a row from Username to Username1.
    await db.insert('friends', {
      'sender': 'Username',
      'recipientFriendCode': 'A00A00A01',
      'status': 'accepted',
    });
    // Insert a reciprocal row from Username1 to Username.
    await db.insert('friends', {
      'sender': 'Username1',
      'recipientFriendCode': 'A00A00A00',
      'status': 'accepted',
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

  Future<List<Map<String, dynamic>>> getUserCardsFor(String username) async {
    final db = await instance.database;
    return await db
        .query('usercards', where: 'username = ?', whereArgs: [username]);
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

  // Account Related Methods
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

  Future<int> insertAccount(Map<String, dynamic> account) async {
    final db = await instance.database;
    return await db.insert('accounts', account);
  }

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

  Future<int> insertReciprocalFriendship(
      String user, String recipientFriendCode) async {
    final db = await instance.database;
    // Check if a reciprocal record exists already.
    final existing = await db.query('friends',
        where: 'sender = ? AND recipientFriendCode = ?',
        whereArgs: [user, recipientFriendCode]);
    if (existing.isNotEmpty) {
      return 0;
    }
    return await db.insert('friends', {
      'sender': user,
      'recipientFriendCode': recipientFriendCode,
      'status': 'accepted',
    });
  }

  Future<List<Map<String, dynamic>>> getIncomingFriendRequests(
      String recipientFriendCode) async {
    final db = await instance.database;
    return await db.query('friends',
        where: 'recipientFriendCode = ?', whereArgs: [recipientFriendCode]);
  }

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

  Future<int> acceptFriendRequest(int requestId) async {
    final db = await instance.database;
    return await db.update('friends', {'status': 'accepted'},
        where: 'id = ?', whereArgs: [requestId]);
  }

  Future<Map<String, dynamic>?> getAccountByUsername(String username) async {
    final db = await instance.database;
    final result = await db.query('accounts',
        where: 'username = ?', whereArgs: [username], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<List<Map<String, dynamic>>> getFriendRequestsByOwner(
      String owner) async {
    final db = await instance.database;
    return await db.query('friends', where: 'sender = ?', whereArgs: [owner]);
  }

  Future<Map<String, dynamic>?> getFriendRequestById(int requestId) async {
    final db = await instance.database;
    final result = await db.query('friends',
        where: 'id = ?', whereArgs: [requestId], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  Future<int> declineFriendRequest(int requestId) async {
    final db = await instance.database;
    return await db.delete('friends', where: 'id = ?', whereArgs: [requestId]);
  }

  Future<int> deleteFriendship(
      String currentUser, String friendUsername) async {
    final db = await instance.database;
    final currentAccount = await getAccountByUsername(currentUser);
    final friendAccount = await getAccountByUsername(friendUsername);
    if (currentAccount == null || friendAccount == null) return 0;
    final currentFriendCode = currentAccount['friendCode'];
    final friendFriendCode = friendAccount['friendCode'];

    return await db.delete(
      'friends',
      where:
          '(sender = ? AND recipientFriendCode = ?) OR (sender = ? AND recipientFriendCode = ?)',
      whereArgs: [
        currentUser,
        friendFriendCode,
        friendUsername,
        currentFriendCode
      ],
    );
  }

  Future<List<Map<String, dynamic>>> getFriendCards(String username) async {
    final db = await instance.database;
    // Get current account info.
    final currentAccount = await getAccountByUsername(username);
    if (currentAccount == null) return [];
    final currentFriendCode = currentAccount['friendCode'];

    // Get friend rows where current user is the sender.
    final friendRows1 = await db.query('friends',
        where: 'sender = ? AND status = ?', whereArgs: [username, 'accepted']);
    // Get friend rows where current user's friendCode is the recipient.
    final friendRows2 = await db.query('friends',
        where: 'recipientFriendCode = ? AND status = ?',
        whereArgs: [currentFriendCode, 'accepted']);

    List<String> friendUsernames = [];

    // In friendRows1, use the recipient friend code to look up the friend account.
    for (var row in friendRows1) {
      final friendAcc =
          await getAccountByFriendCode(row['recipientFriendCode'] as String);
      if (friendAcc != null) {
        friendUsernames.add(friendAcc['username'] as String);
      }
    }
    // In friendRows2, the sender is the friend.
    for (var row in friendRows2) {
      friendUsernames.add(row['sender'] as String);
    }
    // Remove duplicate usernames.
    friendUsernames = friendUsernames.toSet().toList();
    if (friendUsernames.isEmpty) return [];

    final String whereClause =
        'username IN (${List.filled(friendUsernames.length, '?').join(',')})';
    final friendCards = await db.query('usercards',
        where: whereClause, whereArgs: friendUsernames, orderBy: 'id DESC');
    return friendCards;
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
