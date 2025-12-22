import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../widgets/bmi_gauge_card.dart';
import '../../routes/app_router.dart';
import '../../data/badge_data.dart'; // Import this


@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '...'; 

  // Stats
  String _totalSessions = '0';
  String _totalTime = '0d';
  String _streak = '0 gün';
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = UserService().user; // Sync access now possible usually, but keeps future structure if needed or just direct
    // Actually UserService().user is synchronous now if box is open.
    final stats = UserService().getStats();
    
    if (mounted) {
      setState(() {
        _name = user.name;

        _totalSessions = stats['sessions']!;
        _totalTime = stats['time']!;
        _streak = stats['streak']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
        actions: [
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Üst profil kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),

              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF00C853),
                    child: Text(
                      _name.isNotEmpty
                          ? _name.trim().split(' ').map((e) => e[0]).take(2).join()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),

                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded),
                    onPressed: () async {
                      await _showEditProfileDialog(context);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // İstatistikler
            // İstatistikler (Reactive)
            ValueListenableBuilder(
              valueListenable: UserService().sessionListenable,
              builder: (context, box, _) {
                final stats = UserService().getStats();
                return Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Toplam seans',
                        value: stats['sessions']!,
                        icon: Icons.fitness_center_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Toplam süre',
                        value: stats['time']!,
                        icon: Icons.timer_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Streak',
                        value: stats['streak']!,
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            
            // BMI Gauge (Added)
            BMIGaugeCard(
              weight: UserService().user.weight, // Pass actual nullable value
              height: UserService().user.height, // Pass actual nullable value
              onAddInfo: () async {
                 await _showEditProfileDialog(context);
              },
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 24),
            
            // Premium Level Progress Card
            ValueListenableBuilder(
              valueListenable: UserService().userListenable,
              builder: (context, box, _) {
                final user = UserService().user; // Get fresh user
                
                int currentLvl = user.currentLevel;
                int nextLvl = currentLvl + 1;
                
                int xpForCurrent = 100 * (currentLvl - 1) * (currentLvl - 1);
                int xpForNext = 100 * currentLvl * currentLvl;
                int xpNeeded = xpForNext - xpForCurrent;
                int xpProgress = user.currentXp - xpForCurrent;
                int xpRemaining = xpForNext - user.currentXp;
                
                double progress = (xpProgress / xpNeeded).clamp(0.0, 1.0);

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C3E50), Color(0xFF000000)], // Sleek Dark Luxe
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SEVİYE $currentLvl",
                                style: const TextStyle(
                                  color: Color(0xFFFFD700), // Gold
                                  fontWeight: FontWeight.w900,
                                  fontSize: 28,
                                  letterSpacing: 1.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Şampiyon Yolunda", // Dynamic title could go here
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Progress Bar
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${user.currentXp} XP',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12
                                ),
                              ),
                              Text(
                                '${xpRemaining} XP kaldı',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5), 
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              height: 16,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF00C853)), // Green highlights
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            
            // Badges Section
            Text(
              'Rozetler',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ValueListenableBuilder(
              valueListenable: UserService().userListenable,
              builder: (context, box, _) {
                final user = UserService().user;
                final earnedIds = user.earnedBadges.toSet();
                
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: BadgeData.badges.length,
                  itemBuilder: (context, index) {
                    final badge = BadgeData.badges[index];
                    final isUnlocked = earnedIds.contains(badge.id);
                    
                    return Tooltip(
                      message: badge.description,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: isUnlocked 
                              ? Border.all(color: badge.color.withValues(alpha: 0.5), width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: isUnlocked ? 1.0 : 0.3,
                              child: Image.asset(
                                badge.iconPath,
                                width: 48,
                                height: 48,
                                errorBuilder: (_,__,___) => Icon(
                                  Icons.emoji_events, 
                                  size: 48, 
                                  color: isUnlocked ? badge.color : Colors.grey
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              badge.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked ? theme.colorScheme.onSurface : theme.disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),

            const SizedBox(height: 24),

            Text(
              'Hedeflerin',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kilo verme ve dayanıklılık artırma',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Haftada en az 3 seans yap, formunu koru ve sakatlanmadan geliş.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // REMOVE SPACER
          ],
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final user = UserService().user;
    final nameController = TextEditingController(text: user.name == 'Misafir' ? '' : user.name);
    final weightController = TextEditingController(text: user.weight?.toString() ?? '');
    final heightController = TextEditingController(text: user.height?.toString() ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profili Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Kilo (kg)',
                          suffixText: 'kg',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        decoration: const InputDecoration(
                          labelText: 'Boy (cm)',
                          suffixText: 'cm',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newName = nameController.text.trim().isEmpty ? _name : nameController.text.trim();
      double? newWeight = double.tryParse(weightController.text.replaceAll(',', '.'));
      double? newHeight = double.tryParse(heightController.text.replaceAll(',', '.'));

      await UserService().updateProfile(
        name: newName,
        weight: newWeight,
        height: newHeight,
      );
      
      if (mounted) {
        setState(() {
          _name = newName;
          // Force rebuild to update BMI Gauge
        });
      }
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}


