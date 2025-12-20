import 'package:flutter/material.dart';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'ui_styles.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;
  final Color? maskColor;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
    this.maskColor,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = maskColor ?? UIStyles.primaryBlue;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = maskColor ?? UIStyles.primaryBlue;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = maskColor ?? UIStyles.primaryBlue;

    for (final pose in poses) {
      pose.landmarks.forEach((_, landmark) {
        // Skip face landmarks
        if (landmark.type == PoseLandmarkType.nose ||
            landmark.type == PoseLandmarkType.leftEyeInner ||
            landmark.type == PoseLandmarkType.leftEye ||
            landmark.type == PoseLandmarkType.leftEyeOuter ||
            landmark.type == PoseLandmarkType.rightEyeInner ||
            landmark.type == PoseLandmarkType.rightEye ||
            landmark.type == PoseLandmarkType.rightEyeOuter ||
            landmark.type == PoseLandmarkType.leftEar ||
            landmark.type == PoseLandmarkType.rightEar ||
            landmark.type == PoseLandmarkType.leftMouth ||
            landmark.type == PoseLandmarkType.rightMouth) {
          return;
        }

        // Draw glow

        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            6,
            Paint()..color = UIStyles.glassWhite..style = PaintingStyle.fill);

        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            1,
            paint);
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark joint1 = pose.landmarks[type1]!;
        final PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(
              translateX(joint1.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(joint1.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            Offset(
              translateX(joint2.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(joint2.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            paintType);
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      //Draw Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);

      // Draw computed neck point
      final PoseLandmark? leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
      final PoseLandmark? rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];

      if (leftShoulder != null && rightShoulder != null) {
        final double neckX = (leftShoulder.x + rightShoulder.x) / 2;
        final double neckY = (leftShoulder.y + rightShoulder.y) / 2;

        canvas.drawCircle(
            Offset(
              translateX(neckX, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(neckY, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            6,
            Paint()..color = UIStyles.glassWhite..style = PaintingStyle.fill);

        canvas.drawCircle(
            Offset(
              translateX(neckX, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(neckY, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            1,
            paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses ||
        oldDelegate.maskColor != maskColor;
  }

  double translateX(
    double x,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // Swap width and height logic for portrait
        return x *
            canvasSize.width /
            (Platform.isIOS ? imageSize.width : imageSize.height);
      default:
        return x * canvasSize.width / imageSize.width;
    }
  }

  double translateY(
    double y,
    Size canvasSize,
    Size imageSize,
    InputImageRotation rotation,
    CameraLensDirection cameraLensDirection,
  ) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        // Swap width and height logic for portrait
        return y *
            canvasSize.height /
            (Platform.isIOS ? imageSize.height : imageSize.width);
      default:
        return y * canvasSize.height / imageSize.height;
    }
  }
}

 
