import 'package:hive/hive.dart';

part 'exercise_session_model.g.dart';

@HiveType(typeId: 1)
class ExerciseSessionModel extends HiveObject {
  @HiveField(0)
  String exerciseName;

  @HiveField(1)
  int durationMinutes;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int? accuracyScore; // 0-100 score for form accuracy (future AI)

  @HiveField(4)
  int? reps;

  @HiveField(5)
  int? durationSeconds;

  ExerciseSessionModel({
    required this.exerciseName,
    required this.durationMinutes,
    required this.date,
    this.accuracyScore,
    this.reps, // Optional
    this.durationSeconds, // Optional
  });
}
