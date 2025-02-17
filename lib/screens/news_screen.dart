import 'package:flutter/material.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  final List<Map<String, String>> newsArticles = const [
    {
      "title": "Flutter 3.0 Released!",
      "excerpt": "The latest version of Flutter introduces new exciting features...",
      "content": "Flutter 3.0 brings better performance, new widgets, and stability across platforms.",
      "author": "John Doe",
      "date": "Feb 17, 2025"
    },
    {
      "title": "Dart 3 Announced",
      "excerpt": "Dart 3 is here with null safety and enhanced compiler optimizations...",
      "content": "Dart 3 is now officially available, bringing faster performance and new modern syntax.",
      "author": "Jane Smith",
      "date": "Feb 16, 2025"
    },
    {
      "title": "AI in Mobile Apps",
      "excerpt": "Artificial Intelligence is revolutionizing mobile app development...",
      "content": "With AI, apps can now provide personalized experiences, enhanced automation, and improved UI interactions.",
      "author": "Alex Johnson",
      "date": "Feb 15, 2025"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("News")),
      body: ListView.builder(
        itemCount: newsArticles.length,
        itemBuilder: (context, index) {
          final news = newsArticles[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(news["title"] ?? "No Title", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(news["excerpt"] ?? "No Excerpt"),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NewsDetailScreen(
                      title: news["title"] ?? "No Title",
                      content: news["content"] ?? "No Content Available",
                      author: news["author"] ?? "Unknown Author",
                      date: news["date"] ?? "Unknown Date",
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
