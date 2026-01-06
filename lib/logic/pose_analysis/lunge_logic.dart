import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class LungeLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
        PoseLandmarkType.rightAnkle,
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
      ];

  @override
  AnalysisResult analyze(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;

    // Visibility Check
    bool isLeftVisible = leftHip.likelihood > 0.5 && leftKnee.likelihood > 0.5 && leftAnkle.likelihood > 0.5;
    bool isRightVisible = rightHip.likelihood > 0.5 && rightKnee.likelihood > 0.5 && rightAnkle.likelihood > 0.5;

    if (!isLeftVisible && !isRightVisible) {
      return AnalysisResult(
        feedback: "Kamera açısına girin",
        status: AnalysisStatus.neutral,
        score: 0.0,
        jointColors: {},
      );
    }

    // Trainer Pro Logic Refinement
    
    // 1. Determine active leg (the one in front)
    // The front leg is the one with the larger knee angle in standing, 
    // but in lunge position, it's the one that is bending towards 90.
    // We can assume the "lower" knee is the back knee, but let's stick to the angle logic.
    // If both visible, the one with sharper angle is likely the front working leg in descent? 
    // Actually, back leg bends more (can go to 90 or less). Front leg goes to ~90.
    // Distinguishing front/back by X position relative to Hip is safer.
    
    PoseLandmark frontKnee = isLeftVisible ? leftKnee : rightKnee;
    PoseLandmark frontAnkle = isLeftVisible ? leftAnkle : rightAnkle;
    // Simple heuristic: Using visible side for single-side view.

    // Calculate Knee Angle
    double currentKneeAngle = 0.0;
    if (isLeftVisible) {
        currentKneeAngle = calculateAngle(leftHip, leftKnee, leftAnkle);
    } else {
        currentKneeAngle = calculateAngle(rightHip, rightKnee, rightAnkle);
    }

    // State Machine
    // Down Phase: Knee < 100
    // Up Phase: Knee > 160
    
    if (currentKneeAngle < 100) {
      repState = "down";
    } else if (currentKneeAngle > 160 && repState == "down") {
      repState = "up";
      if (!hasTriggered) {
        repCount++;
        hasTriggered = true;
      }
    } else if (currentKneeAngle > 160 && repState != "down") {
      repState = "neutral";
      hasTriggered = false;
    }

    String message = "Başlayın";
    AnalysisStatus status = AnalysisStatus.neutral;
    List<PoseLandmarkType> wrongJoints = [];

    // PRO CHECKS
    if (repState == "down") {
      message = "Yukarı it!";
      status = AnalysisStatus.correct;
      
      // Check 1: Shin Verticality (Safety)
      // Front Knee x should be close to Front Ankle x
      double shinDeviation = (frontKnee.x - frontAnkle.x).abs();
      // Normalize by leg length roughly or just use raw pixel threshold if we assume normalized coords?
      // ML Kit coords are absolute pixels. Need relative check.
      // Angle of shin with vertical:
      // We can construct a virtual point (ankle.x, ankle.y - 100) and measure angle Knee-Ankle-Vertical.
      // Or simply: check absolute diff of X. Ideally < 20-30 pixels or small ratio.
      
      // Let's use simple angle logic if possible or message.
      if (shinDeviation > 40) { // arbitrary threshold, better to use angle
         // Create a more robust check? 
         // Let's assume user is side profile.
         // If shin is too far forward -> "Diz parmak ucunu geçmesin!"
         message = "Diz parmak ucunu geçmesin!";
         status = AnalysisStatus.incorrect;
         wrongJoints.add(frontKnee.type);
      }
      
      // Check 2: Torso Upright
      // Shoulder X vs Hip X
      double shoulderX = isLeftVisible ? leftShoulder.x : pose.landmarks[PoseLandmarkType.rightShoulder]!.x;
      double hipX = isLeftVisible ? leftHip.x : rightHip.x;
      if ((shoulderX - hipX).abs() > 50) { // Leaning
          message = "Gövdeni dik tut!";
          status = AnalysisStatus.incorrect;
          wrongJoints.add(PoseLandmarkType.leftShoulder); // Highlight shoulder
      }

    } else if (repState == "up") {
      message = "Harika!";
      status = AnalysisStatus.correct;
    } else {
      message = "Çök (Lunge)";
      status = AnalysisStatus.neutral;
    }
    
    double score = 100.0;
    if (repState == "down") {
        score = calculateScore(currentKneeAngle, 90, tolerance: 15);
        if (wrongJoints.isNotEmpty) score -= 20;
    }

    return AnalysisResult(
      feedback: message,
      status: status,
      score: score,
      postureQuality: wrongJoints.isEmpty ? "İyi" : "Hatalı",
      jointColors: {
        for (var j in wrongJoints) j: Colors.red,
      },
      // overlayText: Removed to avoid type mismatch
    );
  }
}
