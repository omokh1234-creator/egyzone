class ChatMessage {
  final String? message;
  final String? timestamp;
  final bool isUser;

  ChatMessage({
    this.message,
    this.timestamp,
    required this.isUser,
  });
}
