import '../services/networking_service.dart';

class ChatMessage {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final bool isMe;
  final bool isDelivered;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.isMe,
    this.isDelivered = true,
    this.isRead = false,
  });

  factory ChatMessage.fromNetworkMessage(
    NetworkMessage networkMessage,
    String currentUserId,
  ) {
    return ChatMessage(
      id: networkMessage.id,
      content: networkMessage.content,
      senderId: networkMessage.senderId,
      senderName: networkMessage.senderName,
      timestamp: networkMessage.timestamp,
      isMe: networkMessage.senderId == currentUserId,
    );
  }
}
