import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../routes/app_router.dart';

@RoutePage()
class ExerciseSelectScreen extends StatelessWidget {
  const ExerciseSelectScreen({super.key});

  final List<Map<String, dynamic>> _exercises = const [
    {
      'name': 'Squat',
      'description': 'Bacak ve kalça kaslarını güçlendirir.',
      'icon': Icons.accessibility_new_rounded,
      'color': Color(0xFFE3F2FD),
      'iconColor': Color(0xFF2196F3),
    },
    {
      'name': 'Plank',
      'description': 'Karın ve merkez bölgeyi kuvvetlendirir.',
      'icon': Icons.horizontal_rule_rounded,
      'color': Color(0xFFE8F5E9),
      'iconColor': Color(0xFF4CAF50),
    },
    {
      'name': 'Bridge',
      'description': 'Bel ve arka bacak kasları için etkili.',
      'icon': Icons.architecture_rounded,
      'color': Color(0xFFFFF3E0),
      'iconColor': Color(0xFFFF9800),
    },
    {
      'name': 'Russian Twist',
      'description': 'Yan karın kaslarını çalıştırır.',
      'icon': Icons.rotate_right_rounded,
      'color': Color(0xFFF3E5F5),
      'iconColor': Color(0xFF9C27B0),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersiz Seç'),
        centerTitle: false,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hangi egzersizi çalışmak istersin?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _exercises.length,
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return _ExerciseCard(
                    name: exercise['name'] as String,
                    description: exercise['description'] as String,
                    icon: exercise['icon'] as IconData,
                    color: exercise['color'] as Color,
                    iconColor: exercise['iconColor'] as Color,
                    onTap: () {
                      context.router.push(
                        ExerciseSessionRoute(exerciseName: exercise['name']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark 
                    ? color.withValues(alpha: 0.2) // Dim background in dark mode
                    : color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const Spacer(),
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
