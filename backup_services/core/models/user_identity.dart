import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user_identity.g.dart';

@HiveType(typeId: 0)
class UserIdentity extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  bool isAnonymous;

  @HiveField(3)
  bool isSystemGenerated;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? avatar;

  @HiveField(6)
  String sessionId;

  @HiveField(7)
  bool isPermanentSession;

  UserIdentity({
    required this.id,
    required this.nickname,
    required this.isAnonymous,
    required this.isSystemGenerated,
    required this.createdAt,
    this.avatar,
    required this.sessionId,
    required this.isPermanentSession,
  });

  factory UserIdentity.anonymous({String? customNickname}) {
    final uuid = const Uuid();
    final nicknames = [
      'Anonymous Fox',
      'Silent Wolf',
      'Mystic Raven',
      'Shadow Cat',
      'Digital Ghost',
      'Cyber Phantom',
      'Virtual Wanderer',
      'Unknown Entity',
    ];

    return UserIdentity(
      id: uuid.v4(),
      nickname:
          customNickname ??
          nicknames[DateTime.now().millisecond % nicknames.length],
      isAnonymous: true,
      isSystemGenerated: customNickname == null,
      createdAt: DateTime.now(),
      sessionId: uuid.v4(),
      isPermanentSession: false,
    );
  }

  factory UserIdentity.registered({
    required String nickname,
    String? avatar,
    bool isPermanent = true,
  }) {
    final uuid = const Uuid();

    return UserIdentity(
      id: uuid.v4(),
      nickname: nickname,
      isAnonymous: false,
      isSystemGenerated: false,
      createdAt: DateTime.now(),
      avatar: avatar,
      sessionId: uuid.v4(),
      isPermanentSession: isPermanent,
    );
  }

  void regenerateSession() {
    sessionId = const Uuid().v4();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'isAnonymous': isAnonymous,
      'isSystemGenerated': isSystemGenerated,
      'createdAt': createdAt.toIso8601String(),
      'avatar': avatar,
      'sessionId': sessionId,
      'isPermanentSession': isPermanentSession,
    };
  }

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    return UserIdentity(
      id: json['id'],
      nickname: json['nickname'],
      isAnonymous: json['isAnonymous'],
      isSystemGenerated: json['isSystemGenerated'],
      createdAt: DateTime.parse(json['createdAt']),
      avatar: json['avatar'],
      sessionId: json['sessionId'],
      isPermanentSession: json['isPermanentSession'],
    );
  }
}
