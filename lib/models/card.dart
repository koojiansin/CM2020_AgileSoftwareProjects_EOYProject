import 'package:lgpokemon/helpers/database_helper.dart';

class Card {
  final int? id;
  final String title;
  final String grade;
  final String imagePath;
  final String? username; // Add username field

  Card({
    this.id,
    required this.title,
    required this.grade,
    required this.imagePath,
    this.username,
  });

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] as int?,
      title: map['title'] as String,
      grade: map['grade'] as String,
      imagePath: map['imagePath'] as String,
      username: map['username'] as String?,
    );
  }

  // Fetch all social cards.
  static Future<List<Card>> fetchAllSocialCards() async {
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getSocialCards();
    return data.map((map) => Card.fromMap(map)).toList();
  }

  // Fetch all user cards for a specific username.
  static Future<List<Card>> fetchUserCards(String username) async {
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getUserCardsFor(username);
    return data.map((map) => Card.fromMap(map)).toList();
  }
}
