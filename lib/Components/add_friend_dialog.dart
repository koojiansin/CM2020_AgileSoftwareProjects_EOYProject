//// filepath: /Users/shaunsevilla/Downloads/CM2020_AgileSoftwareProjects_EOYProject/lib/components/add_friend_dialog.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';

Future<void> showAddFriendDialog(
    BuildContext context, String currentUser) async {
  final TextEditingController friendCodeController = TextEditingController();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Add Friend"),
        content: TextField(
          controller: friendCodeController,
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
              final friendCode = friendCodeController.text.trim();
              if (friendCode.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a friend code.")),
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
                  .getAccountByUsername(currentUser);
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
              // Check if a friend request is already sent or friendship exists.
              final existingRequests = await DatabaseHelper.instance
                  .getFriendRequestsByOwner(currentUser);
              if (existingRequests
                  .any((req) => req['recipientFriendCode'] == friendCode)) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text("Friend request already sent or already friends."),
                  ),
                );
                return;
              }
              try {
                await DatabaseHelper.instance
                    .insertFriendRequest(currentUser, friendCode);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Friend request sent successfully.")),
                );
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
