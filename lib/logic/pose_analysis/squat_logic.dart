
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
         status: AnalysisStatus.neutral,
         statusTitle: "GÖRÜNÜM YOK",
       );
    }

    // CONFIDENCE CHECK
    const double minConfidence = 0.6;
    if (hip.likelihood < minConfidence || 
        knee.likelihood < minConfidence || 
        ankle.likelihood < minConfidence) {
       return AnalysisResult(
         feedback: "Kamera seni göremiyor.",
         status: AnalysisStatus.neutral,
         statusTitle: "GÖRÜNÜM YOK",
       );
    }

    // 1. Knee Angle (Hip - Knee - Ankle)
    double kneeAngle = calculateAngle(hip, knee, ankle);
    
    // Repetition Logic
    // Standing: > 160 degrees
    // Deep Squat: < 95 degrees (adjusted for average user)

    // Repetition Logic (Mekik Style State Machine)
    // Active Phase: Squat Down (< 100 degrees)
    // Neutral Phase: Standing Up (> 165 degrees)

    // 1. Standing Up (Neutral / End of Rep)
    if (kneeAngle > 165) {
      if (repState == "down" && hasTriggered) {
        repCount++;
        hasTriggered = false; // Consume trigger
      }
      repState = "up"; 
    } 
    // 2. Squatting Down (Active Phase)
    else if (kneeAngle < 100) {
      repState = "down";
      hasTriggered = true; // Set Latch
    }

    // Feedback & Status
    String message = "Başla";
    AnalysisStatus status = AnalysisStatus.neutral;
    Map<PoseLandmarkType, Color> jointColors = {};

    if (repState == "down") {
      message = "Yüksel!";
      status = AnalysisStatus.correct;
      jointColors[knee.type] = const Color(0xFF00C853);
    } else if (repState == "up" && hasTriggered == false) {
      // Just standing, waiting for next rep
      message = "Çök!";
      status = AnalysisStatus.neutral;
       jointColors[knee.type] = Colors.white;
    } else {
      // Transition Area (between 100 and 165)
      if (repState == "up") {
         // Going down
         message = "Daha aşağı!";
         jointColors[knee.type] = Colors.orange;
      } else {
         // Going up
         message = "Devam et!";
         jointColors[knee.type] = const Color(0xFF00C853);
      }
    }
    
    // Score based on depth when in motion (deeper is better score)
    double score = 0;
    if (kneeAngle < 120) {
       score = calculateScore(kneeAngle, 90, tolerance: 30);
    }

    return AnalysisResult(
        feedback: message,
        status: status, 
        jointColors: jointColors,
        score: score,
        postureQuality: (kneeAngle < 90) ? "Mükemmel" : "İyi",
    );
  }
}
