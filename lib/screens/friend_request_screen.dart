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
  Future<void> _showAddFriendDialog() async {
    final TextEditingController _dialogFriendCodeController =
        TextEditingController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Add Friend"),
          content: TextField(
            controller: _dialogFriendCodeController,
            decoration: const InputDecoration(
              labelText: "Friend Code",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final friendCode = _dialogFriendCodeController.text.trim();
                if (friendCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please enter a friend code.")),
                  );
                  return;
                }
                // Validate that the provided friend code exists.
                final targetAccount = await DatabaseHelper.instance
                    .getAccountByFriendCode(friendCode);
                if (targetAccount == null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Friend code not found.")),
                  );
                  return;
                }
                // Get current user's account details.
                final currentAccount = await DatabaseHelper.instance
                    .getAccountByUsername(widget.currentUser);
                if (currentAccount == null) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Current account not found.")),
                  );
                  return;
                }
                // Prevent self-friendship.
                if (friendCode == currentAccount['friendCode']) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("You cannot add yourself as a friend.")),
                  );
                  return;
                }
                // Check if a friend request is already sent or friendship already exists.
                final existingRequests = await DatabaseHelper.instance
                    .getFriendRequestsByOwner(widget.currentUser);
                if (existingRequests
                    .any((req) => req['recipientFriendCode'] == friendCode)) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            "Friend request already sent or already friends.")),
                  );
                  return;
                }
                try {
                  await DatabaseHelper.instance
                      .insertFriendRequest(widget.currentUser, friendCode);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Friend request sent successfully.")),
                  );
                  setState(() {}); // refresh the list
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Failed to send friend request.")),
                  );
                }
              },
              child: const Text("Send Request"),
            ),
          ],
        );
      },
    );
  }

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
      await DatabaseHelper.instance.acceptFriendRequest(requestId);
      // Retrieve and create the reciprocal record if needed.
      final req = await DatabaseHelper.instance.getFriendRequestById(requestId);
      if (req != null) {
        final String senderUsername = req['sender'] as String;
        final senderAccount =
            await DatabaseHelper.instance.getAccountByUsername(senderUsername);
        if (senderAccount != null) {
          final String senderFriendCode = senderAccount['friendCode'] as String;
          final reciprocalRequests = await DatabaseHelper.instance
              .getFriendRequestsByOwner(widget.currentUser);
          bool alreadyInserted = reciprocalRequests.any((r) =>
              r['recipientFriendCode'] == senderFriendCode &&
              r['status'] == 'accepted');
          if (!alreadyInserted) {
            await DatabaseHelper.instance
                .insertFriendRequest(widget.currentUser, senderFriendCode);
            final newReciprocals = await DatabaseHelper.instance
                .getFriendRequestsByOwner(widget.currentUser);
            final newReciprocal = newReciprocals.firstWhere(
                (r) => r['recipientFriendCode'] == senderFriendCode);
            await DatabaseHelper.instance
                .acceptFriendRequest(newReciprocal['id'] as int);
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Friend Requests")),
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
                        final String sender = req['sender'] as String;
                        return ListTile(
                          title: Text("Friend Code: $sender"),
                          subtitle: const Text("Accepted"),
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
                                    backgroundColor: Colors.red),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
