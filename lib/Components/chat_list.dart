import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/models/message.dart';

class ChatScreen extends StatefulWidget {
  final String currentUser;
  final String otherUser;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.otherUser,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Future<List<Map<String, dynamic>>> _messagesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMessages();
    // Mark messages as read when opening chat
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshMessages() {
    setState(() {
      _messagesFuture = DatabaseHelper.instance.getMessagesBetweenUsers(
        widget.currentUser,
        widget.otherUser,
      );
    });
  }

  Future<void> _markMessagesAsRead() async {
    await DatabaseHelper.instance.markMessagesAsRead(
      widget.otherUser,
      widget.currentUser,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'sender': widget.currentUser,
      'recipient': widget.otherUser,
      'content': _messageController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': 0,
    };

    await DatabaseHelper.instance.insertMessage(message);
    _messageController.clear();
    _refreshMessages();

    // Scroll to bottom after new message is added
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _messagesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }

                // Scroll to bottom after messages are loaded
                Future.delayed(
                    const Duration(milliseconds: 100), _scrollToBottom);

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = Message.fromMap(messages[index]);
                    final bool isMe = message.sender == widget.currentUser;
                    final time =
                        DateTime.fromMillisecondsSinceEpoch(message.timestamp);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          if (isMe) const Spacer(),

                          // Limit width to 80% of screen
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('h:mm a').format(time),
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white.withOpacity(0.7)
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (!isMe) const Spacer(),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  offset: const Offset(0, -1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Theme.of(context).primaryColor,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
