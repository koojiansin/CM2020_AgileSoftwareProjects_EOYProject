import 'package:flutter/material.dart';
import 'package:lgpokemon/screens/home_screen.dart';
import 'package:lgpokemon/screens/friend_request_screen.dart';
import 'package:lgpokemon/screens/news_screen.dart';
import 'package:lgpokemon/screens/account_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
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
  String _username = "Guest";

  // Updated to accept username.
  void _toggleLogin(bool status, [String username = "Guest"]) {
    setState(() {
      _isLoggedIn = status;
      if (status) _username = username;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(isLoggedIn: _isLoggedIn),
      FriendRequestScreen(currentUser: _username),
      const NewsScreen(),
      AccountScreen(
        isLoggedIn: _isLoggedIn,
        onLogin: (username) => _toggleLogin(true, username),
        onLogout: () => _toggleLogin(false),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.person_add), label: 'Friend Request'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.article), label: 'News'),
          BottomNavigationBarItem(
            icon: Icon(_isLoggedIn ? Icons.person : Icons.login),
            label: _isLoggedIn ? 'Profile' : 'Account',
          ),
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
