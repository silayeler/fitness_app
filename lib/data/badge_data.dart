import 'package:flutter/material.dart';

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final String iconPath; // Can be asset or IconData conceptually
  final Color color;
  final int requiredXp; // Or other condition

  const BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.color,
    this.requiredXp = 0,
  });
}

class BadgeData {
  static const List<BadgeModel> badges = [
    BadgeModel(
      id: 'first_step',
      title: 'İlk Adım',
      description: 'İlk antrenmanını tamamla.',
      iconPath: 'assets/badges/first_step.png', // Placeholder logic
      color: Colors.blue,
      requiredXp: 10,
    ),
    BadgeModel(
      id: 'consistent',
      title: 'Kararlı',
      description: '3 gün üst üste antrenman yap.',
      iconPath: 'assets/badges/consistent.png',
      color: Colors.orange,
      requiredXp: 100, // Placeholder
    ),
    BadgeModel(
      id: 'champion',
      title: 'Şampiyon',
      description: '10. Seviyeye ulaş.',
      iconPath: 'assets/badges/champion.png',
      color: Colors.purple,
      requiredXp: 5000,
    ),
    BadgeModel(
      id: 'early_bird',
      title: 'Erkenci Kuş',
      description: 'Sabah 08:00\'den önce antrenman yap.',
      iconPath: 'assets/badges/early_bird.png',
      color: Colors.amber,
    ),
  ];
  
  static BadgeModel? getBadge(String id) {
    try {
      return badges.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
