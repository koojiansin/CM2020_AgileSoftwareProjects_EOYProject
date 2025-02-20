import 'package:lgpokemon/helpers/database_helper.dart';

class Card {
  final int? id;
  final String title;
  final String grade;
  final String imagePath;

  Card({
    this.id,
    required this.title,
    required this.grade,
    required this.imagePath,
  });

  factory Card.fromMap(Map<String, dynamic> map) {
    return Card(
      id: map['id'] as int?,
      title: map['title'],
      grade: map['grade'],
      imagePath: map['imagePath'],
    );
  }

  // Fetch all social cards.
  static Future<List<Card>> fetchAllSocialCards() async {
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getSocialCards();
    return data.map((map) => Card.fromMap(map)).toList();
  }

  // Fetch all user cards.
  static Future<List<Card>> fetchAllUserCards() async {
    final List<Map<String, dynamic>> data =
        await DatabaseHelper.instance.getUserCards();
    return data.map((map) => Card.fromMap(map)).toList();
  }
}
