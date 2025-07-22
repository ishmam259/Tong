// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 1;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      senderId: fields[1] as String,
      senderNickname: fields[2] as String,
      content: fields[3] as String,
      type: fields[4] as MessageType,
      timestamp: fields[5] as DateTime,
      chatSpaceId: fields[6] as String,
      replyToId: fields[7] as String?,
      reactions: (fields[8] as List).cast<String>(),
      isEncrypted: fields[9] as bool,
      filePath: fields[10] as String?,
      fileSize: fields[11] as String?,
      isDelivered: fields[12] as bool,
      isRead: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.senderNickname)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.chatSpaceId)
      ..writeByte(7)
      ..write(obj.replyToId)
      ..writeByte(8)
      ..write(obj.reactions)
      ..writeByte(9)
      ..write(obj.isEncrypted)
      ..writeByte(10)
      ..write(obj.filePath)
      ..writeByte(11)
      ..write(obj.fileSize)
      ..writeByte(12)
      ..write(obj.isDelivered)
      ..writeByte(13)
      ..write(obj.isRead);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
