import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/exercise_session_model.dart';
import 'package:intl/intl.dart';

class WeeklyActivityGraph extends StatelessWidget {
  const WeeklyActivityGraph({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Get Data (Last 7 Days)
    final sessions = UserService().sessions;
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    // Calculate max value for scaling (default min 30 mins)
    int maxMinutes = 1;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = DateFormat('E', 'tr_TR').format(date); // Pzt, Sal...
      
      // Filter sessions for this day
      final daySessions = sessions.where((s) {
        return s.date.year == date.year &&
               s.date.month == date.month && 
               s.date.day == date.day;
      }).toList();

      // Sum duration
      int totalMinutes = daySessions.fold(0, (sum, item) => sum + item.durationMinutes);
      if (totalMinutes > maxMinutes) maxMinutes = totalMinutes;

      data.add({
        'day': dayName,
        'value': totalMinutes,
        'isToday': i == 0,
      });
    }

    // Round max up to nearest 30 for cleaner graph
    maxMinutes = ((maxMinutes + 29) ~/ 30) * 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Haftalık Gelişim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(Icons.bar_chart_rounded, color: Color(0xFF00C853)),
            ],
          ),
          const SizedBox(height: 24),
          
          // Graph
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: data.map((d) {
                final heightPercentage = (d['value'] as int) / maxMinutes;
                final isToday = d['isToday'] as bool;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tooltip/Value (Optional, visible if distinct)
                    // Bar
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: heightPercentage),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, _) {
                        return Column(
                          children: [
                            // Bar
                            Container(
                              width: 12,
                              height: 120 * value,
                              decoration: BoxDecoration(
                                color: isToday ? const Color(0xFF00C853) : const Color(0xFFE0E0E0),
                                borderRadius: BorderRadius.circular(6),
                                gradient: isToday ? const LinearGradient(
                                  colors: [Color(0xFF00C853), Color(0xFF69F0AE)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ) : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Duration Label (e.g., 20)
                            if (d['value'] > 0)
                              Text(
                                '${d['value']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              )
                            else 
                              const SizedBox(height: 12) // Placeholder space
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    // Label
                    Text(
                      d['day'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isToday ? const Color(0xFF00C853) : Colors.black45,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
