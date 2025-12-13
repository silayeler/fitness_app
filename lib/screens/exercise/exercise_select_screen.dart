import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

@RoutePage()
class ExerciseSelectScreen extends StatelessWidget {
  const ExerciseSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exercises = [
      (
        title: 'Squat',
        description: 'Bacak ve kalça kaslarını güçlendir.',
        color: const Color(0xFFE8F5E9),
        icon: Icons.fitness_center
      ),
      (
        title: 'Push-up',
        description: 'Göğüs ve kol kaslarını çalıştır.',
        color: const Color(0xFFE3F2FD),
        icon: Icons.push_pin_rounded
      ),
      (
        title: 'Plank',
        description: 'Merkez (core) kaslarını stabilize et.',
        color: const Color(0xFFFFF3E0),
        icon: Icons.accessibility_new_rounded
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersiz Seç'),
        centerTitle: false,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: exercises.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ex = exercises[index];
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              context.router.push(
                ExercisePreviewRoute(exerciseName: ex.title),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ex.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(ex.icon, color: Colors.green[600]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ex.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


