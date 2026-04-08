import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../succeed/succeed_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
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

    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.98, end: 1.02)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _shutterController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _shutterScale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));
    _rippleScale = Tween<double>(begin: 1.0, end: 2.2)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));
    _rippleOpacity = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _shutterController, curve: Curves.easeOut));

    _flashController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _flashController, curve: Curves.easeIn));

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Tidak ada kamera tersedia.');
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(front, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _cameraController = ctrl; _isCameraReady = true; });
    } on CameraException catch (e) {
      setState(() => _errorMessage = 'Gagal:\n${e.description}');
    } catch (e) {
      setState(() => _errorMessage = 'Error:\n$e');
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;
    setState(() => _isCapturing = true);

    HapticFeedback.mediumImpact();

    await _shutterController.forward();
    await _shutterController.reverse();

    _flashController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 80), () => _flashController.reverse());
    });

    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        debugPrint('📸 Absensi foto: ${photo.path}');

        if (mounted) {
          // Navigasi ke succeed page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SucceedPage()),
            (route) => route.isFirst,
          );
        }
      }
    } on CameraException catch (e) {
      debugPrint('Gagal: ${e.description}');
    } finally {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Isi Absen'),
      ),
      body: Column(
        children: [
          // Camera area
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
                      _buildLoading(),

                    if (_isCameraReady)
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseAnim.value,
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _OvalPainter(
                              w: constraints.maxWidth,
                              h: constraints.maxHeight,
                            ),
                          ),
                        ),
                      ),

                    // Flash
                    AnimatedBuilder(
                      animation: _flashOpacity,
                      builder: (_, __) => Opacity(
                        opacity: _flashOpacity.value,
                        child: Container(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom
          Container(
            color: const Color(0xFF0A1628),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: _onShutterTap,
                  child: AnimatedBuilder(
                    animation: _shutterController,
                    builder: (_, __) => SizedBox(
                      width: 80, height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple
                          Transform.scale(
                            scale: _rippleScale.value,
                            child: Opacity(
                              opacity: _rippleOpacity.value,
                              child: Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),
                          // Button
                          Transform.scale(
                            scale: _shutterScale.value,
                            child: Container(
                              width: 64, height: 64,
                              decoration: BoxDecoration(
                                color: _isCapturing
                                    ? const Color(0xFF1A3A5C)
                                    : const Color(0xFF0D1F38),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isCameraReady ? Colors.white70 : const Color(0xFF263E5E),
                                  width: 2.5,
                                ),
                                boxShadow: _isCameraReady
                                    ? [BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 12, spreadRadius: 2)]
                                    : null,
                              ),
                              child: _isCapturing
                                  ? const Padding(
                                      padding: EdgeInsets.all(18),
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.camera_alt_outlined,
                                      color: _isCameraReady ? Colors.white : Colors.white24,
                                      size: 28,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Posisikan Wajah Anda',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Pastikan wajah anda dalam bingkai oval',
                    style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() => Container(
        color: const Color(0xFF0D1525),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Color(0xFFE31E24), strokeWidth: 2),
            SizedBox(height: 16),
            Text('Membuka kamera...', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
          ]),
        ),
      );

  Widget _buildError() => Container(
        color: const Color(0xFF0D1525),
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_outlined, color: Color(0xFF90A4AE), size: 56),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Kamera tidak tersedia',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xF90A4AE), fontSize: 13, height: 1.6)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() { _isCameraReady = false; _errorMessage = null; });
                _initCamera();
              },
              child: const Text('Coba Lagi'),
            ),
          ]),
        ),
      );
}

class _OvalPainter extends CustomPainter {
  final double w, h;
  _OvalPainter({required this.w, required this.h});

  @override
  void paint(Canvas canvas, Size size) {
    final ovalW = w * 0.72;
    final ovalH = h * 0.78;
    final center = Offset(w / 2, h * 0.47);
    final rect = Rect.fromCenter(center: center, width: ovalW, height: ovalH);

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, w, h))
        ..addOval(rect)
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    canvas.drawOval(rect,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5);

    // Tick marks
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const len = 20.0;
    canvas.drawLine(Offset(rect.center.dx, rect.top - 1), Offset(rect.center.dx, rect.top + len), p);
    canvas.drawLine(Offset(rect.center.dx, rect.bottom + 1), Offset(rect.center.dx, rect.bottom - len), p);
    canvas.drawLine(Offset(rect.left - 1, rect.center.dy), Offset(rect.left + len, rect.center.dy), p);
    canvas.drawLine(Offset(rect.right + 1, rect.center.dy), Offset(rect.right - len, rect.center.dy), p);
  }

  @override
  bool shouldRepaint(covariant _OvalPainter old) => old.w != w || old.h != h;
}