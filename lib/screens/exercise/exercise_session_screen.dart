import 'dart:async';
import 'dart:io'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../pose_estimation/pose_painter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../logic/pose_analysis/exercise_logic.dart';
import '../../logic/pose_analysis/analysis_result.dart';
import '../../logic/pose_analysis/squat_logic.dart';
import '../../logic/pose_analysis/plank_logic.dart';
import '../../logic/pose_analysis/mekik_logic.dart';
import '../../logic/pose_analysis/weight_logic.dart';
import '../../logic/pose_analysis/pose_smoother.dart';

import 'package:auto_route/auto_route.dart';
import '../../services/user_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

@RoutePage()
class ExerciseSessionScreen extends StatefulWidget {
  const ExerciseSessionScreen({
    super.key,
    required this.exerciseName,
  });

  final String exerciseName;

  @override
  State<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends State<ExerciseSessionScreen>
    with WidgetsBindingObserver {
  // ML Kit State
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions(model: PoseDetectionModel.accurate));
  final PoseSmoother _poseSmoother = PoseSmoother(alpha: 0.6); // 0.6 = Moderate smoothing
  bool _canProcess = true;
  bool _isBusy = false;
  int _frameCounter = 0; // Throttling counter
  CustomPainter? _customPaint;
  late ExerciseLogic _exerciseLogic;
  
  // Feedback State
  String _feedbackStatus = "Analiz Ediliyor...";
  String _feedbackDetail = "Kameraya geçiniz.";
  bool _isGoodPosture = false;
  double _score = 0.0;
  int _reps = 0;

  // Audio Feedback
  FlutterTts flutterTts = FlutterTts();
  DateTime? _lastSpeechTime; // Throttle speech

  CameraController? _controller;
  bool _isCameraInitialized = false;
  CameraLensDirection _cameraLensDirection = CameraLensDirection.front;

  void _switchCamera() async {
    // 1. Unmount preview immediately to prevent "Disposed CameraController" error
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }

    // 2. Dispose existing controller
    if (_controller != null) {
      await _controller!.dispose();
    }

    // 3. Update direction and re-initialize
    if (mounted) {
      setState(() {
        _cameraLensDirection =
            _cameraLensDirection == CameraLensDirection.front
                ? CameraLensDirection.back
                : CameraLensDirection.front;
      });
    }
    
