import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/models/message.dart';
import 'package:lgpokemon/models/card.dart' as model;

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

  bool _isBase64(String s) => s.length > 100;

  // Handle declining a card offer
  Future<void> _declineCardOffer(int? messageId) async {
    if (messageId == null) return;

    // Update the message to indicate declined offer
    await DatabaseHelper.instance.updateMessageContent(
      messageId,
      'CARD_OFFER_DECLINED: I declined the offer.',
    );

    // Send a response message
    final responseMessage = {
      'sender': widget.currentUser,
      'recipient': widget.otherUser,
      'content': 'I declined your card offer.',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'read': 0,
    };

    await DatabaseHelper.instance.insertMessage(responseMessage);
    _refreshMessages();
  }

  // Handle accepting a card offer
  Future<void> _acceptCardOffer(
      int? messageId, int cardId, String seller, String buyer) async {
    if (messageId == null) return;

    // Transfer the card from seller to buyer
    final success =
        await DatabaseHelper.instance.transferCard(cardId, seller, buyer);

    if (success) {
      // Update the message to indicate accepted offer
      await DatabaseHelper.instance.updateMessageContent(
        messageId,
        'CARD_OFFER_ACCEPTED: Card has been transferred successfully!',
      );

      // Send a confirmation message
      final confirmationMessage = {
        'sender': widget.currentUser,
        'recipient': widget.otherUser,
        'content': 'I accepted your offer and sold the card!',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'read': 0,
      };

      await DatabaseHelper.instance.insertMessage(confirmationMessage);
      _refreshMessages();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Card transferred successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to transfer card. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build a special widget for card offer messages
  Widget _buildCardOfferMessage(Message message, bool isMe, DateTime time) {
    // Check if it's already accepted or declined
    if (message.content.startsWith('CARD_OFFER_ACCEPTED:')) {
      return _buildCardOfferStatusMessage(
        message,
        isMe,
        time,
        'Accepted',
        Colors.green.shade100,
        Colors.green,
        Icons.check_circle,
      );
    }

    if (message.content.startsWith('CARD_OFFER_DECLINED:')) {
      return _buildCardOfferStatusMessage(
        message,
        isMe,
        time,
        'Declined',
        Colors.red.shade100,
        Colors.red,
        Icons.cancel,
      );
    }

    // Regular card offer - parse the data
    final parts = message.content.split(':');
    if (parts.length < 3) return const SizedBox(); // Invalid format

    final cardId = int.tryParse(parts[1]);
    final price = double.tryParse(parts[2]);
    if (cardId == null || price == null)
      return const SizedBox(); // Invalid data

    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseHelper.instance.getUserCardById(cardId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(); // Card not found or was deleted
        }

        final card = model.Card.fromMap(snapshot.data!);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
          color: isMe ? Colors.blue.shade100 : Colors.green.shade100,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard),
                    const SizedBox(width: 8),
                    Text(
                      isMe ? 'Card Offer Sent' : 'Card Offer Received',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _isBase64(card.imagePath)
                          ? Image.memory(
                              base64Decode(card.imagePath),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              card.imagePath,
                              fit: BoxFit.cover,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Grade: ${card.grade}'),
                          Text(
                            'Offer: \$${price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Sent: ${DateFormat('MMM d, h:mm a').format(time)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (!isMe) // Show accept/decline buttons only to the card owner
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => _declineCardOffer(message.id),
                          child: const Text('Decline'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptCardOffer(
                            message.id,
                            cardId,
                            widget
                                .currentUser, // seller (recipient of the offer)
                            message.sender, // buyer (sender of the offer)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text('Accept & Sell'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Build a message showing the status of a card offer (accepted/declined)
  Widget _buildCardOfferStatusMessage(
    Message message,
    bool isMe,
    DateTime time,
    String status,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
                Text(
                  'Card Offer $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.content.split(':')[1].trim(),
              style: TextStyle(color: textColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(time),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
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

                    // Check if this is a card offer or related message
                    if (message.content.startsWith('CARD_OFFER:') ||
                        message.content.startsWith('CARD_OFFER_ACCEPTED:') ||
                        message.content.startsWith('CARD_OFFER_DECLINED:')) {
                      return _buildCardOfferMessage(message, isMe, time);
                    }

                    // Regular message rendering
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
