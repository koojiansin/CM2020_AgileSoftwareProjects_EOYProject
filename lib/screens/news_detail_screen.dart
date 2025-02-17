import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final String author;
  final String date;

  const NewsDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Text("Author: $author", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Published on: $date", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
