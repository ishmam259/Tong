class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final bool isOnline;
  final String deviceInfo;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.profileImageUrl,
    required this.createdAt,
    required this.lastActiveAt,
    this.isOnline = false,
    this.deviceInfo = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
      lastActiveAt:
          json['lastActiveAt'] != null
              ? DateTime.parse(json['lastActiveAt'])
              : DateTime.now(),
      isOnline: json['isOnline'] ?? false,
      deviceInfo: json['deviceInfo'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isOnline': isOnline,
      'deviceInfo': deviceInfo,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    bool? isOnline,
    String? deviceInfo,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isOnline: isOnline ?? this.isOnline,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}
