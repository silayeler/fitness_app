import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class ShoulderPressLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        // Hands
        PoseLandmarkType.leftPinky,
        PoseLandmarkType.leftIndex,
        PoseLandmarkType.leftThumb,
        PoseLandmarkType.rightPinky,
        PoseLandmarkType.rightIndex,
        PoseLandmarkType.rightThumb,
        // Torso & Head (for context)
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.nose,
      ];

  @override
  AnalysisResult analyze(Pose pose) {
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow]!;
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;

    bool isLeftVisible = leftShoulder.likelihood > 0.5 && leftElbow.likelihood > 0.5 && leftWrist.likelihood > 0.5;
    bool isRightVisible = rightShoulder.likelihood > 0.5 && rightElbow.likelihood > 0.5 && rightWrist.likelihood > 0.5;

    if (!isLeftVisible && !isRightVisible) {
      return AnalysisResult(
        feedback: "Kollar görünmüyor",
        status: AnalysisStatus.neutral,
        score: 0.0,
        jointColors: {},
      );
    }
    
    // Analyze prominent side or both
    double leftAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
    double rightAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
    
    // Normalize logic: Use average if both visible, else use single
    double avgAngle = 0.0;
    if (isLeftVisible && isRightVisible) {
      avgAngle = (leftAngle + rightAngle) / 2;
    } else if (isLeftVisible) {
      avgAngle = leftAngle;
    } else {
      avgAngle = rightAngle;
    }

    // Logic:
    // Down (Start): Elbows bent ~90 or less (Hands at ear level)
    // Up (Finish): Arms extended (> 150)
    
    if (avgAngle < 100) {
      repState = "down";
    } else if (avgAngle > 160 && repState == "down") {
      repState = "up";
      if (!hasTriggered) {
        repCount++;
        hasTriggered = true;
      }
    } else if (avgAngle > 160 && repState != "down") {
      repState = "neutral";
      hasTriggered = false;
    }

    String message = "İt!";
    AnalysisStatus status = AnalysisStatus.correct;
    List<PoseLandmarkType> wrongJoints = [];

    // PRO CHECKS
    
    // 1. Symmetry Check (Only if both visible)
    if (isLeftVisible && isRightVisible) {
        double wristDiff = (leftWrist.y - rightWrist.y).abs();
        if (wristDiff > 40) { // Threshold for uneven press
            message = "Dengesiz basış!";
            status = AnalysisStatus.incorrect;
            // Highlight the lower hand (higher Y value)
            if (leftWrist.y > rightWrist.y) wrongJoints.add(PoseLandmarkType.leftWrist);
            else wrongJoints.add(PoseLandmarkType.rightWrist);
        }
    }

    // 2. Elbow Flare Check (Front view)
    // Elbows should be somewhat vertically aligned under wrists in start? 
    // Or just general "Don't lock elbows violently" -> Angle check?

    if (repState == "down") {
        message = "Yukarı bas!";
        // Check depth
        if (avgAngle > 110) {
            message = "Daha aşağı indir";
            status = AnalysisStatus.neutral;
        }
    } else if (repState == "up") {
        message = "İndir!";
        // Check Full Extension
         if (avgAngle < 150) {
            message = "Kollarını tam uzat";
            status = AnalysisStatus.incorrect;
            wrongJoints.add(PoseLandmarkType.leftElbow);
            wrongJoints.add(PoseLandmarkType.rightElbow);
        }
    }

    double score = isLeftVisible && isRightVisible 
        ? calculateScore((leftAngle - rightAngle).abs(), 0, tolerance: 15) // Symmetry bonus
        : 90.0; 
    
    if (wrongJoints.isNotEmpty) score -= 15;

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
