import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class PlankLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
  ];

  @override
  AnalysisResult analyze(Pose pose) {
    // Determine which side is more visible
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
    final ankle = checkLeft ? pose.landmarks[PoseLandmarkType.leftAnkle] : pose.landmarks[PoseLandmarkType.rightAnkle];

    if (hip == null || shoulder == null || ankle == null) {
       return AnalysisResult(
         feedback: "Vücudun tam görünmüyor",
         statusTitle: "GÖRÜNÜM YOK",
         isGoodPosture: false,
       );
    }

    // Body Line Angle (Shoulder - Hip - Ankle)
    // Goal: ~180 degrees (straight line)
    double bodyAngle = calculateAngle(shoulder, hip, ankle);
    
    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};
    overlays[hip.type] = "${bodyAngle.toInt()}°";

    // Dynamic Score: Target 180, Tolerance 10
    double score = calculateScore(bodyAngle, 180, tolerance: 10, sensitivity: 3.0);

    // Allow smaller margin of error for professional form (170-190)
    if (bodyAngle > 170 && bodyAngle < 190) {
       jointColors[hip.type] = const Color(0xFF00C853);
       return AnalysisResult(
         feedback: "Kusursuz düzlük! Böyle devam et.",
         statusTitle: "MÜKEMMEL",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } else if (bodyAngle <= 170) {
      jointColors[hip.type] = Colors.red;
      return AnalysisResult(
         feedback: "Kalçanı kaldır!",
         statusTitle: "DÜZELT",
         isGoodPosture: false,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } else {
      jointColors[hip.type] = Colors.red;
      return AnalysisResult(
         feedback: "Kalçanı indir!",
         statusTitle: "DÜZELT",
         isGoodPosture: false,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    }
  }
}
