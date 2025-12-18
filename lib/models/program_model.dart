class ProgramModel {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final int durationWeeks;
  final String imagePath;
  final List<DailyWorkout> schedule;

  const ProgramModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.durationWeeks,
    required this.imagePath,
    required this.schedule,
  });
}

class DailyWorkout {
  final int dayNumber;
  final String title;
  final List<String> exercises; // List of exercise names (e.g., 'Squat', 'Plank')
  final bool isRestDay;

  const DailyWorkout({
    required this.dayNumber,
    required this.title,
    this.exercises = const [],
    this.isRestDay = false,
  });
}
