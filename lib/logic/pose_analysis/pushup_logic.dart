import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class PushUpLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightWrist,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.rightAnkle,
      ];

  @override
  AnalysisResult analyze(Pose pose) {
    // Determine visibility
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow]!;
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;

    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;

    // Check visibility probability
    bool isLeftVisible = leftShoulder.likelihood > 0.5 &&
        leftElbow.likelihood > 0.5 &&
        leftWrist.likelihood > 0.5;
    bool isRightVisible = rightShoulder.likelihood > 0.5 &&
        rightElbow.likelihood > 0.5 &&
        rightWrist.likelihood > 0.5;

    if (!isLeftVisible && !isRightVisible) {
      return AnalysisResult(
        feedback: "Kamera açısına girin",
        status: AnalysisStatus.neutral,
        score: 0.0,
        jointColors: {},
      );
    }

    // Use the more visible side or average if both
    double elbowAngle = 0.0;
    double bodyAngle = 0.0; // Alignment check
    Map<PoseLandmarkType, Color> jointStatus = {}; // Fixed Type: Color

    if (isLeftVisible) {
      elbowAngle = calculateAngle(leftShoulder, leftElbow, leftWrist);
      bodyAngle = calculateAngle(leftShoulder, leftHip, leftAnkle); // Should be ~180 for plank form
    } else {
      elbowAngle = calculateAngle(rightShoulder, rightElbow, rightWrist);
      bodyAngle = calculateAngle(rightShoulder, rightHip, rightAnkle);
    }

    // Update Repetition State
    // Down phase: Elbow angle < 90
    // Up phase: Elbow angle > 160
    
    // Body Alignment Check (Simple Plank check)
    bool goodForm = bodyAngle > 160; 

    if (elbowAngle < 90) {
      repState = "down";
    } else if (elbowAngle > 160 && repState == "down") {
      repState = "up";
      if (!hasTriggered) {
        repCount++;
        hasTriggered = true;
      }
    } else if (elbowAngle > 160 && repState != "down") {
      repState = "neutral";
      hasTriggered = false;
    }

    // Feedback
    String message = "Başlayın";
    AnalysisStatus status = AnalysisStatus.neutral;
    
    if (repState == "down") {
      message = "Yukarı it!";
      status = AnalysisStatus.correct;
    } else if (repState == "up") {
      message = "Harika!";
      status = AnalysisStatus.correct;
    } else if (!goodForm) {
      message = "Vücudunu düz tut!";
      status = AnalysisStatus.incorrect;
      // Mark hips as bad
      if (isLeftVisible) jointStatus[PoseLandmarkType.leftHip] = Colors.red;
      else jointStatus[PoseLandmarkType.rightHip] = Colors.red;
    } else {
      message = "Aşağı in";
      status = AnalysisStatus.neutral;
    }

    // Score calculation based on body alignment (form)
    double score = calculateScore(bodyAngle, 180, tolerance: 15);

    return AnalysisResult(
      feedback: message,
      status: status,
      score: score,
      postureQuality: goodForm ? "İyi" : "Kötü",
      jointColors: jointStatus,
    );
  }
}
