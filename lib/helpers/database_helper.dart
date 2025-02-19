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

    // Create the cards table
    await db.execute('''
      CREATE TABLE cards (
        id $idType,
        title $textType,
        grade $textType,
        imagePath $textType
      )
    ''');

    // Seed the database with default cards
    final defaultCards = [
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

    for (var card in defaultCards) {
      await db.insert('cards', card);
    }

    // Create the accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        username $textType,
        password $textType
      )
    ''');

    // Seed the accounts table with one account record
    await db.insert('accounts', {
      'username': 'Username',
      'password': 'Password',
    });
  }

  // CRUD Methods

  // Insert a card into the database
  Future<int> insertCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    return await db.insert('cards', card);
  }

  // Retrieve a card by ID
  Future<Map<String, dynamic>?> getCardById(int id) async {
    final db = await instance.database;
    final result = await db.query('cards', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Retrieve all cards from the database
  Future<List<Map<String, dynamic>>> getCards() async {
    final db = await instance.database;
    return await db.query('cards');
  }

  // Update a card
  Future<int> updateCard(Map<String, dynamic> card) async {
    final db = await instance.database;
    final id = card['id'];
    return await db.update('cards', card, where: 'id = ?', whereArgs: [id]);
  }

  // Static method to fetch all cards as objects.
  static Future<List<Card>> fetchAllCards() async {
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getCards();
    return data.map((map) => Card.fromMap(map)).toList();
  }

  // Delete a card
  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  // Close the database
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // Optionally, you can add methods to retrieve or validate the account.
  Future<Map<String, dynamic>?> getAccount() async {
    final db = await instance.database;
    final result = await db.query('accounts', limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }
}
