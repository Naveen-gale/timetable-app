// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TimetableEntryAdapter extends TypeAdapter<TimetableEntry> {
  @override
  final int typeId = 1;

  @override
  TimetableEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimetableEntry(
      id: fields[0] as String,
      day: fields[1] as int,
      type: fields[2] as EntryType,
      title: fields[3] as String,
      startHour: fields[4] as int,
      startMinute: fields[5] as int,
      endHour: fields[6] as int,
      endMinute: fields[7] as int,
      teacher: fields[8] as String,
      room: fields[9] as String,
      notificationEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TimetableEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.day)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.startHour)
      ..writeByte(5)
      ..write(obj.startMinute)
      ..writeByte(6)
      ..write(obj.endHour)
      ..writeByte(7)
      ..write(obj.endMinute)
      ..writeByte(8)
      ..write(obj.teacher)
      ..writeByte(9)
      ..write(obj.room)
      ..writeByte(10)
      ..write(obj.notificationEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimetableEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EntryTypeAdapter extends TypeAdapter<EntryType> {
  @override
  final int typeId = 0;

  @override
  EntryType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntryType.classEntry;
      case 1:
        return EntryType.breakEntry;
      default:
        return EntryType.classEntry;
    }
  }

  @override
  void write(BinaryWriter writer, EntryType obj) {
    switch (obj) {
      case EntryType.classEntry:
        writer.writeByte(0);
        break;
      case EntryType.breakEntry:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntryTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
