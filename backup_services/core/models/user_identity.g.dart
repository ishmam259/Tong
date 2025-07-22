// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_identity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserIdentityAdapter extends TypeAdapter<UserIdentity> {
  @override
  final int typeId = 0;

  @override
  UserIdentity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserIdentity(
      id: fields[0] as String,
      nickname: fields[1] as String,
      isAnonymous: fields[2] as bool,
      isSystemGenerated: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      avatar: fields[5] as String?,
      sessionId: fields[6] as String,
      isPermanentSession: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserIdentity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.isAnonymous)
      ..writeByte(3)
      ..write(obj.isSystemGenerated)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.avatar)
      ..writeByte(6)
      ..write(obj.sessionId)
      ..writeByte(7)
      ..write(obj.isPermanentSession);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserIdentityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
