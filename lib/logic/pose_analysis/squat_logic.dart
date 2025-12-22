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
    
    // Static Hold Logic (Wall Sit / Iso Squat)
    // Target: Hold between 65 and 105 degrees.
    bool isHolding = kneeAngle < 105;
    
    String message = "Çök ve Bekle!";
    AnalysisStatus status = AnalysisStatus.neutral;
    Map<PoseLandmarkType, Color> jointColors = {};

    if (isHolding) {
        if (kneeAngle < 65) {
             // Too Deep / Advanced
             message = "Çok derin! Sabit kal.";
             status = AnalysisStatus.correct;
             jointColors[knee.type] = Colors.blue; 
        } else {
             // Perfect Range
             message = "Harika! Bozma.";
             status = AnalysisStatus.correct;
             jointColors[knee.type] = const Color(0xFF00C853);
        }
    } else {
        // Standing or too high
        status = AnalysisStatus.incorrect; // Pauses timer
        jointColors[knee.type] = Colors.orange;
        if (kneeAngle > 160) {
             message = "Başla: Çökerek bekle";
             status = AnalysisStatus.neutral;
        } else {
             message = "Daha aşağı in!";
        }
    }
    
    // Dynamic Score Calculation
    double score = calculateScore(kneeAngle, 90, tolerance: 15, sensitivity: 1.5);
    if (!isHolding) score = 0; // Only score when holding

    return AnalysisResult(
        feedback: message,
        status: status, 
        jointColors: jointColors,
        score: score,
        postureQuality: isHolding ? "İyi" : "Hatalı",
    );
  }
}
