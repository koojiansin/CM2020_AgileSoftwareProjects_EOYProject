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
  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchFriendRequestData() async {
    try {
      final account = await DatabaseHelper.instance
          .getAccountByUsername(widget.currentUser);
      if (account == null) return {'incoming': []};

      final String myFriendCode = account['friendCode'] as String;
      final incoming =
          await DatabaseHelper.instance.getIncomingFriendRequests(myFriendCode);

      return {'incoming': incoming};
    } catch (e, stack) {
      debugPrint("Error fetching friend data: $e");
      return {'incoming': []};
    }
  }

  Future<void> _declineFriendRequest(int requestId) async {
    try {
      await DatabaseHelper.instance.declineFriendRequest(requestId);
      setState(() {});
    } catch (e) {
      debugPrint("Failed to decline friend request: $e");
    }
  }

  Future<void> _deleteFriend(String friendUsername) async {
    try {
      await DatabaseHelper.instance
          .deleteFriendship(widget.currentUser, friendUsername);
      setState(() {});
    } catch (e) {
      debugPrint("Failed to delete friend: $e");
    }
  }

  Future<void> _acceptFriendRequest(int requestId) async {
    try {
      await DatabaseHelper.instance.acceptFriendRequest(requestId);
      final requestRecord =
          await DatabaseHelper.instance.getFriendRequestById(requestId);
      if (requestRecord != null) {
        final String friendSender = requestRecord['sender'] as String;
        final senderAccount =
            await DatabaseHelper.instance.getAccountByUsername(friendSender);
        if (senderAccount != null) {
          final String senderFriendCode = senderAccount['friendCode'] as String;
          await DatabaseHelper.instance
              .insertReciprocalFriendship(widget.currentUser, senderFriendCode);
        }
      }
      setState(() {});
    } catch (e) {
      debugPrint("Failed to accept friend request: $e");
    }
  }

  Widget _buildFriendListTile(String friendUsername, String? avatarPath) {
    return FutureBuilder<int>(
      future: DatabaseHelper.instance
          .getUnreadMessagesCount(widget.currentUser, friendUsername),
      builder: (context, snapshot) {
        int unreadCount = snapshot.data ?? 0;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              friendUsername.isNotEmpty ? friendUsername[0].toUpperCase() : "?",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(friendUsername),
          subtitle: const Text("Friend"),
          trailing: SizedBox(
            width: 100, // Ensures both buttons fit properly
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none, // Ensures badge doesn't get clipped
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
                        ).then((_) {
                          setState(() {}); // Refresh UI when coming back
                        });
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: IgnorePointer(
                          // Ensures badge does not block clicks
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle, // Keeps badge circular
                              border: Border.all(
                                  color: Colors.white,
                                  width: 1), // White border
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 20,
                              minHeight: 20,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9
                                    ? '9+'
                                    : '$unreadCount', // Limits badge to '9+'
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove),
                  color: Colors.red,
                  tooltip: "Remove $friendUsername",
                  onPressed: () => _deleteFriend(friendUsername),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Friends & Requests"),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchFriendRequestData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
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
                          return _buildFriendListTile(
                              friendUsername, req['avatarPath'] as String?);
                        }).toList(),
                      ),
                    ),
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
                                  onPressed: () =>
                                      _acceptFriendRequest(requestId),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).primaryColor),
                                  child: const Text("Accept"),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () =>
                                      _declineFriendRequest(requestId),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
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
