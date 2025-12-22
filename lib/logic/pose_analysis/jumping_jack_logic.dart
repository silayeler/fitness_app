import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:flutter/material.dart';
import 'exercise_logic.dart';
import 'analysis_result.dart';
import 'dart:math';
import 'package:flutter/material.dart'; // For Colors

class JumpingJackLogic extends ExerciseLogic {
  @override
  List<PoseLandmarkType> get relevantLandmarks => [
        PoseLandmarkType.leftShoulder,
        PoseLandmarkType.rightShoulder,
        PoseLandmarkType.leftWrist,
        PoseLandmarkType.rightWrist,
        PoseLandmarkType.leftHip,
        PoseLandmarkType.rightHip,
        PoseLandmarkType.leftAnkle,
        PoseLandmarkType.rightAnkle,
      ];

  @override
  AnalysisResult analyze(Pose pose) {
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;

    // Visibility Check
    if (leftWrist.likelihood < 0.5 || rightWrist.likelihood < 0.5 || leftAnkle.likelihood < 0.5) {
       return AnalysisResult(
        feedback: "Tüm vücut görünmeli",
        status: AnalysisStatus.neutral,
        score: 0.0,
        jointColors: {},
      );
    }

    // State Logic
    // Open (Star): Hands above shoulders + Feet wide
    // Closed (Pencil): Hands down + Feet together
    
    // Check Hands (Y axis is inverted in image coordinates, 0 is top)
    bool handsUp = (leftWrist.y < leftShoulder.y) && (rightWrist.y < rightShoulder.y);
    bool handsDown = (leftWrist.y > leftHip.y) && (rightWrist.y > rightHip.y);
    
    // Check Feet
    double hipWidth = (leftHip.x - rightHip.x).abs();
    double ankleDist = (leftAnkle.x - rightAnkle.x).abs();
    
    bool feetWide = ankleDist > (hipWidth * 1.5);
    bool feetClosed = ankleDist < (hipWidth * 1.2);

    // Transitions
    if (handsUp && feetWide) {
        repState = "open";
    } else if (handsDown && feetClosed && repState == "open") {
        repState = "closed";
        if (!hasTriggered) {
            repCount++;
            hasTriggered = true;
        }
    } else if (handsDown && feetClosed && repState != "open") {
        repState = "neutral";
        hasTriggered = false; // Reset trigger for next rep
    }

    String message = "Zıpla!";
    AnalysisStatus status = AnalysisStatus.correct;
    List<PoseLandmarkType> wrongJoints = [];

    if (repState == "open") {
        message = "Kapan!";
        
        // PRO CHECK 1: Arms Straight
        // Check Elbow Angles (Should be > 160)
        double leftElbowA = calculateAngle(leftShoulder, pose.landmarks[PoseLandmarkType.leftElbow]!, leftWrist);
        double rightElbowA = calculateAngle(rightShoulder, pose.landmarks[PoseLandmarkType.rightElbow]!, rightWrist);
        
        if (leftElbowA < 140) {
            message = "Kollarını bükme!";
            status = AnalysisStatus.incorrect;
            wrongJoints.add(PoseLandmarkType.leftElbow);
        }
        if (rightElbowA < 140) {
            message = "Kollarını bükme!";
            status = AnalysisStatus.incorrect;
            wrongJoints.add(PoseLandmarkType.rightElbow);
        }

        // PRO CHECK 2: Full ROM (Hands crossing / touching)
        double handDist = (leftWrist.x - rightWrist.x).abs();
        if (handDist > hipWidth * 0.8) { // Hands too far apart at top
             message = "Ellerini birleştir!";
             status = AnalysisStatus.neutral;
        }

    } else if (repState == "neutral") {
        message = "Açıl!";
    }
    
    // Score based on form
    double score = 100.0;
    if (repState == "open") {
        double handDist = (leftWrist.x - rightWrist.x).abs();
        if (handDist < hipWidth) score = 100;
        else score = 85; 
        
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
