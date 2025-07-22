import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'message.g.dart';

enum MessageType { text, image, file, system, reaction }

enum ChatSpaceType { temporary, permanent, noticeBoard, forum, thread }

@HiveType(typeId: 1)
class Message extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String senderId;

  @HiveField(2)
  String senderNickname;

  @HiveField(3)
  String content;

  @HiveField(4)
  MessageType type;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  String chatSpaceId;

  @HiveField(7)
  String? replyToId;

  @HiveField(8)
  List<String> reactions;

  @HiveField(9)
  bool isEncrypted;

  @HiveField(10)
  String? filePath;

  @HiveField(11)
  String? fileSize;

  @HiveField(12)
  bool isDelivered;

  @HiveField(13)
  bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderNickname,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.chatSpaceId,
    this.replyToId,
    this.reactions = const [],
    this.isEncrypted = false,
    this.filePath,
    this.fileSize,
    this.isDelivered = false,
    this.isRead = false,
  });

  factory Message.text({
    required String senderId,
    required String senderNickname,
    required String content,
    required String chatSpaceId,
    String? replyToId,
  }) {
    return Message(
      id: const Uuid().v4(),
      senderId: senderId,
      senderNickname: senderNickname,
      content: content,
      type: MessageType.text,
      timestamp: DateTime.now(),
      chatSpaceId: chatSpaceId,
      replyToId: replyToId,
    );
  }

  factory Message.system({
    required String content,
    required String chatSpaceId,
  }) {
    return Message(
      id: const Uuid().v4(),
      senderId: 'system',
      senderNickname: 'System',
      content: content,
      type: MessageType.system,
      timestamp: DateTime.now(),
      chatSpaceId: chatSpaceId,
    );
  }

  void addReaction(String reaction) {
    if (!reactions.contains(reaction)) {
      reactions.add(reaction);
    }
  }

  void removeReaction(String reaction) {
    reactions.remove(reaction);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderNickname': senderNickname,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'chatSpaceId': chatSpaceId,
      'replyToId': replyToId,
      'reactions': reactions,
      'isEncrypted': isEncrypted,
      'filePath': filePath,
      'fileSize': fileSize,
      'isDelivered': isDelivered,
      'isRead': isRead,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      senderNickname: json['senderNickname'],
      content: json['content'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      chatSpaceId: json['chatSpaceId'],
      replyToId: json['replyToId'],
      reactions: List<String>.from(json['reactions'] ?? []),
      isEncrypted: json['isEncrypted'] ?? false,
      filePath: json['filePath'],
      fileSize: json['fileSize'],
      isDelivered: json['isDelivered'] ?? false,
      isRead: json['isRead'] ?? false,
    );
  }
}
