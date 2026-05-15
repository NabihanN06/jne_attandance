import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../succeed/succeed_page.dart';
import '../../widgets/package_loading.dart';

class EnrollPage extends StatefulWidget {
  const EnrollPage({super.key});

  @override
  State<EnrollPage> createState() => _EnrollPageState();
}

class _EnrollPageState extends State<EnrollPage> with TickerProviderStateMixin {
  static const Color _jneRed = Color(0xFFE31E24);
  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _errorMessage;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  late AnimationController _shutterController;
  late Animation<double> _shutterScale;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;
  late AnimationController _scanController;
  late Animation<double> _scanLine;

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _shutterController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _shutterScale = Tween<double>(begin: 1.0, end: 0.85)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));
    _rippleScale = Tween<double>(begin: 1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));
    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));

    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flashController, curve: Curves.easeIn));

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _scanLine = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanController, curve: Curves.linear));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Kamera tidak terdeteksi.');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = ctrl;
        _isCameraReady = true;
      });
    } on CameraException catch (e) {
      setState(() => _errorMessage = 'Gagal membuka kamera:\n${e.description}');
    } catch (e) {
      setState(() => _errorMessage = 'Kesalahan sistem:\n$e');
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);
    HapticFeedback.heavyImpact();

    await _shutterController.forward();
    await _shutterController.reverse();
    _flashController
        .forward()
        .then((_) => Future.delayed(
              const Duration(milliseconds: 80),
              () => _flashController.reverse(),
            ));

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        if (mounted) {
          final app = context.read<AppProvider>();
          await app.registerFace(photo.path);
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SucceedPage(isEnroll: true)),
              (route) => false,
            );
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _shutterController.dispose();
    _flashController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: Column(
          children: [
            // Camera area
            Expanded(
              child: LayoutBuilder(builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera preview
                    if (_isCameraReady && _cameraController != null)
                      SizedBox.expand(
                        child: CameraPreview(_cameraController!),
                      )
                    else if (_errorMessage != null)
                      _buildError()
                    else
                      Container(
                        color: const Color(0xFF0A0E1A),
                        child: const PackageLoading(
                          message: 'Mempersiapkan kamera...',
                          isLight: true,
                        ),
                      ),

                    // Overlay + oval guide
                    if (_isCameraReady)
                      AnimatedBuilder(
                        animation: Listenable.merge([_pulseAnim, _scanLine]),
                        builder: (_, _) => CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: _FaceScanPainter(
                            w: constraints.maxWidth,
                            h: constraints.maxHeight,
                            pulseScale: _pulseAnim.value,
                            scanProgress: _scanLine.value,
                            isCapturing: _isCapturing,
                          ),
                        ),
                      ),

                    // Flash overlay
                    AnimatedBuilder(
                      animation: _flashOpacity,
                      builder: (_, _) => IgnorePointer(
                        child: Opacity(
                          opacity: _flashOpacity.value,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    ),

                    // Back button + title at top
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(
                                            alpha: 0.15)),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Pendaftaran Wajah',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Instruction text inside oval area
                    if (_isCameraReady)
                      Positioned(
                        bottom: constraints.maxHeight * 0.1,
                        left: 24,
                        right: 24,
                        child: Text(
                          _isCapturing
                              ? 'Memproses...'
                              : 'Posisikan wajah di dalam bingkai',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),

            // Bottom control panel
            Container(
              color: const Color(0xFF0A0E1A),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 48),
              child: Column(
                children: [
                  // Status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCameraReady
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCameraReady ? 'Kamera Siap' : 'Menginisialisasi...',
                        style: GoogleFonts.outfit(
                          color: _isCameraReady
                              ? const Color(0xFF10B981)
                              : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Shutter button
                  GestureDetector(
                    onTap: _onShutterTap,
                    child: AnimatedBuilder(
                      animation: _shutterController,
                      builder: (_, _) => SizedBox(
                        width: 84,
                        height: 84,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple
                            Transform.scale(
                              scale: _rippleScale.value,
                              child: Opacity(
                                opacity: _rippleOpacity.value,
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _jneRed,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Outer ring
                            Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isCameraReady
                                      ? _jneRed
                                      : Colors.white12,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            // Inner button
                            Transform.scale(
                              scale: _shutterScale.value,
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _isCapturing
                                      ? _jneRed
                                      : _isCameraReady
                                          ? _jneRed
                                          : Colors.white12,
                                  boxShadow: _isCameraReady
                                      ? [
                                          BoxShadow(
                                            color: _jneRed
                                                .withValues(alpha: 0.4),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: _isCapturing
                                    ? const Padding(
                                        padding: EdgeInsets.all(18),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Tekan untuk mengambil foto',
                    style: GoogleFonts.outfit(
                      color: Colors.white38,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Container(
        color: const Color(0xFF0A0E1A),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    const Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage ?? 'Kamera bermasalah',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCameraReady = false;
                    _errorMessage = null;
                  });
                  _initCamera();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _jneRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: Text('Coba Lagi',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
}

// ─── FACE SCAN PAINTER ───────────────────────────────────────────────────────
// Oval proporsional, tidak lonjong — width 68%, height 52% dari layar
class _FaceScanPainter extends CustomPainter {
  final double w, h;
  final double pulseScale;
  final double scanProgress;
  final bool isCapturing;

  _FaceScanPainter({
    required this.w,
    required this.h,
    required this.pulseScale,
    required this.scanProgress,
    required this.isCapturing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Oval dimensions - proper face proportions (not elongated)
    final ovalW = w * 0.68 * pulseScale;
    final ovalH = h * 0.52 * pulseScale; // Reduced height ratio
    final centerX = w / 2;
    final centerY = h * 0.44; // Slightly above center
    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: ovalW,
      height: ovalH,
    );

    // Dark overlay outside oval
    final overlayPaint = Paint()
      ..color = const Color(0xFF0A0E1A).withValues(alpha: 0.75);
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, w, h))
        ..addOval(rect)
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Oval border
    final borderColor =
        isCapturing ? const Color(0xFF10B981) : const Color(0xFFE31E24);
    canvas.drawOval(
      rect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Corner accent brackets
    final bracketPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final bl = 22.0; // bracket length

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top + bl), Offset(rect.left, rect.top + 8), bracketPaint);
    canvas.drawLine(Offset(rect.left + 8, rect.top), Offset(rect.left + bl, rect.top), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(rect.right - bl, rect.top), Offset(rect.right - 8, rect.top), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.top + 8), Offset(rect.right, rect.top + bl), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - bl), Offset(rect.left, rect.bottom - 8), bracketPaint);
    canvas.drawLine(Offset(rect.left + 8, rect.bottom), Offset(rect.left + bl, rect.bottom), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(rect.right - bl, rect.bottom), Offset(rect.right - 8, rect.bottom), bracketPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom - bl), Offset(rect.right, rect.bottom - 8), bracketPaint);

    // Scanning line (only when not capturing)
    if (!isCapturing) {
      final scanY = rect.top + (rect.height * scanProgress);
      // Clamp inside oval
      if (scanY > rect.top && scanY < rect.bottom) {
        final halfX = _ovalHalfWidthAt(scanY, rect, ovalW / 2, ovalH / 2);
        final scanPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              Colors.transparent,
              borderColor.withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ).createShader(Rect.fromLTRB(
            centerX - halfX, scanY, centerX + halfX, scanY + 2,
          ))
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(
          Offset(centerX - halfX, scanY),
          Offset(centerX + halfX, scanY),
          scanPaint,
        );
      }
    }
  }

  double _ovalHalfWidthAt(double y, Rect rect, double rx, double ry) {
    final dy = (y - rect.center.dy).abs();
    if (dy >= ry) return 0;
    return rx * (1 - (dy * dy) / (ry * ry)).abs() * 0.5 +
        rx * 0.5; // simplified horizontal extent
  }

  @override
  bool shouldRepaint(covariant _FaceScanPainter old) =>
      old.pulseScale != pulseScale ||
      old.scanProgress != scanProgress ||
      old.isCapturing != isCapturing;
}
