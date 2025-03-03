import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'news_detail_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;

  @override
  void initState() {
    super.initState();
    _newsFuture = DatabaseHelper.instance.getNews();
  }

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
      return const Icon(Icons.broken_image, size: 50);
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
            return const Icon(Icons.broken_image, size: 50);
          },
        );
      }
      return const Icon(Icons.broken_image, size: 50);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _newsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("No news available."));
          }
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final news = data[index];
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: SizedBox(
                    width: 80,
                    child: _buildNewsImage(news['imgPath'], width: 80),
                  ),
                  title: Text(
                    news['title'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    news['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NewsDetailScreen(
                          imgPath: news['imgPath'],
                          title: news['title'],
                          description: news['description'],
                          date: news['date'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
