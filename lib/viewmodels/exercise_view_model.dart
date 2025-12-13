import 'package:flutter/foundation.dart';

/// ExerciseViewModel
/// Egzersiz seçimi, önizleme ve seans ekranları için kullanılacak
/// temel MVVM iskeleti.
class ExerciseViewModel extends ChangeNotifier {
  String _selectedExerciseId = '';

  String get selectedExerciseId => _selectedExerciseId;

  void selectExercise(String id) {
    _selectedExerciseId = id;
    notifyListeners();
  }
}


