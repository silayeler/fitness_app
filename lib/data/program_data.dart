import '../models/program_model.dart';
import 'package:flutter/material.dart';

class ProgramData {
  static const List<ProgramModel> programs = [
    ProgramModel(
      id: 'p1',
      title: '30 Günlük Karın İnceltme',
      description: 'Plank ve Mekik ile karın kaslarını güçlendir, sıkılaş ve forma gir.',
      difficulty: 'Orta',
      durationWeeks: 4,
      imagePath: 'assets/images/gorsel_3.png', // Reusing existing asset
      schedule: _absSchedule,
    ),
    ProgramModel(
      id: 'p2',
      title: 'Başlangıç Güç Programı',
      description: 'Squat ve Ağırlık çalışmaları ile tüm vücut direncini artır.',
      difficulty: 'Zor',
      durationWeeks: 4,
      imagePath: 'assets/images/gorsel_1.png', // Reusing existing asset
      schedule: _strengthSchedule,
    ),
  ];

  static const List<DailyWorkout> _absSchedule = [
    DailyWorkout(dayNumber: 1, title: 'Başlangıç', exercises: ['Mekik', 'Plank']),
    DailyWorkout(dayNumber: 2, title: 'Dayanıklılık', exercises: ['Plank']),
    DailyWorkout(dayNumber: 3, title: 'Karın Odaklı', exercises: ['Mekik']),
    DailyWorkout(dayNumber: 4, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 5, title: 'Yoğun Karın', exercises: ['Mekik', 'Plank', 'Mekik']),
    DailyWorkout(dayNumber: 6, title: 'Statik Güç', exercises: ['Plank', 'Plank']),
    DailyWorkout(dayNumber: 7, title: 'Hafta Sonu Meydan Okuması', exercises: ['Mekik', 'Mekik', 'Plank']),
    
    DailyWorkout(dayNumber: 8, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 9, title: 'Hafta 2 Başlangıç', exercises: ['Mekik', 'Plank']),
    DailyWorkout(dayNumber: 10, title: 'Alt Karın', exercises: ['Mekik']),
    DailyWorkout(dayNumber: 11, title: 'Core Güçlendirme', exercises: ['Plank', 'Plank']),
    DailyWorkout(dayNumber: 12, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 13, title: 'Maksimum Efor', exercises: ['Mekik', 'Mekik', 'Plank']),
    DailyWorkout(dayNumber: 14, title: 'Esnetme ve Güç', exercises: ['Plank']),
    DailyWorkout(dayNumber: 15, title: 'Yarı Yol Kontrolü', exercises: ['Mekik', 'Plank', 'Squat']), // Mix up slightly

    DailyWorkout(dayNumber: 16, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 17, title: 'Hafta 3 Yükleme', exercises: ['Mekik', 'Mekik', 'Plank']),
    DailyWorkout(dayNumber: 18, title: 'Plank Maratonu', exercises: ['Plank', 'Plank', 'Plank']),
    DailyWorkout(dayNumber: 19, title: 'Hızlı Yakım', exercises: ['Mekik', 'Squat', 'Mekik']),
    DailyWorkout(dayNumber: 20, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 21, title: 'Üst Karın', exercises: ['Mekik', 'Mekik']),
    DailyWorkout(dayNumber: 22, title: 'Core Stabilite', exercises: ['Plank']),
    DailyWorkout(dayNumber: 23, title: 'Pazar Antrenmanı', exercises: ['Mekik', 'Plank']),

    DailyWorkout(dayNumber: 24, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 25, title: 'Son Hafta', exercises: ['Mekik', 'Plank', 'Squat']),
    DailyWorkout(dayNumber: 26, title: 'Güç Artışı', exercises: ['Ağırlık', 'Plank']), // Introducing weights
    DailyWorkout(dayNumber: 27, title: 'Tam Gaz', exercises: ['Mekik', 'Mekik', 'Mekik']),
    DailyWorkout(dayNumber: 28, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 29, title: 'Final Hazırlık', exercises: ['Plank', 'Plank']),
    DailyWorkout(dayNumber: 30, title: 'BÜYÜK FİNAL', exercises: ['Mekik', 'Plank', 'Squat', 'Ağırlık']),
  ];

  static const List<DailyWorkout> _strengthSchedule = [
    DailyWorkout(dayNumber: 1, title: 'Bacak Günü', exercises: ['Squat', 'Squat']),
    DailyWorkout(dayNumber: 2, title: 'Üst Vücut', exercises: ['Ağırlık']),
    DailyWorkout(dayNumber: 3, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 4, title: 'Full Body', exercises: ['Squat', 'Ağırlık', 'Plank']),
    DailyWorkout(dayNumber: 5, title: 'Bacak Odaklı', exercises: ['Squat', 'Squat']),
    DailyWorkout(dayNumber: 6, title: 'Aktif Dinlenme', exercises: ['Plank']),
    DailyWorkout(dayNumber: 7, title: 'Hafta Sonu Gücü', exercises: ['Ağırlık', 'Squat']),
    
    // ... Simplified for brevity, usually repeats with intensity
    DailyWorkout(dayNumber: 8, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 9, title: 'Hafta 2', exercises: ['Squat', 'Ağırlık']),
    DailyWorkout(dayNumber: 10, title: 'Güç Devam', exercises: ['Ağırlık', 'Ağırlık']),
    DailyWorkout(dayNumber: 11, title: 'Dinlenme', isRestDay: true),
    DailyWorkout(dayNumber: 12, title: 'Bacak Kuvveti', exercises: ['Squat', 'Squat', 'Squat']),
    DailyWorkout(dayNumber: 13, title: 'Üst Vücut', exercises: ['Ağırlık', 'Plank']),
    DailyWorkout(dayNumber: 14, title: 'Kardiyo Güç', exercises: ['Mekik', 'Squat']),
    DailyWorkout(dayNumber: 15, title: 'Yarı Yol', exercises: ['Squat', 'Ağırlık', 'Plank']),
    
    // ...
    DailyWorkout(dayNumber: 30, title: 'FİNAL GÜCÜ', exercises: ['Squat', 'Squat', 'Ağırlık', 'Ağırlık']),
  ];
}
