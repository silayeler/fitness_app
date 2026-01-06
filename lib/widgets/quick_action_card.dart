import 'package:flutter/material.dart';

class QuickActionCard extends StatelessWidget {
  final String title;
  final String duration;
  final IconData? icon;
  final String? imagePath;
  final Color color;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.duration,
    this.icon,
    this.imagePath,
    required this.color,
    required this.onTap,
  }) : assert(icon != null || imagePath != null, 'Either icon or imagePath must be provided');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120, // Sabit genişlik
        height: 140, // Sabit yükseklik, görselle daha düzgün durması için
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: imagePath != null ? Colors.transparent : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: imagePath != null 
              ? null
              : Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1.5,
                ),
          image: imagePath != null 
              ? DecorationImage(
                  image: AssetImage(imagePath!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.3), // Karartma efekti
                    BlendMode.darken,
                  ),
                )
              : null,
          boxShadow: imagePath != null ? [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.2),
               blurRadius: 8,
               offset: const Offset(0, 4),
             )
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath == null && icon != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                
              if (imagePath == null) const SizedBox(height: 12),
              
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  // Görsel varsa beyaz, yoksa siyah
                  color: imagePath != null ? Colors.white : Colors.black87,
                  shadows: imagePath != null ? [
                    const Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 4,
                      color: Colors.black,
                    ),
                  ] : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                duration,
                style: TextStyle(
                  color: imagePath != null ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: imagePath != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
