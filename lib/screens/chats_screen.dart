import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/Components/chat_list.dart';

class ChatListScreen extends StatefulWidget {
  final String currentUser;

  const ChatListScreen({super.key, required this.currentUser});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _refreshConversations();
  }

  void _refreshConversations() {
    setState(() {
      _conversationsFuture =
          DatabaseHelper.instance.getConversations(widget.currentUser);
    });
  }

  String _getOtherUser(Map<String, dynamic> message) {
    if (message['sender'] == widget.currentUser) {
      return message['recipient'];
    } else {
      return message['sender'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const Center(child: Text('No conversations yet'));
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final message = conversations[index];
              final otherUser = _getOtherUser(message);
              final isUnread = message['recipient'] == widget.currentUser &&
                  message['read'] == 0;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(otherUser[0].toUpperCase()),
                ),
                title: Text(otherUser),
                subtitle: Text(
                  message['content'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('h:mm a').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            message['timestamp']),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (isUnread)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        currentUser: widget.currentUser,
                        otherUser: otherUser,
                      ),
                    ),
                  );
                  // Refresh list after returning from chat
                  _refreshConversations();
                },
              );
            },
          );
        },
      ),
    );
  }
}
