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
}
