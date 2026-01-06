import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PostureAnalyzer {
  static String analyzePose(Pose pose) {
    // Get landmarks
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final rightEar = pose.landmarks[PoseLandmarkType.rightEar];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    // Check if essential landmarks are visible
    if (leftEar == null || rightEar == null || leftShoulder == null || rightShoulder == null) {
      return "Body not fully visible";
    }

    // Calculate Neck Inclination (Simplified: vertical distance between ear and shoulder)
    // In a perfect posture, ear should be aligned vertically with shoulder.
    // We check the horizontal offset. 
    // Normalized by shoulder width to be scale invariant.
    
    double shoulderWidth = distance(leftShoulder, rightShoulder);
    if (shoulderWidth == 0) return "Calculating...";

    double leftNeckOffset = (leftEar.x - leftShoulder.x).abs();
    double rightNeckOffset = (rightEar.x - rightShoulder.x).abs();
    
    double avgNeckOffsetRatio = (leftNeckOffset + rightNeckOffset) / 2 / shoulderWidth;

    // Thresholds (experimental)
    if (avgNeckOffsetRatio > 0.3) {
      return "Forward Head Posture Detected!";
    }

    // Check shoulder level
    double shoulderSlope = (rightShoulder.y - leftShoulder.y).abs();
    double shoulderLevelRatio = shoulderSlope / shoulderWidth;

    if (shoulderLevelRatio > 0.15) {
      return "Shoulders Uneven";
    }

    return "Good Posture";
  }

  static double distance(PoseLandmark p1, PoseLandmark p2) {
    return sqrt(pow((p1.x - p2.x), 2) + pow((p1.y - p2.y), 2));
  }
}