    _initCamera();
  }

  bool _isCountdown = true; 
  int _countdownValue = 3;
  Timer? _timer;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _stopwatchTimer;
  String _formattedTime = "00:00";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeLogic();
    _initCamera();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("tr-TR");
    await flutterTts.setSpeechRate(0.5);
  }

  void _initializeLogic() {
    switch (widget.exerciseName) {
      case 'Squat':
        _exerciseLogic = SquatLogic();
        break;
      case 'Plank':
        _exerciseLogic = PlankLogic();
        break;
      case 'Mekik':
        _exerciseLogic = MekikLogic();
        break;
      case 'Ağırlık':
        _exerciseLogic = WeightLogic();
        break;
      default:
        _exerciseLogic = SquatLogic();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _canProcess = false;
    _poseDetector.close();
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      // Free up resources when not in foreground (e.g. screenshot, app switch)
      _isCameraInitialized = false;
      _controller?.dispose();
      _controller = null;
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      // Re-initialize camera when coming back
      _isCameraInitialized = false; 
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      CameraDescription camera = cameras.firstWhere(
        (camera) => camera.lensDirection == _cameraLensDirection,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21 // Android specifics
            : ImageFormatGroup.bgra8888, // iOS specific
      );
      
      await _controller!.initialize();
      
      if (!mounted) return;

      // Start Image Stream
      _controller?.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
      });
      
      _startCountdown();
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownValue > 1) {
          _countdownValue--;
        } else {
          _timer?.cancel();
          _startRecording();
        }
      });
    });
  }

  void _startRecording() {
    setState(() {
      _isCountdown = false; 
    });
    _stopwatch.start();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final elapsed = _stopwatch.elapsed;
      setState(() {
        final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        _formattedTime = "$minutes:$seconds";
      });
    });
  }

  Future<void> _finishSession() async {
    try {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
      
      // Save to user stats
      final durationMinutes = _stopwatch.elapsed.inMinutes > 0 ? _stopwatch.elapsed.inMinutes : 1;
      await UserService().addSession(widget.exerciseName, durationMinutes);
      
      // Award XP (Gamification)
      // Dynamic: 10 XP per minute + 20 Base XP
      int earnedXp = 20 + (durationMinutes * 10);
      await UserService().addXp(earnedXp);
    } catch (e) {
      debugPrint('Error finishing session: $e');
      // Even if saving fails, we should probably allow the user to exit
      // but maybe show a snackbar.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler kaydedilirken bir hata oluştu: $e')),
        );
      }
    } finally {
      if (mounted) {
        context.router.maybePop();
      }
    }
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> _processCameraImage(CameraImage image) async {
    // Throttle: Process only every 2nd frame (15fps) for balance between lag and smoothness
    _frameCounter++;
    if (_frameCounter % 2 != 0) return;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      var rotationCompensation = _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    
    // Only supporting NV21 (Android) and BGRA8888 (iOS) for now as per ML Kit requirement
    if (format == null || (defaultTargetPlatform == TargetPlatform.android && format != InputImageFormat.nv21) || (defaultTargetPlatform == TargetPlatform.iOS && format != InputImageFormat.bgra8888)) {
       // return null; 
    }

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final inputImageMetadata = InputImageMetadata(
      size: imageSize,
      rotation: rotation,
      format: format ?? InputImageFormat.nv21,
      bytesPerRow: image.planes[0].bytesPerRow,
    );
    return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    
    try {
      final poses = await _poseDetector.processImage(inputImage);
      
      if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
         
         AnalysisResult? result;
         Pose? smoothedPose;

         if (poses.isNotEmpty) {
           final rawPose = poses.first;
           smoothedPose = _poseSmoother.smooth(rawPose);
           
           result = _exerciseLogic.analyze(smoothedPose!);
           
           // Audio Feedback (Throttle)
           if (!result.isGoodPosture && !_isCountdown) {
               final now = DateTime.now();
               // Throttle: 3 seconds
               if (_lastSpeechTime == null || now.difference(_lastSpeechTime!) > const Duration(seconds: 3)) {
                   _lastSpeechTime = now;
                   if (result.feedback.isNotEmpty) {
                      flutterTts.speak(result.feedback);
                   }
               }
           }
         } else {
            result = AnalysisResult(
              feedback: "Kamera seni göremiyor.",
              statusTitle: "GÖRÜNÜM YOK",
              isGoodPosture: false,
            );
         }

         if (mounted && result != null) {
           setState(() {
             _feedbackStatus = result!.statusTitle;
             _feedbackDetail = result.feedback;
             _isGoodPosture = result.isGoodPosture;
             _score = result.score ?? 0.0;
             _reps = _exerciseLogic.repCount;
           });
         }

         if (result != null && smoothedPose != null) {
             final painter = PosePainter(
                [smoothedPose], 
                inputImage.metadata!.size,
                inputImage.metadata!.rotation,
                _controller!.description.lensDirection,
                result.isGoodPosture ? const Color(0xFF00C853) : (result.statusTitle == "DİKKAT" || result.statusTitle == "DÜZELT" || result.statusTitle == "DİK DUR" ? Colors.red : Colors.white),
                _exerciseLogic.relevantLandmarks.toSet(),
                result.jointColors,
                result.overlayText,
             );
             _customPaint = painter;
         }
      } else {
        _customPaint = null;
      }

    } catch (e) {
      debugPrint("Error processing image: $e");
    }

    _isBusy = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
           // 1. Camera Layer
           if (_isCameraInitialized && _controller != null && _controller!.value.isInitialized)
             Positioned.fill(
                child: CameraPreview(_controller!),
             ),
             
           // 2. Pose Painter Overlay (Skeleton)
           if (!_isCountdown && _customPaint != null)
             Positioned.fill(
               child: CustomPaint(
                 painter: _customPaint!,
               ),
             ),
             
          // 3. UI Overlay
          if (_isCountdown)
            _buildCountdownView()
          else
            _buildRecordingView(),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    return Container(
      color: const Color(0xFFF4F5F7).withValues(alpha: 0.95),
      width: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
               child: SizedBox(
                width: double.infinity,
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       widget.exerciseName,
                       style: const TextStyle(
                         fontSize: 48,
                         fontWeight: FontWeight.w900,
                         color: Colors.black12,
                         height: 1.0,
                       ),
                     ),
                     const Text(
                       'Hazırlan...',
                       style: TextStyle(
                         fontSize: 32,
                         fontWeight: FontWeight.w600,
                         color: Colors.black45,
                       ),
                     ),
                   ],
                 ),
               ),
             ),
             
             const Spacer(),
             
             Container(
               width: 140,
               height: 140,
               alignment: Alignment.center,
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(30),
                 boxShadow: [
                   BoxShadow(
                     color: Colors.black.withValues(alpha: 0.1),
                     blurRadius: 30,
                     offset: const Offset(0, 15),
                   ),
                 ]
               ),
               child: Text(
                 '$_countdownValue',
                 style: const TextStyle(
                   fontSize: 80,
                   fontWeight: FontWeight.bold,
                   color: Color(0xFFE0E0E0),
                 ),
               ),
             ),
             
             const Spacer(),
             
             Padding(
               padding: const EdgeInsets.all(24),
               child: TextButton(
                 onPressed: () => context.router.maybePop(),
                 child: const Text(
                    'İptal Et',
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.w500
                    ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar: Navigation, Title, Score
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Row(
              children: [
                // 1. Back Button (Glassy)
                InkWell(
                  onTap: () => context.router.maybePop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ),
                
                const Spacer(),
                
                // 2. Exercise Title (with Glow)
                Text(
                  widget.exerciseName.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: const Color(0xFF00C853).withValues(alpha: 0.6), blurRadius: 15)
                    ]
                  ),
                ),
                
                const Spacer(),
                
                // 3. Score Badge (Premium Look)
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     gradient: LinearGradient(
                       colors: [const Color(0xFF00C853).withValues(alpha: 0.8), const Color(0xFF00E676).withValues(alpha: 0.8)],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight
                     ),
                     borderRadius: BorderRadius.circular(30),
                     boxShadow: [
                       BoxShadow(
                         color: const Color(0xFF00C853).withValues(alpha: 0.4),
                         blurRadius: 12,
                         offset: const Offset(0, 4)
                       )
                     ]
                   ),
                   child: Row(
                     children: [
                       const Icon(Icons.bolt, color: Colors.white, size: 16),
                       const SizedBox(width: 4),
                       Text(
                         '${_score.toInt()}',
                         style: const TextStyle(
                           color: Colors.white,
                           fontWeight: FontWeight.bold,
                           fontSize: 16,
                         ),
                       ),
                     ],
                   ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Secondary Bar: Status Chips + Camera Toggle (Centered Row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12)
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       Icon(
                         _isGoodPosture ? Icons.check_circle : Icons.warning_rounded,
                         color: _isGoodPosture ? const Color(0xFF00C853) : Colors.orange,
                         size: 16
                       ),
                       const SizedBox(width: 8),
                       Text(
                         _isGoodPosture ? 'HARİKA FORM' : 'DÜZELT',
                         style: TextStyle(
                           color: _isGoodPosture ? Colors.white : Colors.orangeAccent,
                           fontWeight: FontWeight.bold,
                           fontSize: 12
                         ),
                       ),
                       const SizedBox(width: 12),
                       Container(width: 1, height: 12, color: Colors.white24),
                       const SizedBox(width: 12),
                       const Text(
                         'AI GÖZÜ',
                         style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600),
                       )
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Camera Toggle (Floating on right)
                InkWell(
                  onTap: _switchCamera,
                  child: Container(
                     padding: const EdgeInsets.all(10),
                     decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10),
                     ),
                    child: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          
          // Bottom Dashboard (Compact)
          Container(
             margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
             decoration: BoxDecoration(
               color: Colors.white,
               borderRadius: BorderRadius.circular(24),

               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 20,
                   offset: const Offset(0, 10),
                 )
               ]
             ),
             padding: const EdgeInsets.all(20),
             child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                // Reps and Feedback Row (Merged for compactness)
                Row(
                  children: [
                    // Rep Counter
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           const Text('TEKRAR', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                           Text.rich(
                              TextSpan(
                               children: [
                                 TextSpan(text: '$_reps', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w900)),
                                 const TextSpan(text: '/10', style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w600)),
                               ],
                             ),
                           ),
                         ],
                    ),
                    const SizedBox(width: 20),
                    // Divider
                    Container(height: 30, width: 1, color: Colors.grey[300]),
                    const SizedBox(width: 20),
                    // Feedback
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            _feedbackStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _isGoodPosture ? const Color(0xFF00C853) : Colors.red,
                              fontSize: 14
                            ),
                          ),
                          Text(
                            _feedbackDetail,
                            style: const TextStyle(color: Colors.black54, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    ),
                    // Timer
                     Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Finish Button (Smaller)
                SizedBox(
                   width: double.infinity,
                   height: 44,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF00C853),
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     onPressed: _finishSession,
                     child: const Text('BİTİR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                   ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? color;

  const _AnalysisChip({required this.label, required this.isActive, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? const Color(0xFF00C853) : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle_outline : Icons.radio_button_unchecked,
            color: color ?? (isActive ? const Color(0xFF00C853) : Colors.white54),
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Mock Skeleton for visual effect
class SkeletonOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Setup Paint
    final linePaint = Paint()
      ..color = const Color(0xFF00C853).withValues(alpha: 0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // 2. Mock Points (Simulating a Squat/Standing pose in center)
    // We'll define relative coordinates (0.0 - 1.0)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.height * 0.4; // Skeleton size relative to screen
    
    // Head
    final head = Offset(centerX, centerY - scale);
    final neck = Offset(centerX, centerY - scale + 30);
    
    // Shoulders
    final lShoulder = Offset(centerX - 40, centerY - scale + 40);
    final rShoulder = Offset(centerX + 40, centerY - scale + 40);
    
    // Elbows
    final lElbow = Offset(centerX - 60, centerY - scale + 100);
    final rElbow = Offset(centerX + 60, centerY - scale + 100);
    
    // Wrists (Hands up position for guard)
    final lWrist = Offset(centerX - 50, centerY - scale + 60);
    final rWrist = Offset(centerX + 50, centerY - scale + 60);

    // Spine
    final hipCenter = Offset(centerX, centerY);
    final lHip = Offset(centerX - 30, centerY);
    final rHip = Offset(centerX + 30, centerY);
    
    // Knees (Squatting slightly)
    final lKnee = Offset(centerX - 40, centerY + 100);
    final rKnee = Offset(centerX + 40, centerY + 100);
    
    // Ankles
    final lAnkle = Offset(centerX - 40, centerY + 200);
    final rAnkle = Offset(centerX + 40, centerY + 200);

    // 3. Draw Lines (Bones)
    // Torso
    canvas.drawLine(head, neck, linePaint);
    canvas.drawLine(neck, hipCenter, linePaint);
    canvas.drawLine(lShoulder, rShoulder, linePaint);
    canvas.drawLine(lHip, rHip, linePaint);
    canvas.drawLine(neck, lShoulder, linePaint);
    canvas.drawLine(neck, rShoulder, linePaint);
    canvas.drawLine(hipCenter, lHip, linePaint);
    canvas.drawLine(hipCenter, rHip, linePaint);
    
    // Arms
    canvas.drawLine(lShoulder, lElbow, linePaint);
    canvas.drawLine(lElbow, lWrist, linePaint);
    canvas.drawLine(rShoulder, rElbow, linePaint);
    canvas.drawLine(rElbow, rWrist, linePaint);
    
    // Legs
    canvas.drawLine(lHip, lKnee, linePaint);
    canvas.drawLine(lKnee, lAnkle, linePaint);
    canvas.drawLine(rHip, rKnee, linePaint);
    canvas.drawLine(rKnee, rAnkle, linePaint);

    // 4. Draw Joints (Dots)
    final joints = [head, neck, lShoulder, rShoulder, lElbow, rElbow, lWrist, rWrist, lHip, rHip, lKnee, rKnee, lAnkle, rAnkle];
    for (final point in joints) {
      // Glow effect
      canvas.drawCircle(point, 6, Paint()..color = const Color(0xFF00C853).withValues(alpha: 0.4));
      // Core joint
      canvas.drawCircle(point, 3, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
