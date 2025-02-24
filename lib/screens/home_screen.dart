import 'package:flutter/material.dart';
import 'package:lgpokemon/Components/new_social_card.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/screens/my_page.dart';
import 'package:lgpokemon/screens/news_detail_screen.dart';
import 'package:lgpokemon/screens/social_page.dart';
import 'package:lgpokemon/screens/pokemon_cards_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isLoggedIn;
  final String currentUser; // current logged-in username

  const HomeScreen({
    super.key,
    required this.isLoggedIn,
    required this.currentUser,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final ValueNotifier<int> _currentIndexNotifier = ValueNotifier<int>(0);

  late Future<List<Map<String, dynamic>>> _friendCardsFuture;
  late Future<List<Map<String, dynamic>>> _userCardsFuture;

  final List<Map<String, String>> latestNews = const [
    {
      "title": "Flutter 3.0 Released!",
      "excerpt":
          "The latest version of Flutter introduces new exciting features...",
      "content":
          "Flutter 3.0 brings better performance, new widgets, and stability across platforms.",
      "author": "John Doe",
      "date": "Feb 17, 2025"
    },
    // ... additional news items if needed
  ];

  @override
  void initState() {
    super.initState();
    _friendCardsFuture =
        DatabaseHelper.instance.getFriendCards(widget.currentUser);
    _userCardsFuture =
        DatabaseHelper.instance.getUserCardsFor(widget.currentUser);
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
              onPageChanged: (index) => _currentIndexNotifier.value = index,
              itemBuilder: (context, index) {
                final news = latestNews[index];
                return GestureDetector(
                  onTap: () {
                    try {
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
                    } catch (e) {
                      print("Navigation error: $e");
                    }
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
                      color: currentIndex == index
                          ? Colors.deepPurple
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // Friend Cards Section – Shows cards of friends.
          SectionHeader(
            title: "Friend Cards",
            onExpand: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SocialPage(currentUser: widget.currentUser),
                  ),
                );
              } catch (e) {
                print("Error navigating to SocialPage: $e");
              }
            },
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _friendCardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint(
                      "Error in friend cards FutureBuilder: ${snapshot.error}");
                  return Center(
                      child: Text("Error: ${snapshot.error.toString()}"));
                }
                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(
                      child: Text("No friend cards available."));
                }
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    try {
                      final cardId = data[index]['id'];
                      return NewSocialCard(cardId: cardId, isUserCard: true);
                    } catch (error, stackTrace) {
                      debugPrint(
                          "Error building friend card at index $index: $error");
                      debugPrint("$stackTrace");
                      return const SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // "My Cards" Section – Only show cards for the current user.
          SectionHeader(
            title: "My Cards",
            onExpand: widget.isLoggedIn
                ? () async {
                    try {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyPage(currentUser: widget.currentUser),
                        ),
                      );
                      setState(() {
                        _userCardsFuture = DatabaseHelper.instance
                            .getUserCardsFor(widget.currentUser);
                      });
                    } catch (e, stackTrace) {
                      debugPrint("Error navigating to MyPage: $e");
                      debugPrint("$stackTrace");
                    }
                  }
                : null,
          ),

          widget.isLoggedIn
              ? Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _userCardsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        debugPrint(
                            "Error in user cards FutureBuilder: ${snapshot.error}");
                        return Center(
                            child: Text("Error: ${snapshot.error.toString()}"));
                      }
                      final data = snapshot.data ?? [];
                      if (data.isEmpty) {
                        return const Center(child: Text("No cards added yet."));
                      }
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          try {
                            final cardId = data[index]['id'];
                            return NewSocialCard(
                                cardId: cardId, isUserCard: true);
                          } catch (error, stackTrace) {
                            debugPrint(
                                "Error building my card at index $index: $error");
                            debugPrint("$stackTrace");
                            return const SizedBox.shrink();
                          }
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          if (onExpand != null)
            InkWell(
              onTap: onExpand,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Expand",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
