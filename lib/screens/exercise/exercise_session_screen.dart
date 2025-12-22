import 'dart:async';
import 'dart:io'; 
import 'dart:ui'; // For ImageFilter 
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
import '../../logic/pose_analysis/pushup_logic.dart';
import '../../logic/pose_analysis/lunge_logic.dart';
import '../../logic/pose_analysis/jumping_jack_logic.dart';
import '../../logic/pose_analysis/shoulder_press_logic.dart';
import '../../logic/pose_analysis/glute_bridge_logic.dart';
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
    this.customReps,
    this.customDuration,
  });

  final String exerciseName;
  final int? customReps;
  final int? customDuration;

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
  double _cumulativeScore = 0.0;
  int _scoreCount = 0;
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
  
  // Plank Specific State
  int _plankRemainingSeconds = 30;
  bool _isCompleted = false;

  // Targets
  int _targetReps = 10;
  int _targetDuration = 30;

  @override
  void initState() {
    super.initState();
    // Initialize targets from valid custom values or defaults
    _targetReps = widget.customReps ?? 10;
    _targetDuration = widget.customDuration ?? 30;
    _plankRemainingSeconds = _targetDuration; // Sync duration for time-based
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
      case 'Şınav':
        _exerciseLogic = PushUpLogic();
        break;
      case 'Lunge':
        _exerciseLogic = LungeLogic();
        break;
      case 'Jumping Jacks':
        _exerciseLogic = JumpingJackLogic();
        break;
      case 'Shoulder Press':
        _exerciseLogic = ShoulderPressLogic();
        break;
      case 'Glute Bridge':
        _exerciseLogic = GluteBridgeLogic();
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
    _stopwatchTimer?.cancel();
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
    _timer?.cancel(); // Cancel any existing timer to prevent duplicates
    _countdownValue = 3; // Reset value ensures consistent 3-2-1
    _isCountdown = true; // Ensure visual state is active

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
      
      // Optional: Add a Tick Sound here if requested, but user only asked for "Turkish voice check" and "Timer fix".
    });
  }

  void _startRecording() {
    setState(() {
      _isCountdown = false; 
    });
    
    if (!['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName)) {
      _stopwatch.start();
    }
    
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      
      if (['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName)) {
        // Time-based Logic: Count down ONLY if posture is good
        if (_isGoodPosture) {
           setState(() {
             if (_plankRemainingSeconds > 0) {
               _plankRemainingSeconds--;
               
               // Audio Alert for last 3 seconds (Trigger AFTER decrement to match UI)
               if (_plankRemainingSeconds > 0 && _plankRemainingSeconds <= 3) {
                  flutterTts.speak("$_plankRemainingSeconds");
               }
               
               // Format for Plank (Countdown)
               final minutes = (_plankRemainingSeconds ~/ 60).toString().padLeft(2, '0');
               final seconds = (_plankRemainingSeconds % 60).toString().padLeft(2, '0');
               _formattedTime = "$minutes:$seconds";
             } else {
               // FINISH: Show completion screen
               _stopwatchTimer?.cancel();
               setState(() {
                 _isCompleted = true;
               });
             }
           });
        }
      } else {
        // Standard Logic: Count up (Stopwatch)
        final elapsed = _stopwatch.elapsed;
        setState(() {
          final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
          final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
          _formattedTime = "$minutes:$seconds";
        });
      }
    });
  }

  Future<void> _finishSession() async {
    try {
      _stopwatch.stop();
      _stopwatchTimer?.cancel();
      
      // Calculate duration and reps
      int durationSeconds = 0;
      int? reps;

      if (['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName)) {
        // Time-based: Target - Remaining
        durationSeconds = _targetDuration - _plankRemainingSeconds;
      } else {
        // Rep-based: Stopwatch elapsed
        durationSeconds = _stopwatch.elapsed.inSeconds;
        reps = _reps;
      }

      // Legacy minute calculation (minimum 1 minute for display compatibility if needed, using rounding up)
      int durationMinutes = (durationSeconds / 60).ceil();
      if (durationMinutes < 1) durationMinutes = 1; 

      await UserService().addSession(
        widget.exerciseName, 
        durationMinutes, 
        _score.toInt(),
        reps: reps,
        durationSeconds: durationSeconds,
      );
      
      // Award XP (Gamification)
      // Dynamic: 10 XP per minute + 20 Base XP
      int earnedXp = 20 + (durationMinutes * 10);
      await UserService().addXp(earnedXp);
    } catch (e) {
      debugPrint('Error finishing session: $e');
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

  // Targets
  // Targets (Moved to state variables for customization)
  // final int _targetReps = 10; 
  // final int _targetDuration = 30;

  void _checkCompletion() {
    if (_isCompleted) return;

    bool reachedStart = false;
    
    // Check Targets based on Exercise Type
    // Check Targets based on Exercise Type
    if (['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName)) {
       if (_plankRemainingSeconds == 0) reachedStart = true;
    } else {
       // Rep based exercises
       // Rep based exercises
       if (_reps >= _targetReps) reachedStart = true;
    }

    if (reachedStart) {
      // Trigger Completion State
      setState(() {
        _isCompleted = true;
        _stopwatch.stop();
        _stopwatchTimer?.cancel();
        _timer?.cancel();
      });
      
      // Play Success Sound
      flutterTts.speak("Tebrikler! Hedef tamamlandı.");
    }
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
           // Only speak if NOT completed and NOT countdown
           if (!result.isGoodPosture && !_isCountdown && !_isCompleted) {
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
              status: AnalysisStatus.neutral,
              statusTitle: "GÖRÜNÜM YOK",
            );
         }

         if (mounted && result != null && !_isCompleted) {
           setState(() {
             _feedbackStatus = result!.statusTitle;
             _feedbackDetail = result.feedback;
             _isGoodPosture = result.isGoodPosture;
             
             // Calculate Average Score (Ignore 0.0/Idle states)
             if (result.score != null && result.score! > 10) { // Filter out random low noise
                _cumulativeScore += result.score!;
                _scoreCount++;
                _score = _cumulativeScore / _scoreCount;
             }
             
             _reps = _exerciseLogic.repCount;
           });
           
           _checkCompletion();
         }

         if (result != null && smoothedPose != null) {
             final painter = PosePainter(
                [smoothedPose], 
                inputImage.metadata!.size,
                inputImage.metadata!.rotation,
                _controller!.description.lensDirection,
                result.isGoodPosture ? const Color(0xFF00C853) : (result.statusTitle == "DİKKAT" || result.statusTitle == "DÜZELT" || result.statusTitle == "DİK DUR" || result.statusTitle == "POZİSYON AL" ? Colors.red : Colors.white),
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
           if (!_isCountdown && _customPaint != null && !_isCompleted)
             Positioned.fill(
               child: CustomPaint(
                 painter: _customPaint!,
               ),
             ),
             
          // 3. UI Overlay
          if (_isCountdown)
            _buildCountdownView()
          else if (_isCompleted)
            _buildCompletionView()
          else
            _buildRecordingView(),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    // Determine specific tip based on exercise name
    String tip = "Telefonu sabitle ve ekranda görün.";
    IconData tipIcon = Icons.accessibility_new_rounded;
    
    // Side Profile Exercises
    if (['Squat', 'Lunge', 'Şınav', 'Plank', 'Glute Bridge', 'Mekik'].contains(widget.exerciseName)) {
      tip = "Kameraya YAN profilini dönecek şekilde geç.";
      tipIcon = Icons.switch_left_rounded;
    } 
    // Front Profile Exercises
    else if (['Jumping Jacks', 'Shoulder Press', 'Ağırlık'].contains(widget.exerciseName)) {
      tip = "Kameraya TAM KARŞIDAN bakacak şekilde geç.";
      tipIcon = Icons.accessibility_rounded;
    }

    return Stack(
      children: [
        // 1. Blur Overlay (Glassmorphism)
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6), // Darker overlay for contrast
            ),
          ),
        ),

        // 2. Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Header
                Text(
                  widget.exerciseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "HAZIRLAN",
                  style: TextStyle(
                    color: const Color(0xFF00C853).withValues(alpha: 0.9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                ),

                const Spacer(flex: 1),

                // Main Countdown Number (Animated)
                Container(
                  width: 180,
                  height: 180,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), 
                      width: 4
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.2),
                        blurRadius: 50,
                        spreadRadius: 10,
                      )
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '$_countdownValue',
                      key: ValueKey<int>(_countdownValue),
                      style: const TextStyle(
                        fontSize: 100,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 1),

                // Preparation Tip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(tipIcon, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "İPUCU",
                              style: TextStyle(
                                color: Color(0xFF00C853),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tip,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Cancel Button
                TextButton(
                  onPressed: () => context.router.maybePop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "İPTAL ET",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCompletionView() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      width: double.infinity,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C853).withValues(alpha: 0.3),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ]
          ),
          child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               const Icon(Icons.emoji_events_rounded, color: Color(0xFF00C853), size: 64),
               const SizedBox(height: 24),
               const Text(
                  "HEDEF TAMAMLANDI!",
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 24,
                   fontWeight: FontWeight.w800, // Reduced from w900
                   color: Colors.black87,
                 ),
               ),
               const SizedBox(height: 8),
               const Text(
                 "Harika iş çıkardın. Formun kusursuzdu!",
                 textAlign: TextAlign.center,
                 style: TextStyle(
                   fontSize: 14,
                   color: Colors.black45,
                   fontWeight: FontWeight.w500,
                 ),
               ),
               const SizedBox(height: 32),
               
               // Stats (Dynamic)
               Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: const Color(0xFFF5F7FA),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceAround,
                   children: [
                      Column(
                        children: [
                          Text(
                             ['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName) ? "SÜRE" : "TEKRAR", 
                             style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)
                          ),
                          const SizedBox(height: 4),
                          Text(
                             ['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName) 
                               ? "${_targetDuration}sn" 
                               : "$_reps", 
                             style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                          ),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.black12),
                      Column(
                        children: [
                          const Text("PUAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38)),
                          const SizedBox(height: 4),
                          Text("${_score.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00C853))),
                        ],
                      ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 32),
               
               SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   onPressed: _finishSession,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF00C853),
                     foregroundColor: Colors.white,
                     elevation: 0,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   ),
                   child: const Text(
                     "KAYDET VE ÇIK",
                     style: TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
               ),
             ],
          ),
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
                    // Rep Counter (Hidden for Time-based)
                    if (!['Plank', 'Glute Bridge', 'Squat'].contains(widget.exerciseName)) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             const Text('TEKRAR', style: TextStyle(color: Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                             Text.rich(
                                TextSpan(
                                 children: [
                                   TextSpan(text: '$_reps', style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.w800)), // Reduced from w900
                                   TextSpan(text: '/$_targetReps', style: const TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w600)),
                                 ],
                               ),
                             ),
                           ],
                      ),
                      const SizedBox(width: 20),
                      // Divider
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      const SizedBox(width: 20),
                    ],
                    
                    // Feedback
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                             _feedbackStatus,
                            style: TextStyle(
                              fontWeight: FontWeight.w800, // Reduced from w900
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
                    Column(
                       children: [
                         Text(
                            _formattedTime,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (widget.exerciseName == 'Plank' && !_isGoodPosture)
                             const Text(
                               "DURAKLATILDI",
                               style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                             ),
                       ],
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
