import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class MekikLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
  ];

  @override
  AnalysisResult analyze(Pose pose) {
     final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    // Default to left side
    bool checkLeft = true;
    if (leftHip != null && rightHip != null) {
      if (rightHip.likelihood > leftHip.likelihood) {
        checkLeft = false;
      }
    }

    final hip = checkLeft ? pose.landmarks[PoseLandmarkType.leftHip] : pose.landmarks[PoseLandmarkType.rightHip];
    final shoulder = checkLeft ? pose.landmarks[PoseLandmarkType.leftShoulder] : pose.landmarks[PoseLandmarkType.rightShoulder];
    final knee = checkLeft ? pose.landmarks[PoseLandmarkType.leftKnee] : pose.landmarks[PoseLandmarkType.rightKnee];

     if (hip == null || shoulder == null || knee == null) {
       return AnalysisResult(
         feedback: "Vücudun tam görünmüyor",
         statusTitle: "GÖRÜNÜM YOK",
         isGoodPosture: false,
       );
    }

    double crunchAngle = calculateAngle(shoulder, hip, knee);

    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};
    overlays[hip.type] = "${crunchAngle.toInt()}°";

    // Dynamic Score: Target 90 degrees (Top of crunch), Tolerance 30
    double score = calculateScore(crunchAngle, 90, tolerance: 30, sensitivity: 1.0);

    // Repetition Counting (State Machine)
    // 1. Lying Down (Start/End) -> Angle > 130
    if (crunchAngle > 130) {
      if (repState == "up" && hasTriggered) {
        repCount++;
        hasTriggered = false;
      }
      repState = "down"; // Lying down is "down" state (neutral)
    } 
    // 2. Crunched (Action) -> Angle < 100
    else if (crunchAngle < 100) {
      repState = "up"; // Crunched up
      hasTriggered = true;
    }

    if (crunchAngle < 60) {
       // Too close
       jointColors[hip.type] = Colors.orange;
       return AnalysisResult(
         feedback: "Çok hızlı gitme!",
         statusTitle: "YAVAŞLA",
         isGoodPosture: true,
         jointColors: jointColors, 
         overlayText: overlays,
         score: score
       );
    } else if (crunchAngle < 120) {
       // Good crunch (shoulders off ground)
       jointColors[hip.type] = const Color(0xFF00C853);
       return AnalysisResult(
         feedback: "Harika sıkıştırma!",
         statusTitle: "MÜKEMMEL",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } else {
       // Lying down
       jointColors[hip.type] = Colors.white;
       return AnalysisResult(
         feedback: "Kalk ve Sıkıştır!",
         statusTitle: "HAZIR",
         isGoodPosture: true, // Resting
         jointColors: jointColors,
         overlayText: overlays,
         score: 0.0 // Reset score when resting
       );
    }
  }
}
