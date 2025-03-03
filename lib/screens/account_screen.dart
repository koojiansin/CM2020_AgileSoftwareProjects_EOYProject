import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

class AccountScreen extends StatefulWidget {
  final bool isLoggedIn;
  final Function(String) onLogin;
  final VoidCallback onLogout;
  final String currentUser; // Add this property to receive the current username

  const AccountScreen({
    super.key,
    required this.isLoggedIn,
    required this.onLogin,
    required this.onLogout,
    required this.currentUser, // Make this required
  });

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late String _username; // Don't initialize here
  String _friendCode = "";
  String? _avatarPath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Initialize username from the widget property
    _username = widget.currentUser;

    // Only load profile if actually logged in
    if (widget.isLoggedIn) {
      _loadUserProfile();
    }
  }

  @override
  void didUpdateWidget(AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update username if it changes
    if (oldWidget.currentUser != widget.currentUser) {
      setState(() {
        _username = widget.currentUser;
      });
      if (widget.isLoggedIn) {
        _loadUserProfile();
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (_username == "Guest" || _username.isEmpty) {
      return; // Don't try to load for guest users
    }

    debugPrint("Loading profile for: $_username");
    final account =
        await DatabaseHelper.instance.getAccountByUsername(_username);
    if (account != null) {
      setState(() {
        _friendCode = account['friendCode'] as String;
        _avatarPath = account['avatarPath'] as String?;
      });
      debugPrint("Loaded friendCode: $_friendCode, avatar: $_avatarPath");
    } else {
      debugPrint("No account found for username: $_username");
    }
  }

  // Function to take a photo with camera
  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 300,
      imageQuality: 85,
    );
    if (image != null) {
      await _saveImage(image);
    }
  }

  // Function to select from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      imageQuality: 85,
    );
    if (image != null) {
      await _saveImage(image);
    }
  }

  // Save image to app directory and update database
  Future<void> _saveImage(XFile image) async {
    try {
      final directory = await path_provider.getApplicationDocumentsDirectory();
      final fileName = '${_username}_avatar${path.extension(image.path)}';
      final savedImage =
          await File(image.path).copy('${directory.path}/$fileName');

      // Debug the file path
      debugPrint("Saved avatar to: ${savedImage.path}");

      // Update database with new avatar path
      await DatabaseHelper.instance.updateAccount({
        'username': _username,
        'avatarPath': savedImage.path,
      });

      setState(() {
        _avatarPath = savedImage.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Avatar updated successfully")));
    } catch (e) {
      debugPrint("Failed to save avatar: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Failed to update avatar: $e")));
    }
  }

  // Show avatar selection options
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
        ],
      ),
    );
  }

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
        _avatarPath = account['avatarPath'] as String?;
      });
      widget.onLogin(username);
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
    debugPrint(
        "Building AccountScreen with username: $_username, logged in: ${widget.isLoggedIn}");

    return Scaffold(
      appBar: AppBar(title: const Text("Account")),
      body: Center(
        child: widget.isLoggedIn ? _buildProfile() : _buildLogin(),
      ),
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Avatar with edit option
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Theme.of(context).primaryColor, width: 2),
                  ),
                  child: ClipOval(
                    child: _avatarPath != null && _avatarPath!.isNotEmpty
                        ? Builder(builder: (context) {
                            final file = File(_avatarPath!);
                            return file.existsSync()
                                ? Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          "Error loading avatar: $error");
                                      return const Icon(Icons.person,
                                          size: 80, color: Colors.deepPurple);
                                    },
                                  )
                                : const Icon(Icons.person,
                                    size: 80, color: Colors.deepPurple);
                          })
                        : const Icon(Icons.person,
                            size: 80, color: Colors.deepPurple),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            "Welcome, $_username!",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge, color: Colors.deepPurple),
                      SizedBox(width: 10),
                      Text("Friend Code",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _friendCode,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Share this code with friends to connect",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.onLogout,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
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
