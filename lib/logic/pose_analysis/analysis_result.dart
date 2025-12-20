import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';

/// Holds the rich result of a pose analysis frame
class AnalysisResult {
  final String feedback; // Main text feedback (e.g. "Go Lower")
  final String statusTitle; // Short status (e.g. "DİKKAT", "MÜKEMMEL")
  final bool isGoodPosture; // Overall success
  final double? score; // Optional score for this frame (0-100)
  
  // Specific feedback per joint (for Smart Coloring)
  // e.g. LeftKnee -> Red (Bad), RightKnee -> Green (Good)
  final Map<PoseLandmarkType, Color>? jointColors;
  
  // Text to draw on screen at specific landmark positions (e.g. angles)
  final Map<PoseLandmarkType, String>? overlayText;

  AnalysisResult({
    required this.feedback,
    required this.statusTitle,
    required this.isGoodPosture,
    this.score,
    this.jointColors,
    this.overlayText,
  });
}
