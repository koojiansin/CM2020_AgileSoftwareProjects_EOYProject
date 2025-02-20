import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';

class AccountScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Function(String) onLogin; // Accept a username.
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onLogout,
  });

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _username = "Guest";
  String _friendCode = "";

  // Login function that verifies credentials against the DB.
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    final account = await DatabaseHelper.instance
        .getAccountByCredentials(username, password);
    if (account != null) {
      setState(() {
        _username = username;
        _friendCode = account['friendCode'] as String;
      });
      widget.onLogin(username); // Pass the actual username.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid username or password.")));
    }
  }

  // Register function to create a new account.
  Future<void> _handleRegister() async {
    final TextEditingController registerUsernameController =
        TextEditingController();
    final TextEditingController registerPasswordController =
        TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Register"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: registerUsernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: registerPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final username = registerUsernameController.text.trim();
                final password = registerPasswordController.text.trim();
                if (username.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please fill in all fields.")),
                  );
                  return;
                }
                final friendCode =
                    await DatabaseHelper.instance.generateNextFriendCode();
                await DatabaseHelper.instance.insertAccount({
                  'username': username,
                  'password': password,
                  'friendCode': friendCode,
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          "Account created with Friend Code: $friendCode")),
                );
              },
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: Center(
        child: widget.isLoggedIn ? _buildProfile() : _buildLogin(),
      ),
    );
  }

  Widget _buildProfile() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.person, size: 100, color: Colors.deepPurple),
        const SizedBox(height: 20),
        Text(
          "Welcome, $_username!",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          "Friend Code: $_friendCode",
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: widget.onLogout,
          child: const Text("Logout"),
        ),
      ],
    );
  }

  Widget _buildLogin() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Login to your account",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: "Username",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleLogin,
            child: const Text("Login"),
          ),
          TextButton(
            onPressed: _handleRegister,
            child: const Text("Register"),
          ),
        ],
      ),
    );
  }
}
