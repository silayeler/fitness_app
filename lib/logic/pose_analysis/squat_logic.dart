import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class SquatLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
  ];

  @override
  AnalysisResult analyze(Pose pose) {
    // Determine which side is more visible
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    // Default to left side, but check visibility
    bool checkLeft = true;
    if (leftHip != null && rightHip != null) {
      if (rightHip.likelihood > leftHip.likelihood) {
        checkLeft = false;
      }
    }

    final hip = checkLeft ? pose.landmarks[PoseLandmarkType.leftHip] : pose.landmarks[PoseLandmarkType.rightHip];
    final knee = checkLeft ? pose.landmarks[PoseLandmarkType.leftKnee] : pose.landmarks[PoseLandmarkType.rightKnee];
    final ankle = checkLeft ? pose.landmarks[PoseLandmarkType.leftAnkle] : pose.landmarks[PoseLandmarkType.rightAnkle];
    final shoulder = checkLeft ? pose.landmarks[PoseLandmarkType.leftShoulder] : pose.landmarks[PoseLandmarkType.rightShoulder];

    if (hip == null || knee == null || ankle == null || shoulder == null) {
       return AnalysisResult(
         feedback: "Vücudun tam görünmüyor",
         statusTitle: "GÖRÜNÜM YOK",
         isGoodPosture: false,
       );
    }

    // 1. Knee Angle (Hip - Knee - Ankle)
    double kneeAngle = calculateAngle(hip, knee, ankle);
    
    // Colors for specific joints
    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};

    // Analyze Knee Depth
    if (kneeAngle < 65) {
       // Deep
       jointColors[knee.type] = Colors.blue;
    } else if (kneeAngle < 105) {
       // Parallel
       jointColors[knee.type] = const Color(0xFF00C853);
    } else {
       // High
       jointColors[knee.type] = Colors.orange;
    }
    
    // Dynamic Score Calculation
    // Target: 90 degrees (Parallel). 
    // Tolerance: 15 degrees (75-105 is excellent).
    // Sensitivity: 1.5 points lost per degree off.
    double score = calculateScore(kneeAngle, 90, tolerance: 15, sensitivity: 1.5);

    if (kneeAngle < 65) {
       // Deep Squat (Advanced but good range)
       jointColors[knee.type] = Colors.blue; // Blue for advanced/deep
       return AnalysisResult(
         feedback: "Tam derinlik! (Advanced)",
         statusTitle: "DERİN",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score,
       );
    } else if (kneeAngle < 105) {
       // Parallel (Target range for most)
       return AnalysisResult(
         feedback: "Mükemmel derinlik!",
         statusTitle: "HARİKA",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score, 
       );
    } else if (kneeAngle < 140) {
       return AnalysisResult(
         feedback: "Daha aşağı in!", 
         statusTitle: "HAZIR",
         isGoodPosture: false,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } 
    
    return AnalysisResult(
        feedback: "Harekete Başla",
        statusTitle: "HAZIR",
        isGoodPosture: true, 
        jointColors: {knee.type: Colors.white, hip.type: Colors.white},
        overlayText: overlays,
        score: 0.0
    );
  }
}
