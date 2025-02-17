import 'package:flutter/material.dart';
import 'package:lgpokemon/screens/news_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentIndex = 0;

  final List<Map<String, String>> latestNews = const [
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
      appBar: AppBar(title: const Text("Home")),
      body: Column(
        children: [
          // News Slider (Replaced CarouselSlider with PageView)
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _pageController,
              itemCount: latestNews.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final news = latestNews[index];
                return GestureDetector(
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
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [Colors.deepPurple, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            news["title"] ?? "No Title",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            news["excerpt"] ?? "No Excerpt",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              latestNews.length,
                  (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentIndex == index ? 16 : 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.deepPurple : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Static Welcome Text
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Welcome to Flutter News! Stay updated with the latest tech trends.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
