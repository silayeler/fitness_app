import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../models/exercise_session_model.dart';
import 'package:intl/intl.dart';

@RoutePage()
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ValueListenableBuilder(
      valueListenable: UserService().sessionListenable,
      builder: (context, box, _) {
        // Get fresh sessions directly from service which gets them from the box
        final sessions = UserService().sessions;
        final totalCount = sessions.length;

        // Group sessions
        final Map<String, List<ExerciseSessionModel>> groups = {};
        for (var s in sessions) {
          final key = "${s.date.year}-${s.date.month}-${s.date.day}_${s.exerciseName}";
          if (!groups.containsKey(key)) {
            groups[key] = [];
          }
          groups[key]!.add(s);
        }
        
        final groupedSessions = groups.values.map((list) => _SessionGroup(list)).toList();
        // Sort by date desc
        groupedSessions.sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Geçmiş'),
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
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet kartı
                Container(
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
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F8EA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.timeline_rounded,
                          color: Color(0xFF00C853),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$totalCount egzersiz seansı tamamladın',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Expanded(
                  child: groupedSessions.isEmpty 
                      ? const Center(child: Text("Henüz egzersiz kaydı yok.", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                    itemCount: groupedSessions.length,
                    itemBuilder: (context, index) {
                      final group = groupedSessions[index];
                      final count = group.sessions.length;
                      
                      // Timeline Header Logic
                      bool showHeader = false;
                      String headerText = "";
                      
                      if (index == 0) {
                        showHeader = true;
                        headerText = _getRelativeDate(group.date);
                      } else {
                        final prevDate = groupedSessions[index - 1].date;
                        if (!_isSameDay(group.date, prevDate)) {
                           showHeader = true;
                           headerText = _getRelativeDate(group.date);
                        }
                      }
                      
                      // Date format helper for card
                      final d = group.date;
                      // Just show time if "Today", else date + time
                      final dateStr = _isToday(d) 
                        ? "Bugün" 
                        : DateFormat('d MMMM yyyy', 'tr_TR').format(d);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader)
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Text(
                                headerText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: theme.scaffoldBackgroundColor,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 0.5,
                                    minChildSize: 0.3,
                                    maxChildSize: 0.9,
                                    expand: false,
                                    builder: (context, scrollController) {
                                      return Container(
                                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Center(
                                              child: Container(
                                                width: 40,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      group.exerciseName,
                                                      style: theme.textTheme.headlineSmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.onSurface,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(group.date),
                                                      style: theme.textTheme.bodyMedium?.copyWith(
                                                        color: theme.colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFE0F8EA),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '${group.avgScore}% Ort.',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF00C853),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 24),
                                            Expanded(
                                              child: ListView.separated(
                                                controller: scrollController,
                                                itemCount: group.sessions.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (context, i) {
                                                  final s = group.sessions[i];
                                                  final timeStr = "${s.date.hour}:${s.date.minute.toString().padLeft(2, '0')}";
                                                  return ListTile(
                                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                                    leading: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        color: theme.cardColor,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(color: theme.dividerColor),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          "${i + 1}",
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: theme.colorScheme.onSurface,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    title: Builder(
                                                      builder: (context) {
                                                        String stats = "";
                                                        if (s.reps != null && s.reps! > 0) {
                                                          stats += "${s.reps} Tekrar";
                                                        }
                                                        
                                                        // Duration Logic
                                                        if (s.durationSeconds != null && s.durationSeconds! > 0) {
                                                          if (stats.isNotEmpty) stats += " • ";
                                                          
                                                          int m = s.durationSeconds! ~/ 60;
                                                          int sec = s.durationSeconds! % 60;
                                                          
                                                          if (m > 0) {
                                                              stats += "${m}dk ${sec}sn";
                                                          } else {
                                                              stats += "${sec}sn";
                                                          }
                                                        } else {
                                                          // Fallback
                                                          if (stats.isNotEmpty) stats += " • ";
                                                          stats += "${s.durationMinutes} dk";
                                                        }

                                                        return Text(
                                                          "Saat $timeStr • $stats",
                                                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                                        );
                                                      }
                                                    ),
                                                    trailing: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(Icons.check_circle_rounded, size: 16, color: const Color(0xFF00C853)),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          "%${s.accuracyScore ?? 0}",
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF00C853),
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFF37474F)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        count > 1 ? '${count}x' : '1x',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.onSurfaceVariant,
                                          fontSize: 12
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group.exerciseName,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          count > 1 
                                            ? '$dateStr • Toplam ${group.totalDuration} dk'
                                            : '$dateStr Saat ${d.hour}:${d.minute.toString().padLeft(2, '0')} • ${group.totalDuration} dk',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                   Row(
                                     children: [
                                       Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '%${group.avgScore}',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF00C853),
                                            ),
                                          ),
                                          Text(
                                            'Ort. Form',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                              fontSize: 10
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        message: "Yapay zeka analiz puanı.\n%80+ Mükemmel form demektir.",
                                        triggerMode: TooltipTriggerMode.tap,
                                        showDuration: const Duration(seconds: 3),
                                        child: Icon(Icons.info_outline_rounded, size: 18, color: theme.disabledColor),
                                      )
                                     ],
                                   ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Bugün';
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
  }
  
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
  
  bool _isToday(DateTime date) {
     final now = DateTime.now();
     return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}

class _SessionGroup {
  final List<ExerciseSessionModel> sessions;
  
  _SessionGroup(this.sessions);
  
  DateTime get date => sessions.first.date;
  String get exerciseName => sessions.first.exerciseName;
  
  int get totalDuration => sessions.fold(0, (sum, s) => sum + s.durationMinutes);
  int get avgScore => (sessions.fold(0.0, (sum, s) => sum + (s.accuracyScore ?? 0)) / sessions.length).round();
}
