import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/Components/chat_list.dart';
import 'package:lgpokemon/helpers/database_helper.dart';

class FriendRequestScreen extends StatefulWidget {
  final String currentUser;
  const FriendRequestScreen({super.key, required this.currentUser});

  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  // Check if a string is likely a base64 image - improved detection
  bool _isBase64(String str) {
    try {
      return str.length > 100 &&
          RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(str);
    } catch (e) {
      return false;
    }
  }

  // Check if a string is likely an asset path
  bool _isAssetPath(String str) =>
      str.startsWith('lib/') ||
      str.startsWith('assets/') ||
      str.contains('assets');

  // Fetch incoming friend requests with friend avatars
  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchFriendRequestData() async {
    try {
      debugPrint("Current user: ${widget.currentUser}");

      final account = await DatabaseHelper.instance
          .getAccountByUsername(widget.currentUser);
      if (account == null) {
        debugPrint("Account not found for ${widget.currentUser}");
        return {'incoming': []};
      }

      final String myFriendCode = account['friendCode'] as String;
      debugPrint("Friend code: $myFriendCode");

      final incoming =
          await DatabaseHelper.instance.getIncomingFriendRequests(myFriendCode);
      debugPrint("Fetched ${incoming.length} friend requests");

      // Enhance each friend entry with their avatar path
      for (var request in incoming) {
        try {
          // Only process accepted requests
          if (request['status'] == 'accepted') {
            final friendUsername = request['sender'] as String;
            debugPrint("Processing friend: $friendUsername");

            final friendAccount = await DatabaseHelper.instance
                .getAccountByUsername(friendUsername);

            if (friendAccount != null) {
              final avatarPath = friendAccount['avatarPath'] as String?;
              debugPrint("Friend $friendUsername avatar path: $avatarPath");

              // Store the avatar path in the request
              request['avatarPath'] = avatarPath;

              // Extra debug info
              if (avatarPath != null && avatarPath.isNotEmpty) {
                if (_isBase64(avatarPath)) {
                  debugPrint("Avatar appears to be base64 encoded");
                } else if (_isAssetPath(avatarPath)) {
                  debugPrint("Avatar appears to be an asset path");
                } else {
                  // Check if file exists and is accessible
                  try {
                    final file = File(avatarPath);
                    final fileExists = await file.exists();
                    debugPrint("File exists: $fileExists");

                    if (fileExists) {
                      final fileStats = await file.stat();
                      debugPrint("File size: ${fileStats.size} bytes");
                      debugPrint("File modified: ${fileStats.modified}");

                      // Try to read the first few bytes to verify access
                      await file.openRead(0, 4).first;
                      debugPrint("File is readable");
                    }
                  } catch (e) {
                    debugPrint("File error: $e");
                  }
                }
              } else {
                debugPrint("Avatar path is null or empty");
              }
            } else {
              debugPrint("Friend account not found: $friendUsername");
            }
          }
        } catch (e) {
          debugPrint("Error processing friend avatar: $e");
        }
      }

      return {'incoming': incoming};
    } catch (e, stack) {
      debugPrint("Error fetching friend data: $e");
      debugPrint("Stack trace: $stack");
      return {'incoming': []};
    }
  }

