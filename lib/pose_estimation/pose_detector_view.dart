
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart'; // [RESTORED]
import 'package:path/path.dart' as p;        // [RESTORED]
import 'pose_painter.dart';
import 'package:fitness_app/logic/pose_analysis/exercise_logic.dart';
import 'package:fitness_app/logic/pose_analysis/squat_logic.dart';
import 'package:fitness_app/logic/pose_analysis/plank_logic.dart';
import 'package:fitness_app/logic/pose_analysis/mekik_logic.dart';
import 'package:fitness_app/logic/pose_analysis/weight_logic.dart';
// import 'posture_analyzer.dart'; // No longer needed
import 'package:fitness_app/logic/pose_analysis/analysis_result.dart';
import 'ui_styles.dart';
import 'library_view.dart';

class PoseDetectorView extends StatefulWidget {
  final String exerciseName;

  const PoseDetectorView({super.key, required this.exerciseName});

  @override
  State<StatefulWidget> createState() => _PoseDetectorViewState();
}

class _PoseDetectorViewState extends State<PoseDetectorView> with TickerProviderStateMixin {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions(model: PoseDetectionModel.accurate));
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPainter? _customPaint;
  late ExerciseLogic _exerciseLogic;

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  
  // App State
  bool _isRecording = false;
  int _reps = 0;
  int _score = 98;
  String _postureStatus = ""; // Empty means checking or good
  String _feedbackMessage = "";
  
  // Timer State
  Timer? _timer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeLogic();
    _initializeCamera();
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
        _exerciseLogic = SquatLogic(); // Default fallback
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _stopTimer();
    _poseDetector.close();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (await Permission.camera.request().isGranted) {
      _cameras = await availableCameras();
      if (_cameras.length > 1) {
        _cameraIndex = 1; 
      }
      if (_cameras.isNotEmpty) {
        _startLiveFeed();
      }
    }
  }

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    if (_controller != null) {
      await _controller!.stopImageStream();
      await _controller!.dispose();
      _controller = null;
    }
    _startLiveFeed();
  }

  // --- Timer Logic ---
  void _startTimer() {
    _elapsedSeconds = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
       setState(() {
         _elapsedSeconds++;
       });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatTime(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // --- Button Actions ---
  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      // STOP RECORDING
      try {
        _showInfoInternal("Saving video...");
        
        final file = await _controller!.stopVideoRecording();
        _stopTimer();
        if (mounted) setState(() => _isRecording = false);
        
        // Save to Documents
        final directory = await getApplicationDocumentsDirectory();
        final String newPath = p.join(directory.path, 'squat_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await file.saveTo(newPath);

        if (mounted) _showInfoInternal("✅ Video saved to Library");
      } catch (e) {
        _stopTimer();
        if (mounted) setState(() => _isRecording = false);
        if (mounted) _showInfoInternal("Error saving: $e");
      }
    } else {
      // START RECORDING
      try {
         // Note: Some Android devices might not support simultaneous ImageStreaming + VideoRecording.
         // If it crashes, we might need to stopImageStream() before recording, 
         // which would pause the pose detection. 
         // For now, attempting simultaneous as it's the ideal UX.
         
        await _controller!.startVideoRecording();
        _startTimer();
        _reps = 0;
        if (mounted) setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) _showInfoInternal("Error starting: $e");
      }
    }
  }

  void _openLibrary() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LibraryView()));
  }

  void _closeApp() {
    // Navigate back or exit
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      SystemNavigator.pop();
    }
  }

  void _showInfoInternal(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)), 
        backgroundColor: UIStyles.darkBackground.withAlpha(200),
        duration: Duration(seconds: 1),
      )
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _cameras[_cameraIndex];
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

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    
    try {
      final poses = await _poseDetector.processImage(inputImage);
      if (inputImage.metadata?.size != null &&
          inputImage.metadata?.rotation != null) {
        
        // Analyze posture
        String status = "";
        String feedback = "";
        
        if (poses.isNotEmpty) {
           final AnalysisResult result = _exerciseLogic.analyze(poses.first);
           
           if (result.isGoodPosture) {
             status = result.statusTitle; // e.g. "HARİKA" or "DEVAM"
           } else {
             status = "Bad";
             feedback = result.feedback;
           }

           // Update score from logic if available
           if (result.score != null) {
              _score = result.score!.toInt();
           }
           
           // Pass result data to painter
           final painter = PosePainter(
              poses,
              inputImage.metadata!.size,
              inputImage.metadata!.rotation,
              _cameras[_cameraIndex].lensDirection,
              status != "Bad" ? UIStyles.primaryBlue : UIStyles.dangerRed,
              _exerciseLogic.relevantLandmarks.toSet(),
              result.jointColors,
              result.overlayText,
           );
           _customPaint = painter;

           // Updating state for UI
           if (mounted) {
              setState(() {
                _postureStatus = status == "Bad" ? "Bad" : "Good";
                _feedbackMessage = feedback;
                if (_exerciseLogic is SquatLogic) {
                   _reps = (_exerciseLogic as SquatLogic).repCount;
                }
              });
           }
        } else {
           _customPaint = null;
        }
      } else {
        _customPaint = null;
      }
    } catch (e) {
      // print('Error processing image: $e');
    }
    
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera Preview
          if (_controller != null && _controller!.value.isInitialized)
             Center(
               child: CameraPreview(_controller!)
             ),
             
          // 2. Simple Dark Overlay for text readability
          Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topCenter,
                   end: Alignment.bottomCenter,
                   colors: [
                     Colors.black.withAlpha(150),
                     Colors.transparent,
                     Colors.transparent,
                     Colors.black.withAlpha(200),
                   ]
                 ),
               ),
             ),
          ),

          // 3. Painter (Skeleton)
          if (_customPaint != null) CustomPaint(painter: _customPaint),

          // 4. Header (Top Nav)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Close Button
                    GestureDetector(
                      onTap: _closeApp,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.black26, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12)
                        ),
                        child: Icon(Icons.close, color: Colors.white, size: 24),
                      ),
                    ),
                    
                    // Title & Timer
                    Column(
                      children: [
                        Text("${widget.exerciseName} Analysis", style: UIStyles.heading),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer, color: _isRecording ? UIStyles.dangerRed : Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text(_formatTime(_elapsedSeconds), style: UIStyles.timer.copyWith(color: _isRecording ? UIStyles.dangerRed : Colors.white70)),
                          ],
                        )
                      ],
                    ),

                    // Settings Button
                    GestureDetector(
                      onTap: () => _showInfoInternal("Settings clicked"),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.black26, 
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white12)
                        ),
                        child: Icon(Icons.settings, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Floating Status Chip
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: UIStyles.primaryBlue, size: 20),
                        SizedBox(width: 8),
                        Text("$_reps Reps Completed", style: UIStyles.chipText),
                        Container(height: 16, width: 1, color: Colors.white24, margin: EdgeInsets.symmetric(horizontal: 12)),
                        Text("Score: $_score%", style: UIStyles.scoreText),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 6. Feedback / Warning Toast (Dynamic)
          if (_postureStatus == "Bad")
          Positioned(
            bottom: 140, 
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border(left: BorderSide(color: UIStyles.dangerRed, width: 4)),
                  ),
                  child: Row(
                    children: [
                       Container(
                         padding: EdgeInsets.all(8),
                         decoration: BoxDecoration(color: UIStyles.dangerRed.withAlpha(50), shape: BoxShape.circle),
                         child: Icon(Icons.warning, color: UIStyles.dangerRed, size: 24),
                       ),
                       SizedBox(width: 16),
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text("Correction Needed", style: UIStyles.cardTitle),
                             Text(_feedbackMessage.isNotEmpty ? _feedbackMessage : "Check your form.", style: UIStyles.cardBody),
                           ],
                         ),
                       ),
                       GestureDetector(
                         onTap: () => _showInfoInternal("Detailed analysis info..."),
                         child: Container(
                           padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                           child: Text("Details", style: UIStyles.buttonText),
                         ),
                       )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 7. Bottom Control Bar (Library, Record, Flip)
          Positioned(
             bottom: 0,
             left: 0,
             right: 0,
             child: SafeArea(
               child: Container(
                 padding: EdgeInsets.only(bottom: 20, top: 10),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                   children: [
                     // Library
                     GestureDetector(
                       onTap: _openLibrary,
                       child: Column(
                         children: [
                           Container(
                             padding: EdgeInsets.all(12),
                             decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black45, border: Border.all(color: Colors.white12)),
                             child: Icon(Icons.photo_library, color: Colors.white, size: 24),
                           ),
                           SizedBox(height: 4),
                           Text("Library", style: UIStyles.buttonText) 
                         ],
                       ),
                     ),
                     
                     // Record Button
                     GestureDetector(
                       onTap: _toggleRecording,
                       child: Container(
                         height: 80,
                         width: 80,
                         padding: EdgeInsets.all(4),
                         decoration: BoxDecoration(
                           shape: BoxShape.circle,
                           color: Colors.white,
                           boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)]
                         ),
                         child: Container(
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: _isRecording ? UIStyles.dangerRed : UIStyles.primaryBlue,
                           ),
                           child: Center(
                             child: _isRecording 
                               ? Container(height: 24, width: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))
                               : Icon(Icons.circle, color: Colors.white, size: 24) // White rounded center for record look
                           ),
                         ),
                       ),
                     ),

                     // Flip Camera
                     GestureDetector(
                       onTap: _switchCamera,
                       child: Column(
                         children: [
                           Container(
                             padding: EdgeInsets.all(12),
                             decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black45, border: Border.all(color: Colors.white12)),
                             child: Icon(Platform.isIOS ? Icons.flip_camera_ios : Icons.flip_camera_android, color: Colors.white, size: 24),
                           ),
                           SizedBox(height: 4),
                           Text("Flip", style: UIStyles.buttonText) 
                         ],
                       ),
                     ),
                   ],
                 ),
               ),
             ),
          ),
        ],
      ),
    );
  }
}
