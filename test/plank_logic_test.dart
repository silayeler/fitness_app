import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app/logic/pose_analysis/plank_logic.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  group('PlankLogic Tests', () {
    late PlankLogic plankLogic;

    setUp(() {
      plankLogic = PlankLogic();
    });
    
    // Helper to create landmarks
    PoseLandmark createLandmark(PoseLandmarkType type, double x, double y) {
      return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: 0.9);
    }

    test('should return MÜKEMMEL for straight body (180 degrees)', () {
      // Straight line: Shoulder (0, 0), Hip (10, 0), Ankle (20, 0)
      // Note: Y increases downwards.
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.rightShoulder: createLandmark(PoseLandmarkType.rightShoulder, 0, 100),
        PoseLandmarkType.rightHip: createLandmark(PoseLandmarkType.rightHip, 50, 100),
        PoseLandmarkType.rightAnkle: createLandmark(PoseLandmarkType.rightAnkle, 100, 100),
        // Add left side too just in case logic checks both presence
         PoseLandmarkType.leftShoulder: createLandmark(PoseLandmarkType.leftShoulder, 0, 100),
        PoseLandmarkType.leftHip: createLandmark(PoseLandmarkType.leftHip, 50, 100),
        PoseLandmarkType.leftAnkle: createLandmark(PoseLandmarkType.leftAnkle, 100, 100),
      };
      
      final result = plankLogic.analyze(Pose(landmarks: landmarks));
      expect(result.statusTitle, equals('MÜKEMMEL'));
    });

    test('should return DÜZELT (Lower Hips) for Pike position', () {
      // Pike: Hips are HIGHER (Smaller Y) than Shoulder/Ankle line
      // Shoulder (0, 100), Hip (50, 50 - High), Ankle (100, 100)
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.rightShoulder: createLandmark(PoseLandmarkType.rightShoulder, 0, 100),
        PoseLandmarkType.rightHip: createLandmark(PoseLandmarkType.rightHip, 50, 50), // 50 is HIGHER than 100
        PoseLandmarkType.rightAnkle: createLandmark(PoseLandmarkType.rightAnkle, 100, 100),
        
         PoseLandmarkType.leftShoulder: createLandmark(PoseLandmarkType.leftShoulder, 0, 100),
        PoseLandmarkType.leftHip: createLandmark(PoseLandmarkType.leftHip, 50, 50),
        PoseLandmarkType.leftAnkle: createLandmark(PoseLandmarkType.leftAnkle, 100, 100),
      };

      final result = plankLogic.analyze(Pose(landmarks: landmarks));
      expect(result.statusTitle, equals('DÜZELT'));
      expect(result.feedback, contains('indir')); // Expect "Kalçanı biraz indir!"
    });
    
    test('should return DÜZELT (Raise Hips) for Sag position', () {
      // Sag: Hips are LOWER (Larger Y) than Shoulder/Ankle line
      // Shoulder (0, 100), Hip (50, 150 - Low), Ankle (100, 100)
      final landmarks = <PoseLandmarkType, PoseLandmark>{
        PoseLandmarkType.rightShoulder: createLandmark(PoseLandmarkType.rightShoulder, 0, 100),
        PoseLandmarkType.rightHip: createLandmark(PoseLandmarkType.rightHip, 50, 150), // 150 is LOWER than 100
        PoseLandmarkType.rightAnkle: createLandmark(PoseLandmarkType.rightAnkle, 100, 100),
        
        PoseLandmarkType.leftShoulder: createLandmark(PoseLandmarkType.leftShoulder, 0, 100),
        PoseLandmarkType.leftHip: createLandmark(PoseLandmarkType.leftHip, 50, 150),
        PoseLandmarkType.leftAnkle: createLandmark(PoseLandmarkType.leftAnkle, 100, 100),
      };

      final result = plankLogic.analyze(Pose(landmarks: landmarks));
      expect(result.statusTitle, equals('DÜZELT'));
      expect(result.feedback, contains('kaldır')); // Expect "Kalçanı kaldır!"
    });
  });
}
