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

    await db.execute('''
      CREATE TABLE news (
        id $idType,
        imgPath $textType,
        title $textType,
        description $textType,
        date $textType
      )
    ''');

    // Seed the news table with sample news.
    final defaultNews = [
      {
        'imgPath': 'lib/images/News1.png',
        'title': 'Release Time and Countdown',
        'description':
            'The release time for the new game has been announced. Check out the countdown timer.',
        'date': 'Feb 17, 2025',
      },
      {
        'imgPath': 'lib/images/News2.png',
        'title': 'Maintenance Status',
        'description': 'Maintenance status and updates.',
        'date': 'Feb 16, 2025',
      },
      {
        'imgPath': 'lib/images/News3.png',
        'title': 'Latest News',
        'description':
            'The latest news and updates for the Community and Shops.',
        'date': 'Feb 15, 2025',
      },
    ];
    for (var news in defaultNews) {
      await db.insert('news', news);
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
    friendCode $textType,
    avatarPath TEXT,
    isAdmin INTEGER DEFAULT 0
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
    await db.insert('accounts', {
      'username': 'Admin',
      'password': 'Admin',
      'friendCode': 'A00A00A02',
      'isAdmin': 1,
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

    await db.execute('''
  CREATE TABLE messages (
    id $idType,
    sender $textType,
    recipient $textType,
    content $textType,
    timestamp INTEGER NOT NULL,
    read INTEGER NOT NULL
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

// ----- News CRUD -----
  Future<List<Map<String, dynamic>>> getNews() async {
    final db = await instance.database;
    return await db.query('news', orderBy: 'id DESC');
  }

// Add insertNews method to DatabaseHelper class
  Future<int> insertNews(Map<String, dynamic> news) async {
    final db = await instance.database;
    return await db.insert('news', news);
  }

// Add deleteNews method to DatabaseHelper class
  Future<int> deleteNews(int id) async {
    final db = await instance.database;
    return await db.delete('news', where: 'id = ?', whereArgs: [id]);
  }

// Add updateNews method to DatabaseHelper class
  Future<int> updateNews(Map<String, dynamic> news) async {
    final db = await instance.database;
    return await db.update(
      'news',
      news,
      where: 'id = ?',
      whereArgs: [news['id']],
    );
  }

  // ----- Chat Messages CRUD -----
  Future<int> insertMessage(Map<String, dynamic> message) async {
    final db = await instance.database;
    return await db.insert('messages', message);
  }

  Future<List<Map<String, dynamic>>> getMessagesBetweenUsers(
      String user1, String user2) async {
    final db = await instance.database;
    return await db.query(
      'messages',
      where: '(sender = ? AND recipient = ?) OR (sender = ? AND recipient = ?)',
      whereArgs: [user1, user2, user2, user1],
      orderBy: 'timestamp ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getConversations(String username) async {
    final db = await instance.database;

    // This query gets the most recent message for each conversation
    final result = await db.rawQuery('''
    SELECT 
      m1.*
    FROM 
      messages m1
    INNER JOIN (
      SELECT 
        CASE 
          WHEN sender = ? THEN recipient
          ELSE sender
        END as other_user,
        MAX(timestamp) as max_time
      FROM 
        messages
      WHERE 
        sender = ? OR recipient = ?
      GROUP BY 
        other_user
    ) m2 ON (
      (m1.sender = ? AND m1.recipient = m2.other_user) OR
      (m1.recipient = ? AND m1.sender = m2.other_user)
    ) AND m1.timestamp = m2.max_time
    ORDER BY 
      m1.timestamp DESC
  ''', [username, username, username, username, username]);

    return result;
  }

  Future<int> markMessagesAsRead(String sender, String recipient) async {
    final db = await instance.database;
    return await db.update(
      'messages',
      {'read': 1},
      where: 'sender = ? AND recipient = ? AND read = 0',
      whereArgs: [sender, recipient],
    );
  }

  Future<int> getUnreadMessagesCount(
      String currentUser, String otherUser) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as unreadCount FROM messages WHERE recipient = ? AND sender = ? AND read = 0",
      [currentUser, otherUser],
    );

    return result.isNotEmpty ? result.first['unreadCount'] as int? ?? 0 : 0;
  }

  // Add this method to DatabaseHelper class
  Future<int> updateAccount(Map<String, dynamic> account) async {
    final db = await instance.database;
    final username = account['username'];
    return await db.update(
      'accounts',
      account,
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<int> updateMessageContent(int messageId, String newContent) async {
    final db = await instance.database;
    return await db.update(
      'messages',
      {'content': newContent},
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  Future<bool> transferCard(int cardId, String seller, String buyer) async {
    final db = await instance.database;
    bool success = false;

    // Begin transaction
    await db.transaction((txn) async {
      // Get the card data
      final cardResult = await txn.query(
        'usercards',
        where: 'id = ? AND username = ?',
        whereArgs: [cardId, seller],
      );

      if (cardResult.isEmpty) {
        return;
      }

      // Update the card to belong to the new owner
      final updateCount = await txn.update(
        'usercards',
        {'username': buyer},
        where: 'id = ?',
        whereArgs: [cardId],
      );

      if (updateCount > 0) {
        success = true;
      }
    });

    return success;
  }
}