  // Decline a friend request given its requestId.
  Future<void> _declineFriendRequest(int requestId) async {
    try {
      await DatabaseHelper.instance.declineFriendRequest(requestId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request declined.")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to decline friend request: $e")),
      );
    }
  }

  // Delete a friendship for both sides.
  Future<void> _deleteFriend(String friendUsername) async {
    try {
      await DatabaseHelper.instance
          .deleteFriendship(widget.currentUser, friendUsername);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend deleted.")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete friend: $e")),
      );
    }
  }

  // Accept a friend request given its requestId.
  Future<void> _acceptFriendRequest(int requestId) async {
    try {
      // Accept the original friend request.
      await DatabaseHelper.instance.acceptFriendRequest(requestId);

      // Retrieve the accepted friend request to obtain the sender.
      final requestRecord =
          await DatabaseHelper.instance.getFriendRequestById(requestId);
      if (requestRecord != null) {
        final String friendSender = requestRecord['sender'] as String;
        // Look up the sender's account information to get their friend code.
        final senderAccount =
            await DatabaseHelper.instance.getAccountByUsername(friendSender);
        if (senderAccount != null) {
          final String senderFriendCode = senderAccount['friendCode'] as String;
          // Insert reciprocal friendship: current user (the one who accepted) becomes sender,
          // and the sender's friend code becomes recipient.
          await DatabaseHelper.instance
              .insertReciprocalFriendship(widget.currentUser, senderFriendCode);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Friend request accepted.")),
      );
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to accept friend request: $e")),
      );
    }
  }

  // Improved avatar widget that handles all cases more robustly
  Widget _buildFriendAvatar(String friendUsername, String? avatarPath) {
    // Default avatar widget showing the first letter
    Widget defaultAvatar() {
      return CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        child: Text(
          friendUsername.isNotEmpty ? friendUsername[0].toUpperCase() : "?",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // If no path, return the default avatar
    if (avatarPath == null || avatarPath.isEmpty) {
      debugPrint("No avatar path for $friendUsername, showing default");
      return defaultAvatar();
    }

    debugPrint("Building avatar for $friendUsername with path: $avatarPath");

    try {
      // Handle different types of avatar paths
      if (_isBase64(avatarPath)) {
        debugPrint("Rendering base64 avatar for $friendUsername");

        try {
          final imageBytes = base64Decode(avatarPath);
          return CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: ClipOval(
              child: Image.memory(
                imageBytes,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("Failed to load base64 image: $error");
                  return Text(
                    friendUsername[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
          );
        } catch (e) {
          debugPrint("Base64 decode error: $e");
          return defaultAvatar();
        }
      } else if (_isAssetPath(avatarPath)) {
        debugPrint("Rendering asset avatar for $friendUsername");

        return CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: ClipOval(
            child: Image.asset(
              avatarPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) {
                debugPrint("Failed to load asset image: $error");
                return Text(
                  friendUsername[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // File path handling with extra safety checks
        debugPrint("Rendering file avatar for $friendUsername");

        final file = File(avatarPath);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            // Only try to load the file if it exists
            if (snapshot.data == true) {
              return CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: ClipOval(
                  child: Image.file(
                    file,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    cacheWidth: 80, // Add caching for better performance
                    errorBuilder: (context, error, stackTrace) {
                      debugPrint("Failed to load file image: $error");
                      return Text(
                        friendUsername[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              // File doesn't exist or couldn't be checked
              debugPrint("File doesn't exist: $avatarPath");
              return defaultAvatar();
            }
          },
        );
      }
    } catch (e) {
      debugPrint("Avatar rendering error: $e");
      return defaultAvatar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends & Requests"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchFriendRequestData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint("Error in friend requests: ${snapshot.error}");
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Error loading requests."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data ?? {'incoming': []};
          final incoming = data['incoming'] ?? [];

          final friends =
              incoming.where((req) => req['status'] == 'accepted').toList();
          final pending =
              incoming.where((req) => req['status'] == 'pending').toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Friends Section
                  const Text(
                    "Your Friends:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (friends.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          "No friends yet.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      child: Column(
                        children: friends.map((req) {
                          final String friendUsername =
                              req['sender']?.toString() ?? "Unknown";
                          final String? avatarPath =
                              req['avatarPath'] as String?;

                          return ListTile(
                            leading:
                                _buildFriendAvatar(friendUsername, avatarPath),
                            title: Text(friendUsername),
                            subtitle: const Text("Friend"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chat),
                                  color: Theme.of(context).primaryColor,
                                  tooltip: "Chat with $friendUsername",
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          currentUser: widget.currentUser,
                                          otherUser: friendUsername,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.person_remove),
                                  color: Colors.red,
                                  tooltip: "Remove $friendUsername",
                                  onPressed: () =>
                                      _deleteFriend(friendUsername),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Requests Section
                  const Divider(height: 30, thickness: 1),
                  const Text(
                    "Received Friend Requests:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pending.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20.0),
                      child: Center(
                        child: Text(
                          "No friend requests received.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      elevation: 2,
                      child: Column(
                        children: pending.map((req) {
                          final int requestId = req['id'] as int? ?? -1;
                          final String sender =
                              req['sender']?.toString() ?? "Unknown";
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey,
                              child: Text(
                                sender.isNotEmpty
                                    ? sender[0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(sender),
                            subtitle: const Text("Pending Request"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: requestId > 0
                                      ? () => _acceptFriendRequest(requestId)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                  child: const Text("Accept"),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: requestId > 0
                                      ? () => _declineFriendRequest(requestId)
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text("Decline"),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
