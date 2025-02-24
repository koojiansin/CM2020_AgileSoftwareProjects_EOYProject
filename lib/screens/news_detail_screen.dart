import 'package:flutter/material.dart';

class NewsDetailScreen extends StatelessWidget {
  final String imgPath;
  final String title;
  final String description;
  final String date;

  const NewsDetailScreen({
    super.key,
    required this.imgPath,
    required this.title,
    required this.description,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the news image.
              Image.asset(
                imgPath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 150),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(
                "Published on: $date",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Divider(),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
