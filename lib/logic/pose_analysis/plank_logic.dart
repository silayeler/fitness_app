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
         status: AnalysisStatus.neutral,
         statusTitle: "GÖRÜNÜM YOK",
       );
    }

    // Check Likelihood (Confidence)
    // If not confident, do not proceed
    if (hip.likelihood < 0.5 || shoulder.likelihood < 0.5 || ankle.likelihood < 0.5) {
       return AnalysisResult(
         feedback: "Net görünmüyorsun",
         status: AnalysisStatus.neutral,
         statusTitle: "GÖRÜNÜM ZAYIF",
       );
    }

    // Horizontal Check
    // Plank is horizontal: abs(Delta X) should be >> abs(Delta Y)
    // If Delta Y > Delta X, person is likely vertical (Standing)
    final dx = (shoulder.x - ankle.x).abs();
    final dy = (shoulder.y - ankle.y).abs();
    
    if (dy > dx) {
       return AnalysisResult(
         feedback: "Yere yat ve plank pozisyonu al!",
         status: AnalysisStatus.neutral,
         statusTitle: "POZİSYON AL",
       );
    }

    // Body Line Angle (Shoulder - Hip - Ankle)
    // Goal: 180 degrees (straight line)
    // Acceptable Range: 165 - 180
    double bodyAngle = calculateAngle(shoulder, hip, ankle);
    
    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};
    overlays[hip.type] = "${bodyAngle.toInt()}°";

    // Dynamic Score: Target 180, Tolerance 15
    double score = calculateScore(bodyAngle, 180, tolerance: 15, sensitivity: 2.0);

    // Check if body is straight enough
    // Stricter tolerance: must be >= 170 degrees (10 degree deviation max)
    if (bodyAngle >= 165) {
       jointColors[hip.type] = const Color(0xFF00C853);
       return AnalysisResult(
         feedback: "Mükemmel düzlük! Böyle devam et.",
         status: AnalysisStatus.correct,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } 
    
    // If not straight, determine direction (Pike or Sag)
    // Y-coordinate increases downwards.
    // Line Midpoint Y between Shoulder and Ankle
    double midY = (shoulder.y + ankle.y) / 2;
    
    if (hip.y < midY) {
      // Hip is above the line -> Pike (Hips too high)
      jointColors[hip.type] = Colors.red;
      return AnalysisResult(
         feedback: "Kalçanı biraz indir!",
         status: AnalysisStatus.incorrect,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    } else {
      // Hip is below the line -> Sag (Hips too low)
      jointColors[hip.type] = Colors.red;
      return AnalysisResult(
         feedback: "Kalçanı kaldır!",
         status: AnalysisStatus.incorrect,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
       );
    }
  }
}
