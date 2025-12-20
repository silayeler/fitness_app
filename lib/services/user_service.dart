import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math'; // Import math
import '../models/user_model.dart';
import '../models/exercise_session_model.dart';
import 'notification_service.dart';

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
      final defaultUser = UserModel(name: 'Misafir', email: '');
      _userBox.put('currentUser', defaultUser);
      return defaultUser;
    }
    return _userBox.get('currentUser')!;
  }

  Future<void> updateProfile({String? name, double? weight, double? height, String? goal}) async {
    final currentUser = user;
    if (name != null) currentUser.name = name;
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
  bool get vibrationEnabled => _settingsBox.get('vibrationEnabled', defaultValue: true);
  int get reminderHour => _settingsBox.get('reminderHour', defaultValue: 8);
  int get reminderMinute => _settingsBox.get('reminderMinute', defaultValue: 0);

  Future<void> setDarkMode(bool value) async {
    await _settingsBox.put('darkMode', value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put('notificationsEnabled', value);
    
    if (value) {
      await NotificationService().requestPermissions();
      // Schedule with current time
      final h = reminderHour;
      final m = reminderMinute;
      await NotificationService().scheduleDailyReminder(h, m);
    } else {
      await NotificationService().cancelDailyReminder();
    }
    }


  Future<void> setSoundEnabled(bool value) async {
    await _settingsBox.put('soundEnabled', value);
  }

  Future<void> setVibrationEnabled(bool value) async {
    await _settingsBox.put('vibrationEnabled', value);
  }

  Future<void> setReminderTime(int hour, int minute) async {
    await _settingsBox.put('reminderHour', hour);
    await _settingsBox.put('reminderMinute', minute);
    
    // Reschedule if enabled
    if (notificationsEnabled) {
       await NotificationService().scheduleDailyReminder(hour, minute);
    }
  }

  // --- Onboarding Persistence ---

  bool get onboardingSeen => _settingsBox.get('onboardingSeen', defaultValue: false);

  Future<void> setOnboardingSeen() async {
    await _settingsBox.put('onboardingSeen', true);
  }

  // --- Session History Management ---

  Box<ExerciseSessionModel> get _sessionBox => Hive.box<ExerciseSessionModel>(_sessionBoxName);

  ValueListenable<Box<ExerciseSessionModel>> get sessionListenable => _sessionBox.listenable();

  List<ExerciseSessionModel> get sessions {
     // Return reversed list (newest first)
     return _sessionBox.values.toList().reversed.toList();
  }

  Future<void> addSession(String exerciseName, int durationMinutes, int accuracyScore) async {
    final session = ExerciseSessionModel(
      exerciseName: exerciseName,
      durationMinutes: durationMinutes,
      date: DateTime.now(),
      accuracyScore: accuracyScore, 
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


  Future<void> clearAllData() async {
    await _sessionBox.clear();
  }

  // --- Gamification Logic ---

  Future<void> addXp(int amount) async {
    final currentUser = user;
    currentUser.currentXp += amount;

    // Level Calculation: Level = sqrt(XP / 100) + 1
    // 0 XP -> Lvl 1
    // 100 XP -> Lvl 2
    // 400 XP -> Lvl 3
    int newLevel = (sqrt(currentUser.currentXp / 100)).floor() + 1;
    
    if (newLevel > currentUser.currentLevel) {
      currentUser.currentLevel = newLevel;
      // TODO: Show Level Up Dialog (handled by UI observing userListenable)
    }
    
    await currentUser.save();
    
    // Check Badges
    await _checkBadges();
  }

  Future<void> _checkBadges() async {
    final currentUser = user;
    final earned = currentUser.earnedBadges.toSet();
    bool changed = false;

    // Check "First Step"
    if (!earned.contains('first_step')) {
      if (sessions.isNotEmpty) {
        currentUser.earnedBadges.add('first_step');
        changed = true;
      }
    }

    // Check "Consistent" (3 days streak)
    if (!earned.contains('consistent')) {
      final stats = getStats();
      // Parsing "3 gün" string or refactoring getStats to return int is better.
      // For now, let's just check stats['streak']
      // This is a bit fragile string parsing but works for MVP
      String streakStr = stats['streak'] ?? '0';
      int streak = int.tryParse(streakStr.split(' ')[0]) ?? 0;
      
      if (streak >= 3) {
        currentUser.earnedBadges.add('consistent');
        changed = true;
      }
    }

    // Check "Champion" (Level 10)
    if (!earned.contains('champion')) {
      if (currentUser.currentLevel >= 10) {
        currentUser.earnedBadges.add('champion');
        changed = true;
      }
    }

    if (changed) {
      await currentUser.save();
    }
  }
}
