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
  final Set<PoseLandmarkType>? relevantLandmarks;
  final Map<PoseLandmarkType, Color>? jointColors;
  final Map<PoseLandmarkType, String>? overlayText;

  PosePainter(
    this.poses,
    this.absoluteImageSize,
    this.rotation,
    this.cameraLensDirection,
    this.maskColor,
    this.relevantLandmarks,
    this.jointColors,
    this.overlayText,
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
        // 1. Filter: If relevantLandmarks is provided, skip if not contained
        if (relevantLandmarks != null && !relevantLandmarks!.contains(landmark.type)) {
          return;
        }

        // 2. Skip face landmarks unless specifically relevant (We filtered above so this is just redundant safety or for default case)
        // If relevantLandmarks wasn't provided, we still might want to skip detailed face dots
        if (relevantLandmarks == null) {
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
        }

        // Draw glow
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            6,
            Paint()..color = UIStyles.glassWhite..style = PaintingStyle.fill);

        // Determine color: Specific Joint Color > Mask Color > Default Blue
        Color dotColor = paint.color;
        if (jointColors != null && jointColors!.containsKey(landmark.type)) {
           dotColor = jointColors![landmark.type]!;
        }

        canvas.drawCircle(
            Offset(
              translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            4, // Slightly larger
            Paint()..color = dotColor..style = PaintingStyle.fill); // Filled for visibility

        // Draw Overlay Text (Angles, etc.)
        if (overlayText != null && overlayText!.containsKey(landmark.type)) {
           final textSpan = TextSpan(
             text: overlayText![landmark.type],
             style: const TextStyle(
               color: Colors.white,
               fontSize: 16,
               fontWeight: FontWeight.bold,
               backgroundColor: Colors.black45, // Legibility
             ),
           );
           final textPainter = TextPainter(
             text: textSpan,
             textDirection: TextDirection.ltr,
           );
           textPainter.layout(
             minWidth: 0,
             maxWidth: size.width,
           );
           textPainter.paint(
             canvas,
             Offset(
               translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection) + 10, // Offset a bit
               translateY(landmark.y, size, absoluteImageSize, rotation, cameraLensDirection) - 20,
             ),
           );
        }
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        
        // Filter Lines: Both points must be relevant
        if (relevantLandmarks != null) {
          if (!relevantLandmarks!.contains(type1) || !relevantLandmarks!.contains(type2)) {
            return;
          }
        }

        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];
        
        if (joint1 == null || joint2 == null) return;
        
        // Smart Line Coloring:
        // If BOTH joints have a specific color (e.g. both Knees are red), color the line red.
        // Or if the MAIN joint of the segment is colored.
        Color lineColor = paintType.color;
        if (jointColors != null) {
           if (jointColors!.containsKey(type1) && jointColors!.containsKey(type2)) {
               // If both are red, line is red.
               if (jointColors![type1] == Colors.red || jointColors![type2] == Colors.red) {
                  lineColor = Colors.red;
               } else if (jointColors![type1] == const Color(0xFF00C853)) {
                  lineColor = const Color(0xFF00C853);
               }
           }
        }

        canvas.drawLine(
            Offset(
              translateX(joint1.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(joint1.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            Offset(
              translateX(joint2.x, size, absoluteImageSize, rotation, cameraLensDirection),
              translateY(joint2.y, size, absoluteImageSize, rotation, cameraLensDirection),
            ),
            Paint()..color = lineColor..strokeWidth = paintType.strokeWidth..style = PaintingStyle.stroke);
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
      
      // Draw Connector between shoulders (clavicle) if both are visible
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      // Draw Connector between hips (pelvis) if both are visible
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses ||
        oldDelegate.maskColor != maskColor || 
        oldDelegate.relevantLandmarks != relevantLandmarks;
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
        // Calculate the relative X in the image
        double relativeX = x *
            canvasSize.width /
            (Platform.isIOS ? imageSize.width : imageSize.height);
            
        // For Front Camera, Mirror X
        if (cameraLensDirection == CameraLensDirection.front) {
          return canvasSize.width - relativeX;
        }
        return relativeX;
        
      default:
        double relativeX = x * canvasSize.width / imageSize.width;
        if (cameraLensDirection == CameraLensDirection.front) {
          return canvasSize.width - relativeX;
        }
        return relativeX;
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
        return y *
            canvasSize.height /
            (Platform.isIOS ? imageSize.height : imageSize.width);
      default:
        return y * canvasSize.height / imageSize.height;
    }
  }
}

 
