import 'package:flutter/material.dart';
import 'package:lgpokemon/Components/add_friend_dialog.dart';
import 'package:lgpokemon/screens/home_screen.dart';
import 'package:lgpokemon/screens/friend_request_screen.dart';
import 'package:lgpokemon/screens/news_screen.dart';
import 'package:lgpokemon/screens/account_screen.dart';
import 'package:lgpokemon/screens/pokemon_cards_screen.dart';
import 'package:lgpokemon/screens/admin_screen.dart'; // New import
import 'package:lgpokemon/helpers/database_helper.dart';

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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
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
  bool _isAdmin = false; // New flag to check if user is admin
  String _username = "Guest";

  // Toggle login status and update username if logged in.
  void _toggleLogin(bool status, [String username = "Guest"]) async {
    setState(() {
      _isLoggedIn = status;
      _username = status ? username : "Guest";
    });

    if (status) {
      // Check if logged in user is admin
      final account =
          await DatabaseHelper.instance.getAccountByUsername(username);
      final bool isAdmin =
          account != null && (account['isAdmin'] as int? ?? 0) == 1;

      setState(() {
        _isAdmin = isAdmin;
        if (_selectedIndex >= 4) {
          // Reset to Home if on Admin tab but no longer admin
          _selectedIndex = 0;
        }
      });

      debugPrint("User is admin: $_isAdmin");
    } else {
      setState(() {
        _isAdmin = false;
        if (_selectedIndex >= 4) {
          // Reset to Home if on Admin tab but logged out
          _selectedIndex = 0;
        }
      });
    }
  }

  /// Returns a different FAB widget (or null) based on the current page.
  Widget? _buildFabForPage(int selectedIndex) {
    switch (selectedIndex) {
      case 0: // HomeScreen: show Pokémon Cards FAB
        return FloatingActionButton(
          key: const ValueKey('home_fab'),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PokemonCardsScreen(),
              ),
            );
          },
          child: const Icon(Icons.catching_pokemon),
          tooltip: "View Pokémon Cards (swsh1)",
        );
      case 1: // FriendRequestScreen: show Add Friend FAB
        return FloatingActionButton(
          key: const ValueKey('friend_request_fab'),
          onPressed: () {
            // Use the imported function from add_friend_dialog.dart.
            showAddFriendDialog(context, _username);
          },
          child: const Icon(Icons.person_add),
          tooltip: "Add Friend",
        );
      default:
        return null; // No FAB for other pages.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the pages list based on logged in status and admin status
    final List<Widget> pages = [
      HomeScreen(isLoggedIn: _isLoggedIn, currentUser: _username),
      FriendRequestScreen(currentUser: _username),
      const NewsScreen(),
      AccountScreen(
        isLoggedIn: _isLoggedIn,
        onLogin: (username) => _toggleLogin(true, username),
        onLogout: () => _toggleLogin(false),
        currentUser: _username,
      ),
    ];

    // Add AdminScreen if user is admin
    if (_isAdmin) {
      pages.add(const AdminScreen());
    }

    // Create bottom navigation items
    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(
          icon: Icon(Icons.person_add), label: 'Friend Request'),
      const BottomNavigationBarItem(icon: Icon(Icons.article), label: 'News'),
      BottomNavigationBarItem(
        icon: Icon(_isLoggedIn ? Icons.person : Icons.login),
        label: _isLoggedIn ? 'Profile' : 'Account',
      ),
    ];

    // Add Admin tab if user is admin
    if (_isAdmin) {
      navItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'LG Pokémon',
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Required for more than 4 items
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      // AnimatedSwitcher for FAB scale (zoom) animation when switching pages.
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: _buildFabForPage(_selectedIndex),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
