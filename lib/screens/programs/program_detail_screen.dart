import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../models/program_model.dart';
import '../../routes/app_router.dart';

@RoutePage()
class ProgramDetailScreen extends StatelessWidget {
  const ProgramDetailScreen({super.key, required this.program});

  final ProgramModel program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(program.title),
        centerTitle: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          letterSpacing: -0.5,
        ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: program.schedule.length,
        itemBuilder: (context, index) {
          final workout = program.schedule[index];
          return _DayCard(
            workout: workout,
            onTap: () {
              if (!workout.isRestDay && workout.exercises.isNotEmpty) {
                // Determine exercise to launch.
                // For now, if multiple, launch the first one or create a playlist logic later.
                // The implementation plan says "specific exercise for that day".
                // Since our sessions are single-exercise, we pick the first one.
                final exerciseName = workout.exercises.first;
                context.router.push(ExerciseSessionRoute(exerciseName: exerciseName));
              }
            },
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.workout, required this.onTap});

  final DailyWorkout workout;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRest = workout.isRestDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRest ? theme.cardColor.withValues(alpha: 0.5) : theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isRest ? Border.all(color: theme.dividerColor.withValues(alpha: 0.5)) : null,
      ),
      child: ListTile(
        onTap: isRest ? null : onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isRest ? Colors.grey.withValues(alpha: 0.2) : const Color(0xFF00C853).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${workout.dayNumber}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRest ? Colors.grey : const Color(0xFF00C853),
            ),
          ),
        ),
        title: Text(
          workout.title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isRest ? FontWeight.normal : FontWeight.bold,
            color: isRest ? theme.disabledColor : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: isRest 
          ? const Text('Dinlenme ve toparlanma') 
          : Text(
              workout.exercises.join(' + '),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        trailing: isRest 
          ? const Icon(Icons.nightlight_round, size: 20, color: Colors.grey)
          : const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      ),
    );
  }
}
