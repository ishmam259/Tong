// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_space.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatSpaceAdapter extends TypeAdapter<ChatSpace> {
  @override
  final int typeId = 2;

  @override
  ChatSpace read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatSpace(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      type: fields[3] as ChatSpaceType,
      createdAt: fields[4] as DateTime,
      createdBy: fields[5] as String,
      expiresAt: fields[6] as DateTime?,
      participants: (fields[7] as List).cast<String>(),
      permissions: (fields[8] as Map).map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      isAutoDelete: fields[9] as bool,
      autoDeleteTimeout: fields[10] as Duration?,
      isEncrypted: fields[11] as bool,
      password: fields[12] as String?,
      maxParticipants: fields[13] as int,
      isPublic: fields[14] as bool,
      tags: (fields[15] as List).cast<String>(),
      parentId: fields[16] as String?,
      allowReplies: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChatSpace obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.createdBy)
      ..writeByte(6)
      ..write(obj.expiresAt)
      ..writeByte(7)
      ..write(obj.participants)
      ..writeByte(8)
      ..write(obj.permissions)
      ..writeByte(9)
      ..write(obj.isAutoDelete)
      ..writeByte(10)
      ..write(obj.autoDeleteTimeout)
      ..writeByte(11)
      ..write(obj.isEncrypted)
      ..writeByte(12)
      ..write(obj.password)
      ..writeByte(13)
      ..write(obj.maxParticipants)
      ..writeByte(14)
      ..write(obj.isPublic)
      ..writeByte(15)
      ..write(obj.tags)
      ..writeByte(16)
      ..write(obj.parentId)
      ..writeByte(17)
      ..write(obj.allowReplies);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSpaceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
