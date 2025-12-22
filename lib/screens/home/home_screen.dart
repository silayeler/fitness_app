import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../services/notification_service.dart';
import '../../routes/app_router.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/weekly_activity_graph.dart';

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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700, // Reduced from w900
          fontSize: 24, // Explicit size for consistency
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        actions: [
          // Streak Counter
          ValueListenableBuilder(
            valueListenable: UserService().sessionListenable,
            builder: (context, _, __) {
              final stats = UserService().getStats();
              final streak = stats['streak'] ?? '0 gün';
              return Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0B2), // Orange-ish bg
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF9800), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      streak,
                      style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         color: Color(0xFFE65100),
                         fontSize: 12
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.05),
                   blurRadius: 10,
                   offset: const Offset(0, 5),
                   ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined),
              color: theme.colorScheme.onSurface,
              onPressed: () {
                context.router.push(SettingsRoute());
              },
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık (Greeting)
              ValueListenableBuilder(
                valueListenable: UserService().userListenable,
                builder: (context, box, _) {
                  final user = UserService().user;
                  final currentName = user.name.split(' ')[0];
                  final isGuest = user.name == 'Misafir';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, $currentName!',
                        style: theme.textTheme.headlineSmall?.copyWith( // Changed to headlineSmall for hierarchy
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF00C853),
                        ),
                      ),
                      if (isGuest) ...[
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.router.push(const ProfileRoute()),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF00C853).withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.person_add_rounded, color: Color(0xFF00C853)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Henüz bir profil oluşturmadın! Adını profilinden girerek başlayabilirsin.',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF00C853)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // Hızlı Başlat Kartları
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    QuickActionCard(
                      title: 'Squat',
                      duration: '20 Adet',
                      imagePath: 'assets/images/gorsel_2.jpg',
                      color: const Color(0xFF2196F3),
                      onTap: () {
                        context.router.push(
                          ExerciseSessionRoute(exerciseName: 'Squat'),
                        );
                      },
                    ),
                    QuickActionCard(
                      title: 'Mekik',
                      duration: '30 Adet',
                      imagePath: 'assets/images/gorsel_4.png',
                      color: const Color(0xFFFF9800),
                      onTap: () {
                         context.router.push(
                          ExerciseSessionRoute(exerciseName: 'Mekik'),
                        );
                      },
                    ),
                    QuickActionCard(
                      title: 'Plank',
                      duration: '1 dk',
                      imagePath: 'assets/images/gorsel_3.png',
                      color: const Color(0xFF9C27B0),
                      onTap: () {
                         context.router.push(
                          ExerciseSessionRoute(exerciseName: 'Plank'),
                        );
                      },
                    ),
                    QuickActionCard(
                      title: 'Ağırlık',
                      duration: '15 dk',
                      imagePath: 'assets/images/gorsel_1.png',
                      color: const Color(0xFFF44336),
                      onTap: () {
                         context.router.push(
                          ExerciseSessionRoute(exerciseName: 'Ağırlık'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Weekly Graph (Added)
              ValueListenableBuilder(
                valueListenable: UserService().sessionListenable,
                builder: (context, box, _) {
                  return const WeeklyActivityGraph();
                },
              ),

              const SizedBox(height: 24),

              // Programs Entry Point
              GestureDetector(
                onTap: () {
                   context.router.push(const ProgramsRoute());
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1565C0), // Dark Blue
                        const Color(0xFF1E88E5), // Lighter Blue
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Özel Programlar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '30 Günlük meydan okumalar ve planlar.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              
              Container(
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
                        fontSize: 18, // Slightly larger for readability
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
                        fontSize: 18,
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
                    if (_dailyProgress > 0) ...[
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
                    ] else ...[
                      // Empty State
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                           color: theme.scaffoldBackgroundColor,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             const Icon(Icons.rocket_launch_rounded, size: 20, color: Color(0xFF00C853)),
                             const SizedBox(width: 8),
                             Text(
                               "Hadi başlayalım! 🚀",
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 fontWeight: FontWeight.w600,
                                 color: theme.colorScheme.onSurface,
                               ),
                             ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24), 
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: theme.brightness == Brightness.dark
                              ? [const Color(0xFF263238), const Color(0xFF37474F)]
                              : [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.format_quote_rounded, color: const Color(0xFF00C853).withValues(alpha: 0.5), size: 32),
                          const SizedBox(height: 12),
                          Text(
                            "Her gün biraz daha iyi ol!",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
