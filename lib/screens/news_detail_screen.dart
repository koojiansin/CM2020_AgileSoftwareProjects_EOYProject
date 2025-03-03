import 'dart:io';
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

  // Helper method to properly handle different image sources
  Widget _buildNewsImage(String imgPath,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    try {
      // First try loading as an asset
      if (imgPath.startsWith('lib/') || imgPath.startsWith('assets/')) {
        return Image.asset(
          imgPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            // If asset loading fails, try file loading
            return _tryLoadFile(imgPath,
                width: width, height: height, fit: fit);
          },
        );
      } else {
        // Try loading as a file
        return _tryLoadFile(imgPath, width: width, height: height, fit: fit);
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
      return const Icon(Icons.broken_image, size: 150);
    }
  }

  Widget _tryLoadFile(String imgPath,
      {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    try {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 150);
          },
        );
      }
      return const Icon(Icons.broken_image, size: 150);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 150);
    }
  }

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
              _buildNewsImage(imgPath, width: double.infinity),
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
