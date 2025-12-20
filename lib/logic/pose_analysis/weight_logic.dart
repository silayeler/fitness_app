import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class WeightLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
    PoseLandmarkType.leftEar, PoseLandmarkType.rightEar, // Head Alignment
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
  ];

  @override
  AnalysisResult analyze(Pose pose) {
    // General Standing Posture with Weight
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    
    if (leftEar == null || leftShoulder == null || leftHip == null) {
       return AnalysisResult(
         feedback: "Vücudun tam görünmüyor",
         statusTitle: "GÖRÜNÜM YOK",
         isGoodPosture: false,
       );
    }
    
    // Professional Alignment Check using Angles instead of Pixels
    // Calculate angle between Ear, Shoulder, and Hip (Vertical Alignment)
    // Ideally should be close to 180 degrees (straight vertical line)
    double alignmentAngle = calculateAngle(leftEar, leftShoulder, leftHip);

    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};
    overlays[leftShoulder.type] = "${alignmentAngle.toInt()}°";
    
    // Thresholds:
    // 160-180: Excellent vertical alignment
    // < 160: Leaning forward (Bad form for standing press etc.)
    
    // Dynamic Score: Target 180 (Vertical Alignment), Tolerance 5 (Strict), Sensitivity 4
    double score = calculateScore(alignmentAngle, 180, tolerance: 5, sensitivity: 4.0);

    if (alignmentAngle < 155) { 
       jointColors[leftShoulder.type] = Colors.red;
       jointColors[leftHip.type] = Colors.red;
       
       return AnalysisResult(
         feedback: "Öne eğilme! Dik dur.",
         statusTitle: "DİK DUR",
         isGoodPosture: false,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    }

    jointColors[leftShoulder.type] = const Color(0xFF00C853);
    overlays[leftShoulder.type] = "İyi";

    return AnalysisResult(
         feedback: "Duruşun iyi",
         statusTitle: "MÜKEMMEL",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
    );
  }
}
