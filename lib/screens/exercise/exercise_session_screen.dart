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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
        children: [
           // 1. Camera Layer
           if (_isCameraInitialized)
             Positioned.fill(
                child: CameraPreview(_controller!),
             ),
             
           // 2. Skeleton Overlay (Removed per user request for future AI integration)
           // if (!_isCountdown)
           //   Positioned.fill(
           //     child: CustomPaint(
           //       painter: SkeletonOverlayPainter(),
           //     ),
           //   ),
             
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
          // Header: AI Coach & Score
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo / Title
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF00C853), size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'AI FORM',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            letterSpacing: 1.2,
                            shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'AKILLI EGZERSIZ KOÇU',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        letterSpacing: 2.0,
                         shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                  ],
                ),
                
                // Live Score Gauge
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00C853), width: 3),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '92',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        'SKOR',
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Analysis Chips (Mock)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AnalysisChip(label: 'OMURGA DİK', isActive: true),
                const SizedBox(width: 8),
                _AnalysisChip(label: 'DİZ AÇISI İYİ', isActive: true),
                const SizedBox(width: 8),
                _AnalysisChip(label: 'DERİNLEŞ!', isActive: false),
              ],
            ),
          ),

          const Spacer(),

          // Center Guides (Visual decoration around user)
          // (Handled by CustomPainter overlay)

          const Spacer(),

          // Bottom Dashboard
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.2),
                   blurRadius: 20,
                   offset: const Offset(0, 10),
                 )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reps and Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TEKRAR',
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: '3',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              TextSpan(
                                text: '/10',
                                style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formattedTime,
                        style: const TextStyle(
                          fontFamily: 'Courier', // Monospace for numbers
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                // Feedback Text
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF00C853)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'FORM MÜKEMMEL',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00C853),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    Text(
                      '585 KCAL',
                      style: TextStyle(
                         color: Colors.black38,
                         fontSize: 12,
                         fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Finish Button
                SizedBox(
                   width: double.infinity,
                   height: 52,
                   child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF00C853),
                       foregroundColor: Colors.white,
                       elevation: 0,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(16),
                       ),
                     ),
                     onPressed: _finishSession,
                     child: const Text(
                       'ANTRENMANI BİTİR',
                       style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                     ),
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

  const _AnalysisChip({required this.label, required this.isActive});

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
            color: isActive ? const Color(0xFF00C853) : Colors.white54,
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
