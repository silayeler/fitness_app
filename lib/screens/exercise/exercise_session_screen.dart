import 'dart:async';
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
  CameraController? _controller;
  bool _isCameraInitialized = false;

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
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    // Permission already granted in previous screen ideally, but check again safely
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      final camera = cameras.first;
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
      // Start countdown immediately after camera checks
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
    _stopwatch.stop();
    _stopwatchTimer?.cancel();
    
    // Save to user stats
    final durationMinutes = _stopwatch.elapsed.inMinutes > 0 ? _stopwatch.elapsed.inMinutes : 1;
    await UserService().addSession(widget.exerciseName, durationMinutes);
    
    if (mounted) {
      context.router.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
     // Full Screen Scaffold
    return Scaffold(
      backgroundColor: Colors.white, // Or whatever background design needs
      // If we want camera background during countdown? Design Screen 3 shows "Squat Hazırlan" on a textured background, NOT camera.
      // But usually user wants to see themselves.
      // The design image "Screen 3" is definitely stylized.
      // Let's stick to the previous plan: Overlay on camera, but maybe with a white overlay if that matches design better?
      // Actually, let's keep Camera visible but with a strong overlay, or if the design implies a transition screen, we can do that.
      // "Screen 3" look: Grey background (texture?), "Squat Hazırlan...", Big "3" in box.
      // Let's implement that exact look for Countdown.
      body: Stack(
        children: [
           // Background: Camera or Solid Color?
           // If we pause camera or show camera?
           // Mobile fitness apps usually show camera during countdown so you can position yourself.
           // But the design shows a solid background. I will support Camera visibility for better UX, but use a high-opacity overlay to match design text contrast.
           if (_isCameraInitialized)
             Positioned.fill(
                child: CameraPreview(_controller!),
             ),
             
          // Overlay
          if (_isCountdown)
            _buildCountdownView()
          else
            _buildRecordingView(),
        ],
      ),
    );
  }

  Widget _buildCountdownView() {
    // Match Screen 3 Design
    return Container(
      color: const Color(0xFFF4F5F7).withValues(alpha: 0.95), // Nearly opaque to match design look
      width: double.infinity,
      child: SafeArea( // Use SafeArea
        child: Column(
          children: [
             // Header: Exercise Name
             // In design: "Squat" (Huge, Light Grey), "Hazırlan..." (Smaller, Darker)
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
                         fontFamily: 'Inter', // If available
                         fontSize: 48,
                         fontWeight: FontWeight.w900,
                         color: Colors.black12, // Very light grey
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
             
             // Countdown Box
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
                   color: Color(0xFFE0E0E0), // Light grey number or similar
                 ),
               ),
             ),
             
             const Spacer(),
             
             // "Kaydı Durdur" / Cancel Button
             Padding(
               padding: const EdgeInsets.all(24),
               child: Column(
                 children: [
                    SizedBox(
                     width: double.infinity,
                     height: 56,
                     child: ElevatedButton(
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFFFF1744),
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(28),
                         ),
                       ),
                       onPressed: () => context.router.maybePop(),
                       child: const Text(
                         'Kaydı Durdur',
                         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                       ),
                     ),
                   ),
                   const SizedBox(height: 12),
                   TextButton(
                     onPressed: () => context.router.maybePop(),
                     child: const Text(
                        'İptal Et',
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 16,
                          fontWeight: FontWeight.w500
                        ),
                     ),
                   )
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    // This is the actual session view (Screen 2 but with "Stop" button?)
    // Or maybe Screen 2 IS the recording view?
    // "Screen 2" has "Kaydı Başlat". So it's Setup.
    // "Recording View" needs to provide feedback.
    
    return Stack(
      children: [
        // Top Bar
        Positioned(
          top: 0, 
          left: 0, 
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Back/Close
                   IconButton(
                     icon: const Icon(Icons.close, color: Colors.white, size: 30),
                     onPressed: () => context.router.maybePop(),
                   ),
                   // Status Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _formattedTime,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 48), // Balance
                ],
              ),
            ),
          ),
        ),
        
        // Bottom Controls
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: Column(
            children: [
               // Feedback Text
               Container(
                 padding: const EdgeInsets.all(16),
                 margin: const EdgeInsets.only(bottom: 24),
                 decoration: BoxDecoration(
                   color: Colors.white.withValues(alpha: 0.9),
                   borderRadius: BorderRadius.circular(16),
                 ),
                 child: const Row(
                   children: [
                     Icon(Icons.check_circle, color: Color(0xFF00C853)),
                     SizedBox(width: 12),
                     Expanded(
                       child: Text(
                         'Formun harika! Böyle devam et.',
                         style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                       ),
                     ),
                   ],
                 ),
               ),
            
               SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.white,
                     foregroundColor: Colors.red,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(28),
                     ),
                   ),
                   onPressed: _finishSession,
                   child: const Text(
                     'Bitir',
                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                   ),
                 ),
               ),
            ],
          ),
        ),
      ],
    );
  }
}
