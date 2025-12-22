import 'dart:math' as math;
import 'package:flutter/material.dart';

class BMIGaugeCard extends StatelessWidget {
  final double? weight;
  final double? height; // in cm
  final VoidCallback onAddInfo;

  const BMIGaugeCard({
    super.key,
    required this.weight,
    required this.height,
    required this.onAddInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (weight == null || height == null || weight == 0 || height == 0) {
      return GestureDetector(
        onTap: onAddInfo,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.primaryColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.calculate_outlined, size: 48, color: theme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Vücut Kitle İndeksini Hesapla',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Boy ve kilonu girerek sağlık durumunu öğren.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              Text(
                'Hesaplamak için dokun 👉',
                style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate BMI
    // BMI = kg / m^2
    final double heightM = height! / 100;
    final double bmi = weight! / (heightM * heightM);
    
    // Determine Status and Color
    String status;
    Color statusColor;
    String advice;

    if (bmi < 18.5) {
      status = 'Zayıf';
      statusColor = Colors.blueAccent;
      advice = 'Beslenmeni protein ağırlıklı artırmalısın.';
    } else if (bmi < 25) {
      status = 'Normal';
      statusColor = const Color(0xFF00C853);
      advice = 'Harikasın! Formunu korumaya devam et. 💪';
    } else if (bmi < 30) {
      status = 'Fazla Kilolu';
      statusColor = Colors.orange;
      advice = 'Daha fazla hareket edip kaloriyi dengelemelisin.';
    } else {
      status = 'Obezite';
      statusColor = Colors.red;
      advice = 'Bir uzmandan destek almanı öneririz.';
    }

    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onAddInfo, // Allow editing by tapping the card
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(20),
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
        child: Column(
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       'Vücut Kitle İndeksi',
                       style: theme.textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       'Durumun: $status',
                       style: theme.textTheme.bodyMedium?.copyWith(
                         color: statusColor,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: statusColor.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(12),
                     border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                   ),
                   child: Text(
                     bmi.toStringAsFixed(1),
                     style: TextStyle(
                       color: statusColor,
                       fontWeight: FontWeight.bold,
                       fontSize: 18,
                     ),
                   ),
                 ),
               ],
            ),
            const SizedBox(height: 24),
            
            // GAUGE
            CustomPaint(
              size: const Size(double.infinity, 150),
              painter: _GaugePainter(
                bmi: bmi,
                isDark: isDark,
              ),
            ),
            
            const SizedBox(height: 16),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double bmi;
  final bool isDark;

  _GaugePainter({required this.bmi, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = math.min(size.width / 2, size.height) - 10;
    
    // Background Arc (Grey)
    final bgPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Colored Segments
    // 15 --- 40 range (Total 25 units)
    // We map 15->40 to Pi->2Pi (technically 180 deg to 360 deg, but drawn from Pi with sweep Pi)
    
    // Zayıf (<18.5) -> Blue
    _drawSegment(canvas, center, radius, 15, 18.5, Colors.blueAccent);
    // Normal (18.5 - 25) -> Green
    _drawSegment(canvas, center, radius, 18.5, 25, const Color(0xFF00C853));
    // Fazla (25 - 30) -> Orange
    _drawSegment(canvas, center, radius, 25, 30, Colors.orange);
    // Obez (>30) -> Red
    _drawSegment(canvas, center, radius, 30, 40, Colors.red);

    // Needle
    final needleValue = bmi.clamp(15.0, 40.0);
    final totalRange = 40.0 - 15.0; // 25
    final normalized = (needleValue - 15.0) / totalRange; // 0.0 to 1.0
    final angle = math.pi + (normalized * math.pi); // Pi to 2Pi



    // Needle (Custom Path)
    final needlePath = Path();
    final needleLength = radius - 15;
    
    // Needle pointing to angle
    final tip = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );
    
    // Perpendicular points at the base (center) for thickness
    const baseWidth = 8.0;
    final baseAngleLeft = angle - math.pi / 2;
    final baseAngleRight = angle + math.pi / 2;
    
    final baseLeft = Offset(
      center.dx + baseWidth * math.cos(baseAngleLeft),
      center.dy + baseWidth * math.sin(baseAngleLeft),
    );
    
    final baseRight = Offset(
      center.dx + baseWidth * math.cos(baseAngleRight),
      center.dy + baseWidth * math.sin(baseAngleRight),
    );

    needlePath.moveTo(baseLeft.dx, baseLeft.dy);
    needlePath.lineTo(tip.dx, tip.dy);
    needlePath.lineTo(baseRight.dx, baseRight.dy);
    needlePath.close();

    final needlePaint = Paint()
      ..color = isDark ? Colors.white : const Color(0xFF263238) // Dark Blue-Grey
      ..style = PaintingStyle.fill;

    // Shadow for depth
    canvas.drawShadow(needlePath, Colors.black, 4, true);

    canvas.drawPath(needlePath, needlePaint);
    
    // Needle Center Dot (Cap)
    final capPaint = Paint()..color = isDark ? Colors.grey[300]! : Colors.white;
    canvas.drawCircle(center, 6, capPaint);
    canvas.drawCircle(center, 6, Paint()..color = Colors.black12..style=PaintingStyle.stroke..strokeWidth=1);
  }

  void _drawSegment(Canvas canvas, Offset center, double radius, double startBmi, double endBmi, Color color) {
    // Clamp to visualization range
    const minVis = 15.0;
    const maxVis = 40.0;
    
    if (startBmi > maxVis || endBmi < minVis) return;
    
    final s = startBmi.clamp(minVis, maxVis);
    final e = endBmi.clamp(minVis, maxVis);
    
    final totalRange = maxVis - minVis;
    
    final startPercent = (s - minVis) / totalRange;
    final sweepPercent = (e - s) / totalRange;
    
    final startAngle = math.pi + (startPercent * math.pi);
    final sweepAngle = sweepPercent * math.pi;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt; // Butt cap for clean transitions

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
