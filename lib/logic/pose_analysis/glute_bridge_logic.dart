import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';

class GluteBridgeLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.leftKnee,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.rightKnee,
      ];

  @override
  AnalysisResult analyze(Pose pose) {
     final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee]!;
    
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee]!;

    bool isLeftVisible = leftShoulder.likelihood > 0.5 && leftHip.likelihood > 0.5 && leftKnee.likelihood > 0.5;
    bool isRightVisible = rightShoulder.likelihood > 0.5 && rightHip.likelihood > 0.5 && rightKnee.likelihood > 0.5;

    if (!isLeftVisible && !isRightVisible) {
      return AnalysisResult(
        feedback: "Yan profil gerekli",
        status: AnalysisStatus.neutral,
        score: 0.0,
        jointColors: {},
      );
    }

    double bodyAngle = 0.0;
    if (isLeftVisible) {
        bodyAngle = calculateAngle(leftShoulder, leftHip, leftKnee);
    } else {
        bodyAngle = calculateAngle(rightShoulder, rightHip, rightKnee);
    }

    // Logic:
    // Down: Hips on floor => Angle ~120-140 (Sitting-ish fold at hips)
    // Up: Hips lifted => Angle ~170-180 (Straight line)
    
    // For Time-Based Hold: We just check if they are in the "Up" range.
    bool isHolding = bodyAngle > 165;
    
    String message = "Kaldır!";
    AnalysisStatus status = AnalysisStatus.neutral;
    List<PoseLandmarkType> wrongJoints = [];
    
    if (isHolding) {
        message = "Sık ve Bekle!";
        status = AnalysisStatus.correct;
        
        // PRO CHECK: Hyperextension
        if (bodyAngle > 185) { // Too arched
            message = "Belini zorlama! Düz dur.";
            status = AnalysisStatus.incorrect;
            // Highlight hip
            if (isLeftVisible) wrongJoints.add(PoseLandmarkType.leftHip);
            else wrongJoints.add(PoseLandmarkType.rightHip);
        } else if (bodyAngle < 170) {
            // Slightly sagging but still "up" -> allow it but warn? 
            // Or restrict strictness? Let's say 165+ is good for now.
             message = "Harika! Bozma.";
        }
    } else {
        // Down phase
        message = "Kalçanı havaya kaldır";
        status = AnalysisStatus.incorrect; // Pauses timer
        if (bodyAngle < 145) {
             message = "Başla: Kalçanı kaldır";
             status = AnalysisStatus.neutral; // Initial state
        }
    }
    
    double score = calculateScore(bodyAngle, 180, tolerance: 10);
    if (wrongJoints.isNotEmpty) score -= 25;

    return AnalysisResult(
      feedback: message,
      status: status,
      score: score,
      postureQuality: wrongJoints.isEmpty ? "İyi" : "Hatalı",
      jointColors: {
          for (var j in wrongJoints) j: Colors.red,
      },
    );
  }
}
