class User {
  final String id;
  final String email;
  final String username;

  User({required this.id, required this.email, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      username: json['username'],
    );
  }
}

class Message {
  final String id;
  final String? senderId;
  final String? receiverId;
  final String messageText;
  final DateTime createdAt;

  Message({
    required this.id,
    this.senderId,
    this.receiverId,
    required this.messageText,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      messageText: json['message_text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final bool readStatus;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.readStatus,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      readStatus: json['read_status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
