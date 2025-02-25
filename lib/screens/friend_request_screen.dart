//// filepath: /Users/shaunsevilla/Downloads/CM2020_AgileSoftwareProjects_EOYProject/lib/screens/friend_request_screen.dart
import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';

class FriendRequestScreen extends StatefulWidget {
  final String currentUser; // The logged-in username.
  const FriendRequestScreen({super.key, required this.currentUser});

  @override
  _FriendRequestScreenState createState() => _FriendRequestScreenState();
}

class _FriendRequestScreenState extends State<FriendRequestScreen> {
  // Fetch incoming friend requests.
  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchFriendRequestData() async {
    final account =
        await DatabaseHelper.instance.getAccountByUsername(widget.currentUser);
    if (account == null) return {'incoming': []};
    final String myFriendCode = account['friendCode'] as String;
    final incoming =
        await DatabaseHelper.instance.getIncomingFriendRequests(myFriendCode);
    return {'incoming': incoming};
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
        const SnackBar(content: Text("Failed to accept friend request.")),
      );
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
        const SnackBar(content: Text("Failed to decline friend request.")),
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
        const SnackBar(content: Text("Failed to delete friend.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchFriendRequestData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading requests."));
          }
          final data = snapshot.data!;
          final incoming = data['incoming']!;

          // Separate accepted and pending incoming requests.
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
                  // Friends Section (Accepted Incoming Requests)
                  const Text(
                    "Your Friends:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (friends.isEmpty)
                    const Text("No friends yet.")
                  else
                    Column(
                      children: friends.map((req) {
                        // The accepted friend row comes from incoming friend requests,
                        // so the friend’s username is in the 'sender' field.
                        final String friendUsername = req['sender'] as String;
                        return ListTile(
                          title: Text("Friend Code: $friendUsername"),
                          subtitle: const Text("Accepted"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Chat button (placeholder)
                              IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Chat feature coming soon.")),
                                  );
                                },
                              ),
                              // Delete friend button.
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteFriend(friendUsername),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  const Divider(height: 30, thickness: 2),
                  // Pending Incoming Friend Requests Section
                  const Text(
                    "Received Friend Requests:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (pending.isEmpty)
                    const Text("No friend requests received.")
                  else
                    Column(
                      children: pending.map((req) {
                        final int requestId = req['id'] as int;
                        final String sender = req['sender'] as String;
                        return ListTile(
                          title: Text("From Friend Code: $sender"),
                          subtitle: const Text("Pending"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: () =>
                                    _acceptFriendRequest(requestId),
                                child: const Text("Accept"),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () =>
                                    _declineFriendRequest(requestId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text("Decline"),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
