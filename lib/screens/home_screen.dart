import 'package:flutter/material.dart';
import 'package:lgpokemon/Components/new_social_card.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/screens/my_page.dart';
import 'package:lgpokemon/screens/news_detail_screen.dart';
import 'package:lgpokemon/screens/social_page.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  const HomeScreen({super.key, required this.isLoggedIn});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

  late Future<List<Map<String, dynamic>>> _socialCardsFuture;
  late Future<List<Map<String, dynamic>>> _userCardsFuture;

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
  void initState() {
    super.initState();
    _socialCardsFuture = DatabaseHelper.instance.getSocialCards();
    _userCardsFuture = DatabaseHelper.instance.getUserCards();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Column(
        children: [
          // News Slider
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _pageController,
              itemCount: latestNews.length,
              onPageChanged: (index) {
                _currentIndexNotifier.value = index;
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
          ValueListenableBuilder<int>(
            valueListenable: _currentIndexNotifier,
            builder: (context, currentIndex, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  latestNews.length,
                      (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: currentIndex == index ? 16 : 8,
                    decoration: BoxDecoration(
                      color: currentIndex == index ? Colors.deepPurple : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Social Section
          SectionHeader(title: "Socials", onExpand: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SocialPage()),
            );
          }),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _socialCardsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                return ListView.builder(
                  itemCount: data.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final cardId = data[index]['id'];
                    return NewSocialCard(cardId: cardId);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // "My Cards" Section
          SectionHeader(
            title: "My Cards",
            onExpand: widget.isLoggedIn
                ? () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPage()),
              );
              if (result == true) {
                setState(() {
                  _userCardsFuture = DatabaseHelper.instance.getUserCards();
                });
              }
            }
                : null,
          ),
          widget.isLoggedIn
              ? Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _userCardsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data!;
                return ListView.builder(
                  itemCount: data.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final cardId = data[index]['id'];
                    return NewSocialCard(cardId: cardId, isUserCard: true);
                  },
                );
              },
            ),
          )
              : const Expanded(
            child: Center(
              child: Text(
                "Please log in",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Section Header Widget
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onExpand;

  const SectionHeader({required this.title, this.onExpand, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
          if (onExpand != null)
            GestureDetector(
              onTap: onExpand,
              child: const Text(
                "Expand",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }
}
