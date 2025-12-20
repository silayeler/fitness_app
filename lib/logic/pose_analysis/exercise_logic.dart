import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'analysis_result.dart';

abstract class ExerciseLogic {
  AnalysisResult analyze(Pose pose);

  List<PoseLandmarkType> get relevantLandmarks;

  // Helper: Calculate angle between three points (first - mid - last)
  double calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double radians = atan2(last.y - mid.y, last.x - mid.x) -
        atan2(first.y - mid.y, first.x - mid.x);
    double degrees = radians * 180.0 / pi;
    degrees = degrees.abs(); 
    if (degrees > 180.0) {
      degrees = 360.0 - degrees; 
    }
    return degrees;
  }

  /// Calculates a score (0-100) based on deviation from target angle.
  /// [currentAngle]: The measured angle.
  /// [targetAngle]: The ideal angle (e.g., 90 for squat parallel).
  /// [tolerance]: The range within which deviation is ignored (score = 100).
  /// [sensitivity]: How fast score drops per degree of deviation.
  double calculateScore(double currentAngle, double targetAngle, {double tolerance = 10, double sensitivity = 2.0}) {
    double deviation = (currentAngle - targetAngle).abs();
    
    if (deviation <= tolerance) {
      return 100.0;
    }
    
    double penalizedDeviation = deviation - tolerance;
    double score = 100.0 - (penalizedDeviation * sensitivity);
    
    return score.clamp(0.0, 100.0);
  }
}
