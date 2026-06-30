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

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shutterScale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeOut),
    );
    _rippleScale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _shutterController, curve: Curves.easeOut),
    );

    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _flashOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _flashController, curve: Curves.easeIn));

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
      final ctrl = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() {
        _cameraController = ctrl;
        _isCameraReady = true;
      });
    } on CameraException catch (e) {
      setState(() => _errorMessage = 'Gagal Membuka Kamera:\n${e.description}');
    } catch (e) {
      setState(() => _errorMessage = 'Kesalahan Sistem:\n$e');
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);
    HapticFeedback.heavyImpact();

    await _shutterController.forward();
    await _shutterController.reverse();

    _flashController.forward().then((_) {
      Future.delayed(
        const Duration(milliseconds: 80),
        () => _flashController.reverse(),
      );
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        debugPrint('📸 Enroll foto: ${photo.path}');

        if (mounted) {
          final app = context.read<AppProvider>();
          await app.registerFace(photo.path);

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => const SucceedPage(isEnroll: true),
              ),
              (route) => false,
            );
          }
        }
      }
    } on CameraException catch (e) {
      debugPrint('Capture Gagal: ${e.description}');
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _pulseController.dispose();
    _shutterController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cyanAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Daftar Wajah',
          style: GoogleFonts.inter(
            color: const Color(0xFF0F172A),
            letterSpacing: 0.2,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isCameraReady && _cameraController != null)
                      SizedBox.expand(child: CameraPreview(_cameraController!))
                    else if (_errorMessage != null)
                      _buildError()
                    else
                      _buildLoading(cyanAccent),

                    if (_isCameraReady)
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, _) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: CustomPaint(
                            size: Size(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            ),
                            painter: _OvalPainter(
                              w: constraints.maxWidth,
                              h: constraints.maxHeight,
                              color: cyanAccent,
                            ),
                          ),
                        ),
                      ),

                    AnimatedBuilder(
                      animation: _flashOpacity,
                      builder: (_, _) => Opacity(
                        opacity: _flashOpacity.value,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            padding: EdgeInsets.only(
              top: 30,
              bottom: MediaQuery.of(context).padding.bottom + 28,
              left: 24,
              right: 24,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onShutterTap,
                  child: AnimatedBuilder(
                    animation: _shutterController,
                    builder: (_, _) => SizedBox(
                      width: 90,
                      height: 90,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.scale(
                            scale: _rippleScale.value,
                            child: Opacity(
                              opacity: _rippleOpacity.value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: cyanAccent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Transform.scale(
                            scale: _shutterScale.value,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: _isCapturing
                                    ? cyanAccent.withValues(alpha: 0.2)
                                    : cyanAccent.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isCameraReady
                                      ? cyanAccent
                                      : const Color(0xFFCBD5E1),
                                  width: 3,
                                ),
                                boxShadow: _isCameraReady
                                    ? [
                                        BoxShadow(
                                          color: cyanAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: _isCapturing
                                  ? Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: CircularProgressIndicator(
                                        color: cyanAccent,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Icon(
                                      Icons.face_retouching_natural_rounded,
                                      color: _isCameraReady
                                          ? cyanAccent
                                          : const Color(0xFFCBD5E1),
                                      size: 32,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'KETUK UNTUK AMBIL FOTO',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posisikan wajah tepat di tengah bingkai, pastikan terang & jelas',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 11,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(Color accent) => Container(
    color: const Color(0xFFF8FAFC),
    child: const PackageLoading(
      message: 'Mempersiapkan kamera...',
      isLight: false,
    ),
  );

  Widget _buildError() => Container(
    color: const Color(0xFFF8FAFC),
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            color: Color(0xFFCBD5E1),
            size: 64,
          ),
          const SizedBox(height: 24),
          Text(
            _errorMessage ?? 'Kamera Bermasalah',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
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
            child: const Text('RE-INITIALIZE'),
          ),
        ],
      ),
    ),
  );
}

class _OvalPainter extends CustomPainter {
  final double w, h;
  final Color color;
  _OvalPainter({required this.w, required this.h, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalW = w * 0.72;
    final ovalH = h * 0.78;
    final center = Offset(w / 2, h * 0.45);
    final rect = Rect.fromCenter(center: center, width: ovalW, height: ovalH);

    // Light/white overlay — bikin frame terang & bersih (bukan gelap)
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, w, h))
        ..addOval(rect)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = const Color(0xFFF8FAFC).withValues(alpha: 0.92),
    );

    // Oval Border
    canvas.drawOval(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Focus Indicators
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Top
    canvas.drawLine(
      Offset(rect.center.dx - 15, rect.top),
      Offset(rect.center.dx + 15, rect.top),
      p,
    );
    // Bottom
    canvas.drawLine(
      Offset(rect.center.dx - 15, rect.bottom),
      Offset(rect.center.dx + 15, rect.bottom),
      p,
    );
    // Left
    canvas.drawLine(
      Offset(rect.left, rect.center.dy - 15),
      Offset(rect.left, rect.center.dy + 15),
      p,
    );
    // Right
    canvas.drawLine(
      Offset(rect.right, rect.center.dy - 15),
      Offset(rect.right, rect.center.dy + 15),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) =>
      old.w != w || old.h != h || old.color != color;
}
