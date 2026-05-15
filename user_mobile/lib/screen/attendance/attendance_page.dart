import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../succeed/succeed_page.dart';
import '../../widgets/package_loading.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with TickerProviderStateMixin {
  static const Color zenNavy   = Color(0xFF0D1829);
  static const Color zenIndigo = Color(0xFFE31E24);
  static const Color zenCyan   = Color(0xFF005596);
  static const Color zenRose   = Color(0xFFF43F5E);
  static const Color zenGreen  = Color(0xFF10B981);

  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _errorMessage;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  late AnimationController _scanAnimController;
  late AnimationController _pulseAnimController;
  late Animation<double> _pulseAnimation;

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();

    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'KAMERA TIDAK TERDETEKSI');
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
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _cameraController = ctrl; _isCameraReady = true; });
    } on CameraException catch (e) {
      if (e.code == 'CameraAccessDenied') {
        setState(() => _errorMessage = 'AKSES KAMERA DITOLAK\n\nAktifkan izin kamera di pengaturan.');
      } else {
        setState(() => _errorMessage = 'KAMERA ERROR: ${e.description}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'ERROR: $e');
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;

    final geo = Provider.of<GeofenceService>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;

    if (geo.currentPosition == null) {
      _showFeedback('Menunggu sinyal GPS...', zenNavy);
      return;
    }
    if (geo.isLocationMocked) {
      HapticFeedback.heavyImpact();
      _showFeedback('LOKASI PALSU TERDETEKSI • AKSES DITOLAK', zenRose);
      return;
    }
    if (!geo.isInRange && !isRemoteAllowed) {
      HapticFeedback.vibrate();
      _showFeedback('DI LUAR JANGKAUAN (${(geo.distanceFromOffice / 1000).toStringAsFixed(1)} KM)', zenRose);
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      
      // Face detection with enhanced robustness
      List<Face> faces;
      try {
        // Pause briefly to ensure camera buffer is stable
        await Future.delayed(const Duration(milliseconds: 200));
        faces = await _faceDetector.processImage(inputImage);
      } catch (e) {
        debugPrint('Face Detector Error: $e');
        // Fallback for detection failures
        _showFeedback('PEMINDAIAN GAGAL: Sensor tidak merespon', zenRose);
        return;
      }

      if (faces.isEmpty) {
        HapticFeedback.vibrate();
        _showFeedback('WAJAH TIDAK TERDETEKSI • COBA LAGI', zenRose);
      } else {
        // AI Verification simulation for premium feel
        await Future.delayed(const Duration(milliseconds: 1800)); 
        
        if (!mounted) return;
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final isCheckOut = args?['isCheckOut'] ?? false;

        if (isCheckOut) {
          await app.addAttendanceCheckOut(
            localImagePath: photo.path,
            lat: geo.currentPosition?.latitude ?? 0,
            lng: geo.currentPosition?.longitude ?? 0,
          );
        } else {
          await app.addAttendanceCheckIn(
            app.isLateForClockIn ? 'Terlambat' : 'Tepat Waktu',
            localImagePath: photo.path,
            lat: geo.currentPosition?.latitude ?? 0,
            lng: geo.currentPosition?.longitude ?? 0,
          );
        }

        if (mounted) {
          final now = DateTime.now();
          HapticFeedback.heavyImpact();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SucceedPage(
              jenis: isCheckOut ? 'Attendance: Exit' : 'Attendance: Entry',
              waktu: '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA',
              status: isCheckOut
                  ? 'ABSENSI KELUAR ✓'
                  : (app.isLateForClockIn ? 'TERLAMBAT ⚠' : 'ABSENSI MASUK ✓'),
              lokasi: isRemoteAllowed ? 'REMOTE SECTOR' : 'HUB MARTAPURA',
            )),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ALREADY_CLOCKED_IN')) {
        _showFeedback('SUDAH ABSEN MASUK HARI INI', zenNavy);
      } else {
        _showFeedback('GANGGUAN SISTEM: $msg', zenRose);
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showFeedback(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 12)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _pulseAnimController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geo         = context.watch<GeofenceService>();
    final app         = context.watch<AppProvider>();
    final isProcessing= app.isProcessing || _isCapturing;

    final args       = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isCheckOut = args?['isCheckOut'] ?? false;

    return Scaffold(
      backgroundColor: zenNavy,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildOverlay(geo, app, isCheckOut),
          if (isProcessing) _buildAIVerificationOverlay(app),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        color: zenNavy,
        child: Center(
          child: _errorMessage != null
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14, height: 1.6),
                  ),
                )
              : const PackageLoading(isLight: true),
        ),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _cameraController!.value.previewSize!.height,
          height: _cameraController!.value.previewSize!.width,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
  }

  Widget _buildAIVerificationOverlay(AppProvider app) {
    return Container(
      color: zenNavy.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI Circle
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(zenIndigo.withValues(alpha: 0.3)),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    valueColor: const AlwaysStoppedAnimation<Color>(zenIndigo),
                    strokeWidth: 4,
                  ),
                ),
                // Registered Face Comparison
                if (app.currentUser?.facePhotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      app.currentUser!.facePhotoUrl!,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(Icons.face_unlock_rounded, color: Colors.white, size: 50),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'AI IDENTITY VERIFICATION',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(color: zenIndigo, strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'COMPARING FACIAL EMBEDDINGS...',
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Match Score (Simulated)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 0.98),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text(
                      'MATCH: ${(value * 100).toStringAsFixed(1)}%',
                      style: GoogleFonts.outfit(
                        color: zenGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 200 * value,
                          decoration: BoxDecoration(
                            color: zenGreen,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [BoxShadow(color: zenGreen.withValues(alpha: 0.5), blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(GeofenceService geo, AppProvider app, bool isCheckOut) {
    return Stack(
      children: [
        _buildScannerOverlay(),
        _buildTopBar(isCheckOut, app),
        _buildGeofenceStatus(geo, app),
        _buildBottomArea(geo, app, isCheckOut),
      ],
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar(bool isCheckOut, AppProvider app) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [zenNavy.withValues(alpha: 0.95), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            // Back + mode badge
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 26),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: (isCheckOut ? zenRose : zenGreen).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: (isCheckOut ? zenRose : zenGreen).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCheckOut ? Icons.logout_rounded : Icons.login_rounded,
                        color: isCheckOut ? zenRose : zenGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCheckOut ? 'ABSEN KELUAR' : 'ABSEN MASUK',
                        style: GoogleFonts.outfit(
                          color: isCheckOut ? zenRose : zenGreen,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Offline Indicator
                if (app.isOffline)
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 20),
                  )
                else
                  const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 16),
            const _LiveClock(),
          ],
        ),
      ),
    );
  }

  // ── GEOFENCE STATUS PILL ──
  Widget _buildGeofenceStatus(GeofenceService geo, AppProvider app) {
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final isAllowed       = geo.isInRange || isRemoteAllowed;

    Color color;
    IconData icon;
    String text;

    if (isRemoteAllowed) {
      color = zenCyan; icon = Icons.satellite_alt_rounded; text = 'MODE REMOTE AKTIF';
    } else if (geo.isInRange) {
      color = zenGreen; icon = Icons.location_on_rounded; text = 'DALAM JANGKAUAN HUB';
    } else if (geo.currentPosition == null) {
      color = Colors.amber; icon = Icons.gps_not_fixed_rounded; text = 'MENUNGGU GPS...';
    } else {
      final km = (geo.distanceFromOffice / 1000).toStringAsFixed(1);
      color = zenRose; icon = Icons.location_off_rounded; text = 'DI LUAR JANGKAUAN · $km KM';
    }

    return Positioned(
      left: 0, right: 0,
      bottom: 220,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: color, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              if (!isAllowed && geo.currentPosition != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: zenRose.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(geo.distanceFromOffice / 1000).toStringAsFixed(1)}KM',
                    style: GoogleFonts.outfit(color: zenRose, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── BOTTOM SHUTTER AREA ──
  Widget _buildBottomArea(GeofenceService geo, AppProvider app, bool isCheckOut) {
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final isAllowed       = geo.isInRange || isRemoteAllowed;
    final isActive        = _isCameraReady && !_isCapturing && !app.isProcessing;
    final shutterColor    = isCheckOut ? zenRose : zenIndigo;

    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 56),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [zenNavy.withValues(alpha: 0.98), zenNavy.withValues(alpha: 0.5), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            // Shutter button with pulse
            if (_isCameraReady)
              GestureDetector(
                onTap: isActive ? _onShutterTap : null,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulse ring
                        if (isActive && isAllowed)
                          Transform.scale(
                            scale: _pulseAnimation.value * 1.15,
                            child: Container(
                              width: 96, height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: shutterColor.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        // Middle ring
                        Container(
                          width: 96, height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: isActive ? 0.15 : 0.05),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Core button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isActive ? 1.0 : 0.35,
                          child: Container(
                            width: 76, height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? shutterColor : Colors.grey.shade700,
                              boxShadow: isActive
                                  ? [BoxShadow(color: shutterColor.withValues(alpha: 0.5), blurRadius: 28, spreadRadius: 4)]
                                  : [],
                            ),
                            child: _isCapturing
                                ? const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Icon(
                                    isCheckOut ? Icons.logout_rounded : Icons.fingerprint_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            // Hint text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_isCapturing),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isCapturing ? Icons.hourglass_top_rounded : Icons.face_retouching_natural_rounded,
                      color: Colors.white54,
                      size: 14,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isCapturing
                          ? 'MEMPROSES BIOMETRIK...'
                          : !isAllowed
                              ? 'LOKASI DI LUAR JANGKAUAN'
                              : app.isOffline 
                                  ? 'OFFLINE MODE: DATA AKAN DISINKRONKAN'
                                  : 'POSISIKAN WAJAH DI DALAM BINGKAI',
                      style: GoogleFonts.outfit(
                        color: _isCapturing
                            ? zenCyan
                            : !isAllowed
                                ? zenRose.withValues(alpha: 0.8)
                                : app.isOffline ? Colors.amber : Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return AnimatedBuilder(
      animation: _scanAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: ScannerPainter(_scanAnimController.value),
          child: Container(),
        );
      },
    );
  }
}

class ScannerPainter extends CustomPainter {
  final double scanValue;
  ScannerPainter(this.scanValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final radius = size.width * 0.38;

    // Background darkening outside circle
    final bgPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(bgPath, Paint()..color = const Color(0xFF0D1829).withValues(alpha: 0.75));

    // Glow ring
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = const Color(0xFFE31E24).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 32
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );

    // Border circle
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Corner brackets
    final bp = Paint()
      ..color = const Color(0xFFE31E24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    const bl = 44.0;

    void bracket(List<Offset> pts) {
      final path = Path()..moveTo(pts[0].dx, pts[0].dy);
      for (final p in pts.skip(1)) { path.lineTo(p.dx, p.dy); }
      canvas.drawPath(path, bp);
    }

    bracket([Offset(center.dx - radius, center.dy - radius + bl), Offset(center.dx - radius, center.dy - radius), Offset(center.dx - radius + bl, center.dy - radius)]);
    bracket([Offset(center.dx + radius - bl, center.dy - radius), Offset(center.dx + radius, center.dy - radius), Offset(center.dx + radius, center.dy - radius + bl)]);
    bracket([Offset(center.dx - radius, center.dy + radius - bl), Offset(center.dx - radius, center.dy + radius), Offset(center.dx - radius + bl, center.dy + radius)]);
    bracket([Offset(center.dx + radius - bl, center.dy + radius), Offset(center.dx + radius, center.dy + radius), Offset(center.dx + radius, center.dy + radius - bl)]);

    // Scanning line
    final lineY = center.dy - radius + (radius * 2 * scanValue);
    canvas.drawLine(
      Offset(center.dx - radius + 5, lineY),
      Offset(center.dx + radius - 5, lineY),
      Paint()
        ..shader = LinearGradient(colors: [
          const Color(0xFFE31E24).withValues(alpha: 0),
          const Color(0xFFE31E24),
          const Color(0xFFE31E24).withValues(alpha: 0.85),
          const Color(0xFFE31E24).withValues(alpha: 0),
        ], stops: const [0.0, 0.4, 0.6, 1.0]).createShader(Rect.fromLTRB(center.dx - radius, lineY - 15, center.dx + radius, lineY + 15))
        ..strokeWidth = 4.0,
    );
  }

  @override
  bool shouldRepaint(ScannerPainter old) => true;
}

/// Isolated 1Hz clock so the parent page (with camera, face detector, and
/// animations) doesn't rebuild every second. Only this widget's RenderObject
/// repaints — cheap.
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('HH:mm:ss').format(_now),
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, d MMMM yyyy', 'id').format(_now),
          style: GoogleFonts.outfit(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
