// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_session_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseSessionModelAdapter extends TypeAdapter<ExerciseSessionModel> {
  @override
  final int typeId = 1;

  @override
  ExerciseSessionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExerciseSessionModel(
      exerciseName: fields[0] as String,
      durationMinutes: fields[1] as int,
      date: fields[2] as DateTime,
      accuracyScore: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ExerciseSessionModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.exerciseName)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.accuracyScore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseSessionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
