import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color zenRose = Color(0xFFF43F5E);

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
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = 'Kamera tidak terdeteksi');
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
      _handleCameraError(e);
    } catch (e) {
      setState(() => _errorMessage = 'Terjadi kesalahan: $e');
    }
  }

  void _handleCameraError(CameraException e) {
    if (e.code == 'CameraAccessDenied') {
      setState(() => _errorMessage = 'Akses kamera ditolak\n\nAktifkan izin kamera di pengaturan ponsel Anda.');
    } else {
      setState(() => _errorMessage = 'Gagal memulai kamera: ${e.description}');
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
       _showFeedback('Lokasi palsu terdeteksi • absensi ditolak', zenRose);
       return;
     }

    if (!geo.isInRange && !isRemoteAllowed) {
      HapticFeedback.vibrate();
      _showFeedback('Di luar radius kantor (${(geo.distanceFromOffice/1000).toStringAsFixed(1)} km)', zenRose);
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _showFeedback('Wajah tidak terdeteksi • coba lagi', zenRose);
      } else {
        if (!mounted) return;
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final bool isCheckOut = args?['isCheckOut'] ?? false;

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
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SucceedPage(
              jenis: isCheckOut ? 'Absen Keluar' : 'Absen Masuk',
              waktu: '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} WITA',
              status: isCheckOut ? 'Selesai ✓' : (app.isLateForClockIn ? 'Terlambat ⚠' : 'Tepat Waktu ✓'),
              lokasi: isRemoteAllowed ? 'Lokasi Luar Kantor' : app.hubName,
            )),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      _showFeedback('Gagal menyimpan absensi: $e', zenRose);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showFeedback(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geo = context.watch<GeofenceService>();
    final app = context.watch<AppProvider>();
    final isProcessing = app.isProcessing || _isCapturing;

    return Scaffold(
      backgroundColor: zenNavy,
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildOverlay(geo, app),
          if (isProcessing) _buildLoadingOverlay(),
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
                    style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
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

  Widget _buildLoadingOverlay() {
    return Container(
      color: zenNavy.withValues(alpha: 0.85),
      child: const PackageLoading(
        message: 'Menyimpan absensi...',
        isLight: true,
      ),
    );
  }

  Widget _buildOverlay(GeofenceService geo, AppProvider app) {
    return Stack(
      children: [
        _buildScannerOverlay(),
          
          // ── APP BAR ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [zenNavy.withValues(alpha: 0.9), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Verifikasi Wajah',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          app.hubName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: zenCyan, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),
          
          // ── STATUS TAG ──
          _buildStatusInfo(geo, app),
          
          // ── BOTTOM SHUTTER AREA ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 40, 32, 60),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [zenNavy.withValues(alpha: 0.95), zenNavy.withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                   if (_isCameraReady)
                   GestureDetector(
                     onTap: (_isCapturing || app.isProcessing) ? null : _onShutterTap,
                     child: AnimatedOpacity(
                       duration: const Duration(milliseconds: 400),
                       opacity: (_isCapturing || app.isProcessing) ? 0.3 : 1.0,
                      child: Container(
                        width: 96, height: 96,
                        padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: zenIndigo,
                          boxShadow: [
                            BoxShadow(
                              color: zenIndigo.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: _isCapturing 
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                          : const Icon(Icons.fingerprint_rounded, color: Colors.white, size: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 14),
                      const SizedBox(width: 12),
                      Text(
                        _isCapturing ? 'Memproses...' : 'Posisikan wajah di dalam bingkai',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusInfo(GeofenceService geo, AppProvider app) {
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final isAllowed = geo.isInRange || isRemoteAllowed;
    
    String statusText = '';
    IconData icon = Icons.gps_fixed_rounded;
    Color color = isAllowed ? zenCyan : zenRose;

    if (isRemoteAllowed) {
      statusText = 'Absensi Luar Kantor Aktif';
      icon = Icons.satellite_alt_rounded;
    } else if (geo.isInRange) {
      statusText = '${app.hubName} • Dalam Area';
      icon = Icons.location_on_rounded;
    } else {
      statusText = 'Di Luar Area • ${(geo.distanceFromOffice/1000).toStringAsFixed(1)} km';
      icon = Icons.warning_amber_rounded;
    }

    return Positioned(
      top: 140,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: zenNavy.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
                )
              ),
            ],
          ),
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
    
    // Background Darkening
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(
      backgroundPath,
      Paint()..color = const Color(0xFF121826).withValues(alpha: 0.8),
    );

    // Frame Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF4F46E5).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 30.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius, glowPaint);

    // Main Circle Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Corner brackets (Zen Style)
    final bracketPaint = Paint()
      ..color = const Color(0xFF4F46E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    const bl = 45.0; // bracket length
    
    // TL
    canvas.drawPath(Path()..moveTo(center.dx - radius, center.dy - radius + bl)..lineTo(center.dx - radius, center.dy - radius)..lineTo(center.dx - radius + bl, center.dy - radius), bracketPaint);
    // TR
    canvas.drawPath(Path()..moveTo(center.dx + radius - bl, center.dy - radius)..lineTo(center.dx + radius, center.dy - radius)..lineTo(center.dx + radius, center.dy - radius + bl), bracketPaint);
    // BL
    canvas.drawPath(Path()..moveTo(center.dx - radius, center.dy + radius - bl)..lineTo(center.dx - radius, center.dy + radius)..lineTo(center.dx - radius + bl, center.dy + radius), bracketPaint);
    // BR
    canvas.drawPath(Path()..moveTo(center.dx + radius - bl, center.dy + radius)..lineTo(center.dx + radius, center.dy + radius)..lineTo(center.dx + radius, center.dy + radius - bl), bracketPaint);

    // Scanning Line with Gradient Glow
    final lineY = center.dy - radius + (radius * 2 * scanValue);
    
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF4F46E5).withValues(alpha: 0),
          const Color(0xFF4F46E5).withValues(alpha: 0.9),
          const Color(0xFF4F46E5).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(center.dx - radius, lineY - 15, center.dx + radius, lineY + 15))
      ..strokeWidth = 4.0;

    canvas.drawLine(Offset(center.dx - radius + 10, lineY), Offset(center.dx + radius - 10, lineY), scanLinePaint);
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) => true;
}