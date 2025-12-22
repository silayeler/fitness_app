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
    // 1. Get Landmarks
    final leftEar = pose.landmarks[PoseLandmarkType.leftEar];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];

    // Check visibility of critical points
    if (leftEar == null || leftShoulder == null || leftHip == null || leftKnee == null) {
       return AnalysisResult(
         feedback: "Vücudun tam görünmüyor",
         statusTitle: "GÖRÜNÜM YOK",
         isGoodPosture: false,
       );
    }
    
    // 2. Calculate Angles
    
    // A. Back Alignment (Ear - Shoulder - Hip)
    // Should be ~180 regardless of leaning, implies straight spine
    double backAngle = calculateAngle(leftEar, leftShoulder, leftHip);

    // B. Hip Angle (Shoulder - Hip - Knee)
    // 180 = Standing Straight
    // < 130 = Hinging/Bending (Action)
    double hipAngle = calculateAngle(leftShoulder, leftHip, leftKnee);

    // 3. Posture Analysis (Safety First)
    
    // Check for Rounding Back (Slouching)
    // If backAngle deviates too much from 180, it's bad posture
    bool isBackStraight = backAngle >= 150; // Tolerance for neck tilt
    
    Map<PoseLandmarkType, Color> jointColors = {};
    Map<PoseLandmarkType, String> overlays = {};
    
    overlays[leftHip.type] = "${hipAngle.toInt()}°";
    overlays[leftShoulder.type] = isBackStraight ? "Dik" : "Eğik";

    // Critical Error: Back Rounding
    if (!isBackStraight) {
       jointColors[leftShoulder.type] = Colors.red;
       jointColors[leftEar.type] = Colors.red;
       
       return AnalysisResult(
         feedback: "Sırtını DİK tut! Kambur durma.",
         statusTitle: "DİK DUR",
         isGoodPosture: false,
         jointColors: jointColors,
         overlayText: overlays,
         score: 10.0, // Low score for safety violation
       );
    }

    // 4. Repetition Logic (State Machine)
    
    // State 1: UP (Standing)
    if (hipAngle > 165) {
      if (repState == "down" && hasTriggered) {
        repCount++;
        hasTriggered = false;
      }
      repState = "up";
    } 
    // State 2: DOWN (Action / Hinging)
    else if (hipAngle < 130) {
      repState = "down";
      hasTriggered = true;
    }
    
    // 5. Feedback & Scoring
    double score = calculateScore(backAngle, 180, tolerance: 20, sensitivity: 2.0);
    
    if (hipAngle < 130) {
      // In action (Down phase)
      jointColors[leftHip.type] = Colors.blue; 
      return AnalysisResult(
         feedback: "Güzel, şimdi kalk!",
         statusTitle: "KALK",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score,
      );
    } else if (hipAngle < 165) {
      // Transition
       return AnalysisResult(
         feedback: repState == "down" ? "Kalkmaya devam et" : "Eğil",
         statusTitle: "DEVAM",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score,
       );
    }

    // Standing / Start
    jointColors[leftHip.type] = const Color(0xFF00C853);
    return AnalysisResult(
         feedback: "Harekete Başla",
         statusTitle: "HAZIR",
         isGoodPosture: true,
         jointColors: jointColors,
         overlayText: overlays,
         score: score
    );
  }
}
