import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'message.dart';

part 'chat_space.g.dart';

enum PermissionType { read, write, react, admin }

@HiveType(typeId: 2)
class ChatSpace extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  ChatSpaceType type;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String createdBy;

  @HiveField(6)
  DateTime? expiresAt;

  @HiveField(7)
  List<String> participants;

  @HiveField(8)
  Map<String, List<String>> permissions; // userId -> [permissions]

  @HiveField(9)
  bool isAutoDelete;

  @HiveField(10)
  Duration? autoDeleteTimeout;

  @HiveField(11)
  bool isEncrypted;

  @HiveField(12)
  String? password;

  @HiveField(13)
  int maxParticipants;

  @HiveField(14)
  bool isPublic;

  @HiveField(15)
  List<String> tags;

  @HiveField(16)
  String? parentId; // For threads

  @HiveField(17)
  bool allowReplies;

  ChatSpace({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.createdAt,
    required this.createdBy,
    this.expiresAt,
    this.participants = const [],
    this.permissions = const {},
    this.isAutoDelete = false,
    this.autoDeleteTimeout,
    this.isEncrypted = false,
    this.password,
    this.maxParticipants = 100,
    this.isPublic = false,
    this.tags = const [],
    this.parentId,
    this.allowReplies = true,
  });

  factory ChatSpace.temporary({
    required String name,
    required String createdBy,
    Duration? timeout,
    String? description,
    bool isEncrypted = false,
  }) {
    final uuid = const Uuid();
    final now = DateTime.now();

    return ChatSpace(
      id: uuid.v4(),
      name: name,
      description: description,
      type: ChatSpaceType.temporary,
      createdAt: now,
      createdBy: createdBy,
      expiresAt:
          timeout != null
              ? now.add(timeout)
              : now.add(const Duration(hours: 24)),
      isAutoDelete: true,
      autoDeleteTimeout: timeout ?? const Duration(hours: 24),
      isEncrypted: isEncrypted,
      participants: [createdBy],
      permissions: {
        createdBy: [
          PermissionType.read.name,
          PermissionType.write.name,
          PermissionType.react.name,
          PermissionType.admin.name,
        ],
      },
    );
  }

  factory ChatSpace.permanent({
    required String name,
    required String createdBy,
    String? description,
    bool isPublic = false,
    bool isEncrypted = false,
    String? password,
  }) {
    final uuid = const Uuid();

    return ChatSpace(
      id: uuid.v4(),
      name: name,
      description: description,
      type: ChatSpaceType.permanent,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isEncrypted: isEncrypted,
      password: password,
      isPublic: isPublic,
      participants: [createdBy],
      permissions: {
        createdBy: [
          PermissionType.read.name,
          PermissionType.write.name,
          PermissionType.react.name,
          PermissionType.admin.name,
        ],
      },
    );
  }

  factory ChatSpace.noticeBoard({
    required String name,
    required String createdBy,
    String? description,
    bool isPublic = true,
  }) {
    final uuid = const Uuid();

    return ChatSpace(
      id: uuid.v4(),
      name: name,
      description: description,
      type: ChatSpaceType.noticeBoard,
      createdAt: DateTime.now(),
      createdBy: createdBy,
      isPublic: isPublic,
      allowReplies: false,
      participants: [createdBy],
      permissions: {
        createdBy: [
          PermissionType.read.name,
          PermissionType.write.name,
          PermissionType.admin.name,
        ],
      },
    );
  }

  bool hasPermission(String userId, PermissionType permission) {
    final userPermissions = permissions[userId] ?? [];
    return userPermissions.contains(permission.name) ||
        userPermissions.contains(PermissionType.admin.name);
  }

  void addParticipant(
    String userId, {
    List<PermissionType> perms = const [
      PermissionType.read,
      PermissionType.write,
      PermissionType.react,
    ],
  }) {
    if (!participants.contains(userId)) {
      participants.add(userId);
      permissions[userId] = perms.map((p) => p.name).toList();
    }
  }

  void removeParticipant(String userId) {
    participants.remove(userId);
    permissions.remove(userId);
  }

  void updatePermissions(String userId, List<PermissionType> perms) {
    if (participants.contains(userId)) {
      permissions[userId] = perms.map((p) => p.name).toList();
    }
  }

  bool isExpired() {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'expiresAt': expiresAt?.toIso8601String(),
      'participants': participants,
      'permissions': permissions,
      'isAutoDelete': isAutoDelete,
      'autoDeleteTimeout': autoDeleteTimeout?.inMilliseconds,
      'isEncrypted': isEncrypted,
      'password': password,
      'maxParticipants': maxParticipants,
      'isPublic': isPublic,
      'tags': tags,
      'parentId': parentId,
      'allowReplies': allowReplies,
    };
  }

  factory ChatSpace.fromJson(Map<String, dynamic> json) {
    return ChatSpace(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      type: ChatSpaceType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      participants: List<String>.from(json['participants'] ?? []),
      permissions: Map<String, List<String>>.from(
        json['permissions']?.map(
              (key, value) => MapEntry(key, List<String>.from(value)),
            ) ??
            {},
      ),
      isAutoDelete: json['isAutoDelete'] ?? false,
      autoDeleteTimeout:
          json['autoDeleteTimeout'] != null
              ? Duration(milliseconds: json['autoDeleteTimeout'])
              : null,
      isEncrypted: json['isEncrypted'] ?? false,
      password: json['password'],
      maxParticipants: json['maxParticipants'] ?? 100,
      isPublic: json['isPublic'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      parentId: json['parentId'],
      allowReplies: json['allowReplies'] ?? true,
    );
  }
}
