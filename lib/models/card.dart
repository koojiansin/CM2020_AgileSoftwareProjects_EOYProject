import 'package:lgpokemon/helpers/database_helper.dart';

class Card {
  final int? id; // New field for the database record id
  final String title;
  final String grade;
  final String imagePath;

  Card({
    this.id,
    required this.title,
    required this.grade,
    required this.imagePath,
  });

  // Factory constructor to create a Card from a Map (from the DB)
  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] as int?, // Assign the id from DB
      title: map['title'],
      grade: map['grade'],
      imagePath: map['imagePath'],
    );
  }

  // Static method to fetch all Cards from the SQL DB
  static Future<List<Card>> fetchAllCards() async {
    // Retrieve the raw list from the DatabaseHelper
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getCards();
    // Map each record to a Card instance
    return data.map((map) => Card.fromMap(map)).toList();
  }
}
