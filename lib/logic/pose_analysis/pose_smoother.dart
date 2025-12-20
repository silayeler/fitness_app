import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// A class to smooth pose landmarks using Exponential Moving Average (EMA).
/// This reduces jitter in the detected keypoints for a more fluid visual experience.
class PoseSmoother {
  // Alpha determines the smoothing factor. 
  // Lower alpha (e.g. 0.1) = More smoothing, more lag.
  // Higher alpha (e.g. 0.8) = Less smoothing, more responsive.
  final double alpha;
  
  // Store the previous filtered state for each landmark type
  final Map<PoseLandmarkType, PoseLandmark> _previousLandmarks = {};

  PoseSmoother({this.alpha = 0.5});

  /// Processes a raw pose and returns a smoothed pose.
  Pose smooth(Pose rawPose) {
    if (rawPose.landmarks.isEmpty) return rawPose;

    Map<PoseLandmarkType, PoseLandmark> smoothedLandmarks = {};

    rawPose.landmarks.forEach((type, currentLandmark) {
      if (_previousLandmarks.containsKey(type)) {
        final prev = _previousLandmarks[type]!;
        
        // Apply EMA filter
        double smoothX = (alpha * currentLandmark.x) + ((1 - alpha) * prev.x);
        double smoothY = (alpha * currentLandmark.y) + ((1 - alpha) * prev.y);
        double smoothZ = (alpha * currentLandmark.z) + ((1 - alpha) * prev.z);
        double smoothLikelihood = (alpha * currentLandmark.likelihood) + ((1 - alpha) * prev.likelihood);

        final smoothed = PoseLandmark(
          type: type,
          x: smoothX,
          y: smoothY,
          z: smoothZ,
          likelihood: smoothLikelihood,
        );

        smoothedLandmarks[type] = smoothed;
        _previousLandmarks[type] = smoothed;
      } else {
        // First frame, no previous data
        smoothedLandmarks[type] = currentLandmark;
        _previousLandmarks[type] = currentLandmark;
      }
    });

    return Pose(landmarks: smoothedLandmarks);
  }

  void reset() {
    _previousLandmarks.clear();
  }
}
