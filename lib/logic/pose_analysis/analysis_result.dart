import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';

enum AnalysisStatus {
  correct,   // Green
  incorrect, // Red
  neutral,   // White/Blue
}

/// Holds the rich result of a pose analysis frame
class AnalysisResult {
  final String feedback; // Main text feedback (e.g. "Go Lower")
  final AnalysisStatus status; // Enum status
  final double? score; // Optional score for this frame (0-100)
  
  // Specific feedback per joint (for Smart Coloring)
  final Map<PoseLandmarkType, Color>? jointColors;
  
  // Text to draw on screen at specific landmark positions
  final Map<PoseLandmarkType, String>? overlayText;
  
  // Backwards compatibility / Helper getters
  String get statusTitle {
    switch (status) {
      case AnalysisStatus.correct: return "HARİKA";
      case AnalysisStatus.incorrect: return "DÜZELT";
      case AnalysisStatus.neutral: return "HAZIR";
    }
  }

  bool get isGoodPosture => status == AnalysisStatus.correct;
  
  // Optional: Allow overriding the derived title if strictly needed, 
  // but for now let's enforce consistency.
  final String? _customStatusTitle;
  final String? _customPostureQuality;

  String get postureQuality => _customPostureQuality ?? (status == AnalysisStatus.incorrect ? "Hatalı" : "İyi");

  AnalysisResult({
    required this.feedback,
    this.status = AnalysisStatus.neutral,
    this.score,
    this.jointColors,
    this.overlayText,
    String? statusTitle, // Optional override
    String? postureQuality,
  }) : _customStatusTitle = statusTitle, _customPostureQuality = postureQuality;
}
