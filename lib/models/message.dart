class Message {
  final int? id;
  final String sender;
  final String recipient;
  final String content;
  final int timestamp;
  final bool read;

  Message({
    this.id,
    required this.sender,
    required this.recipient,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sender: map['sender'],
      recipient: map['recipient'],
      content: map['content'],
      timestamp: map['timestamp'],
      read: map['read'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'recipient': recipient,
      'content': content,
      'timestamp': timestamp,
      'read': read ? 1 : 0,
    };
  }

  // Helper method to check if this is a card offer message
  bool get isCardOffer => content.startsWith('CARD_OFFER:');

  // Helper method to check if this is an accepted card offer
  bool get isCardOfferAccepted => content.startsWith('CARD_OFFER_ACCEPTED:');

  // Helper method to check if this is a declined card offer
  bool get isCardOfferDeclined => content.startsWith('CARD_OFFER_DECLINED:');

  // Parse card ID from an offer message
  int? getCardIdFromOffer() {
    if (!isCardOffer) return null;

    final parts = content.split(':');
    if (parts.length < 2) return null;

    return int.tryParse(parts[1]);
  }

  // Parse price from an offer message
  double? getPriceFromOffer() {
    if (!isCardOffer) return null;

    final parts = content.split(':');
    if (parts.length < 3) return null;

    return double.tryParse(parts[2]);
  }
}
