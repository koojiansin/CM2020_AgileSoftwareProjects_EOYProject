import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;

  void _toggleLogin(bool status) {
    setState(() {
      _isLoggedIn = status;
    });
  }

  final List<Widget> _pages = [
    const HomeScreen(),
    const CommunicationScreen(),
    const NewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _selectedIndex == 3
          ? AccountScreen(
        isLoggedIn: _isLoggedIn,
        onLogin: () => _toggleLogin(true),
        onLogout: () => _toggleLogin(false),
      )
          : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Communication'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// News Section with Author & Date
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
    return ListView.builder(
      itemCount: newsArticles.length,
      itemBuilder: (context, index) {
        final news = newsArticles[index];

        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            title: Text(news["title"] ?? "No Title",
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}

// Detailed News Page with Author and Date
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
            Divider(),
            Text("Author: $author", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text("Published on: $date", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Divider(),
            const SizedBox(height: 10),
            Text(content, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Other Screens (Home, Communication, Account)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Home Screen', style: TextStyle(fontSize: 24)));
  }
}

class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Communication Screen', style: TextStyle(fontSize: 24)));
  }
}

class AccountScreen extends StatefulWidget {
  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return widget.isLoggedIn ? _buildUserAccountPage() : _buildLoginPage();
  }

  Widget _buildLoginPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Login', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onLogin();
            },
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAccountPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CircleAvatar(radius: 50, backgroundImage: AssetImage('assets/avatar.png')),
          const SizedBox(height: 20),
          const Text('Welcome, User!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {},
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onLogout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
