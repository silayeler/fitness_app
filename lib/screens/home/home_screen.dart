import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_router.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutoRouteAwareStateMixin<HomeScreen> {
  String _name = '...'; 
  String _lastExerciseTitle = 'Henüz yok';
  String _lastExerciseSubtitle = 'Hadi ilk antrenmanını yap!';
  double _dailyProgress = 0.0;
  String _dailyProgressText = '0%';
  String _dailyTargetText = '3 Egzersiz Seansı';

  @override
  void initState() {
    super.initState();
    _initNotifications(); // Request permissions and load data
  }

  Future<void> _initNotifications() async {
    await NotificationService().requestPermissions();
    _loadData();
  }

  @override
  void didPushNext() {
    _loadData(); 
  }
  
  @override
  void didPopNext() {
    _loadData();
  }

  Future<void> _loadData() async {
    final user = UserService().user; // Hive box is sync
    final sessions = UserService().sessions;
    
    String title = 'Henüz yok';
    String subtitle = 'Hadi ilk antrenmanını yap!';
    
    if (sessions.isNotEmpty) {
      final last = sessions.first; // Newest is first
      title = "${last.date.day}.${last.date.month} - ${last.exerciseName}";
      subtitle = "${last.durationMinutes} dakika çalıştın!";
    }
    
    // Progress
    final progressData = UserService().getTodayProgress();
    final double prog = progressData['progress'];
    final int percent = progressData['percent'];
    final int completed = progressData['completed'];

    if (mounted) {
      setState(() {
        _name = user.name.split(' ')[0];
        _lastExerciseTitle = title;
        _lastExerciseSubtitle = subtitle;
        _dailyProgress = prog;
        _dailyProgressText = '$percent%';
        _dailyTargetText = '$completed / 3 Tamamlandı'; // Showing count instead of static "3 Egzersiz Seansı"
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.router.push(SettingsRoute());
            },
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık (Greeting)
              ValueListenableBuilder(
                valueListenable: UserService().userListenable,
                builder: (context, box, _) {
                  final currentName = UserService().user.name.split(' ')[0];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, $currentName!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bugün hedefin:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Hedef kartı
                      Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark 
                              ? const Color(0xFF1B5E20).withValues(alpha: 0.3) // Darker green for dark mode
                              : const Color(0xFFF4FFF7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark 
                                    ? const Color(0xFF00C853).withValues(alpha: 0.2)
                                    : const Color(0xFFE0F8EA),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.directions_run_rounded,
                                color: Color(0xFF00C853),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hedef',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: Colors.grey[700]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Günlük Hedef: 3 Seans',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bugün planlanan antrenmanını tamamla.',
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Son başarılar
                      Text(
                        'Son başarıların',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFFE65100).withValues(alpha: 0.2)
                              : const Color(0xFFFFF7EC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFFFF9800).withValues(alpha: 0.2)
                                    : const Color(0xFFFFE2C2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.emoji_events_outlined,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Başarı',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(color: Colors.green[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _lastExerciseTitle,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _lastExerciseSubtitle,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hedef tamamlama
                      Text(
                        'Hedef Tamamlama',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _dailyProgress,
                          minHeight: 10,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF00C853)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$_dailyProgressText ($_dailyTargetText)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),

                      const Spacer(),
                      Center(
                        child: Text(
                          '"Her gün biraz daha iyi ol!"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
