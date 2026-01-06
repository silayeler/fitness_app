import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/logic/pose_analysis/squat_logic.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('SquatLogic Confidence Tests', () {
    late SquatLogic squatLogic;

    setUp(() {
      squatLogic = SquatLogic();
    });

    test('should return GÖRÜNÜM YOK when critical landmarks have low confidence', () {
      // Create a pose with low likelihood landmarks for the left side
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.leftHip: PoseLandmark(
          type: PoseLandmarkType.leftHip,
          x: 100,
          y: 100,
          z: 0,
          likelihood: 0.2, // Low confidence
        ),
        PoseLandmarkType.leftKnee: PoseLandmark(
          type: PoseLandmarkType.leftKnee,
          x: 100,
          y: 200,
          z: 0,
          likelihood: 0.3, // Low confidence
        ),
        PoseLandmarkType.leftAnkle: PoseLandmark(
          type: PoseLandmarkType.leftAnkle,
          x: 100,
          y: 300,
          z: 0,
          likelihood: 0.2, // Low confidence
        ),
         PoseLandmarkType.leftShoulder: PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 100,
          y: 50,
          z: 0,
          likelihood: 0.9,
        ),
      };

      final pose = Pose(landmarks: landmarks);
      final result = squatLogic.analyze(pose);

      // It should NOT try to calculate angles or count reps, causing "GÖRÜNÜM YOK"
      expect(result.statusTitle, equals('GÖRÜNÜM YOK'));
    });

     test('should analyze correctly when landmarks have high confidence', () {
      // High confidence standing pose
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.leftHip: PoseLandmark(
          type: PoseLandmarkType.leftHip,
          x: 100,
          y: 100,
          z: 0,
          likelihood: 0.9, 
        ),
        PoseLandmarkType.leftKnee: PoseLandmark(
          type: PoseLandmarkType.leftKnee,
          x: 100,
          y: 200,
          z: 0,
          likelihood: 0.9, 
        ),
        PoseLandmarkType.leftAnkle: PoseLandmark(
          type: PoseLandmarkType.leftAnkle,
          x: 100,
          y: 300,
          z: 0,
          likelihood: 0.9, 
        ),
         PoseLandmarkType.leftShoulder: PoseLandmark(
          type: PoseLandmarkType.leftShoulder,
          x: 100,
          y: 50,
          z: 0,
          likelihood: 0.9,
        ),
      };

      final pose = Pose(landmarks: landmarks);
      final result = squatLogic.analyze(pose);

      // Should be "HAZIR" or some active state, definitely NOT "GÖRÜNÜM YOK"
      expect(result.statusTitle, isNot(equals('GÖRÜNÜM YOK')));
    });
  });
}
