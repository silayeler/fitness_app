import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/exercise_session_model.dart';

class UserService {
  static const String _userBoxName = 'userBox';
  static const String _sessionBoxName = 'sessionBox';

  // Singleton
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Initialize Hive (Call this in main.dart)
  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(UserModelAdapter());
    Hive.registerAdapter(ExerciseSessionModelAdapter());
    
    await Hive.openBox<UserModel>(_userBoxName);
    await Hive.openBox<ExerciseSessionModel>(_sessionBoxName);
    await Hive.openBox('settingsBox'); // Generic box for settings
  }

  // --- Profile Management ---
  
  Box<UserModel> get _userBox => Hive.box<UserModel>(_userBoxName);
  
  // Listenable for reactive UI updates
  ValueListenable<Box<UserModel>> get userListenable => _userBox.listenable();
  
  // Get current user or create default
  UserModel get user {
    if (_userBox.isEmpty) {
      // Create default
      final defaultUser = UserModel(name: 'Elif Tan', email: 'elif@example.com');
      _userBox.put('currentUser', defaultUser);
      return defaultUser;
    }
    return _userBox.get('currentUser')!;
  }

  Future<void> updateProfile({String? name, String? email, double? weight, double? height, String? goal}) async {
    final currentUser = user;
    if (name != null) currentUser.name = name;
    if (email != null) currentUser.email = email;
    if (weight != null) currentUser.weight = weight;
    if (height != null) currentUser.height = height;
    if (goal != null) currentUser.goal = goal;
    
    await currentUser.save(); // HiveObject extension method
  }

  // --- Settings ---
  
  Box get _settingsBox => Hive.box('settingsBox');
  
  ValueListenable<Box> get settingsListenable => _settingsBox.listenable();

  bool get isDarkMode => _settingsBox.get('darkMode', defaultValue: false);
  bool get notificationsEnabled => _settingsBox.get('notificationsEnabled', defaultValue: true);
  bool get soundEnabled => _settingsBox.get('soundEnabled', defaultValue: true);

  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('darkMode', value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put('notificationsEnabled', value);
  }

  Future<void> setSoundEnabled(bool value) async {
    await _settingsBox.put('soundEnabled', value);
  }

  // --- Session History Management ---

  Box<ExerciseSessionModel> get _sessionBox => Hive.box<ExerciseSessionModel>(_sessionBoxName);

  ValueListenable<Box<ExerciseSessionModel>> get sessionListenable => _sessionBox.listenable();

  List<ExerciseSessionModel> get sessions {
     // Return reversed list (newest first)
     return _sessionBox.values.toList().reversed.toList();
  }

  Future<void> addSession(String exerciseName, int durationMinutes) async {
    final session = ExerciseSessionModel(
      exerciseName: exerciseName,
      durationMinutes: durationMinutes,
      date: DateTime.now(),
      accuracyScore: 85, // Mock score for now until AI is ready
    );
    await _sessionBox.add(session);
  }
  
  // --- Dashboard Stats ---
  
  Map<String, String> getStats() {
    final allSessions = sessions;
    int totalCount = allSessions.length;
    int totalMinutes = allSessions.fold(0, (sum, item) => sum + item.durationMinutes);
    
    // Format minutes
    int h = totalMinutes ~/ 60;
    int m = totalMinutes % 60;
    String timeStr = '${h > 0 ? '${h}s ' : ''}${m}d';
    
    // Streak calculation (Simplified)
    // In a real app, check consecutive days. For now, just return a mock or count unique days.
    Set<String> uniqueDays = allSessions.map((s) => "${s.date.year}-${s.date.month}-${s.date.day}").toSet();
    
    return {
      'sessions': '$totalCount',
      'time': timeStr,
      'streak': '${uniqueDays.length} gün',
    };
  }
  
  // --- Daily Goal Logic ---
  Map<String, dynamic> getTodayProgress() {
    final now = DateTime.now();
    final todaySessions = sessions.where((s) {
      return s.date.year == now.year && 
             s.date.month == now.month && 
             s.date.day == now.day;
    }).toList();
    
    int completed = todaySessions.length;
    int target = 3; // Default daily target
    double progress = (completed / target).clamp(0.0, 1.0);
    
    return {
      'completed': completed,
      'target': target,
      'progress': progress,
      'percent': (progress * 100).toInt(),
    };
  }
}
