import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../utils/connectivity_service.dart';
import '../../utils/geofence_service.dart';
import '../succeed/succeed_page.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  String? _errorMessage;
  final FaceDetector _faceDetector = FaceDetector(options: FaceDetectorOptions(enableContours: true, enableClassification: true));
  
  late AnimationController _scanAnimController;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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
      final ctrl = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) return;
      setState(() { _cameraController = ctrl; _isCameraReady = true; });
    } on CameraException catch (e) {
      _handleCameraError(e);
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  void _handleCameraError(CameraException e) {
    if (e.code == 'CameraAccessDenied') {
      setState(() => _errorMessage = 'AKSES KAMERA DITOLAK\n\nSilakan aktifkan izin kamera di pengaturan sistem.');
    } else {
      setState(() => _errorMessage = 'Gagal membuka kamera: ${e.description}');
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;
    
    final geo = Provider.of<GeofenceService>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final double distance = geo.distanceFromOffice;

    if (!geo.isInRange && !isRemoteAllowed) {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Anda berada di luar jangkauan Hub (${(distance/1000).toStringAsFixed(1)} km). Silakan mendekat ke kantor.'),
          backgroundColor: const Color(0xFFF43F5E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.heavyImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wajah tidak terdeteksi. Silakan coba lagi.'), backgroundColor: Colors.orange),
          );
        }
      } else {
        if (!mounted) return;
        final p = Provider.of<AppProvider>(context, listen: false);
        final conn = Provider.of<ConnectivityService>(context, listen: false);
        
        await p.addAttendanceCheckIn(
          p.currentUser!.uid,
          p.currentUser!.name,
          p.isLateForClockIn ? 'Terlambat' : 'Tepat Waktu',
          isRemoteAllowed ? 'Lokasi Luar (Remote Mode)' : 'JNE Martapura',
          isOffline: !conn.isOnline,
          localImagePath: photo.path,
          lat: geo.currentPosition?.latitude ?? 0,
          lng: geo.currentPosition?.longitude ?? 0,
        );

        if (mounted) {
          final now = DateTime.now();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => SucceedPage(
              jenis: 'Absen Masuk',
              waktu: '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} WITA',
              status: p.isLateForClockIn ? 'Terlambat ⚠' : 'Tepat Waktu ✓',
              lokasi: isRemoteAllowed ? 'Lokasi Luar' : 'JNE Martapura',
            )),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      debugPrint('Attendance Error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
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
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraReady && _cameraController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize!.height,
                  height: _cameraController!.value.previewSize!.width,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            )
          else if (_errorMessage != null)
            _buildError()
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          
          // Custom Overlay
          _buildScannerOverlay(),
          
          // App Bar Area
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Image.asset('assets/images/jne_logo.png', height: 16),
                  const SizedBox(width: 12),
                  Container(width: 1, height: 14, color: Colors.white24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'VERIFIKASI WAJAH',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          
          // Status Tag
          _buildStatusInfo(geo, app),
          
          // Shutter Button Area
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 50, top: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  if (_isCameraReady)
                  GestureDetector(
                    onTap: _onShutterTap,
                    child: Container(
                      width: 88, height: 88,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0891B2).withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: _isCapturing 
                          ? const CircularProgressIndicator(color: Color(0xFF0891B2), strokeWidth: 4)
                          : Icon(Icons.face_unlock_rounded, color: const Color(0xFF0891B2).withValues(alpha: 0.8), size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isCapturing ? 'MEMPROSES VERIFIKASI...' : 'POSISIKAN WAJAH DI DALAM AREA',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(GeofenceService geo, AppProvider app) {
    final isRemoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final isAllowed = geo.isInRange || isRemoteAllowed;
    
    String statusText = '';
    IconData icon = Icons.location_on_rounded;
    Color color = isAllowed ? const Color(0xFF0891B2) : const Color(0xFFF43F5E);

    if (isRemoteAllowed) {
      statusText = 'MODE TUGAS LUAR AKTIF 🛰️';
      icon = Icons.satellite_alt_rounded;
    } else if (geo.isInRange) {
      statusText = 'AREA HUB MARTAPURA ✓';
      icon = Icons.check_circle_rounded;
    } else {
      statusText = 'LUAR AREA HUB (${(geo.distanceFromOffice/1000).toStringAsFixed(1)} KM) 🔒';
      icon = Icons.lock_clock_rounded;
    }

    return Positioned(
      top: 110,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 10),
              Text(
                statusText, 
                style: GoogleFonts.outfit(
                  color: Colors.white, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1,
                  shadows: [Shadow(color: color, blurRadius: 8)],
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFF43F5E), size: 64),
            const SizedBox(height: 20),
            Text(_errorMessage!, textAlign: TextAlign.center, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
    
    // Background Darkening (Overlay)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(
      backgroundPath,
      Paint()..color = Colors.black.withValues(alpha: 0.6),
    );

    // Frame Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF0891B2).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius, glowPaint);

    // Main Circle Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);
    
    // Corner brackets
    final bracketPaint = Paint()
      ..color = const Color(0xFF0891B2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    const bl = 40.0; // bracket length
    const gap = 0.0; // gap from circle
    
    // TL
    canvas.drawPath(Path()..moveTo(center.dx - radius - gap, center.dy - radius - gap + bl)..lineTo(center.dx - radius - gap, center.dy - radius - gap)..lineTo(center.dx - radius - gap + bl, center.dy - radius - gap), bracketPaint);
    // TR
    canvas.drawPath(Path()..moveTo(center.dx + radius + gap - bl, center.dy - radius - gap)..lineTo(center.dx + radius + gap, center.dy - radius - gap)..lineTo(center.dx + radius + gap, center.dy - radius - gap + bl), bracketPaint);
    // BL
    canvas.drawPath(Path()..moveTo(center.dx - radius - gap, center.dy + radius + gap - bl)..lineTo(center.dx - radius - gap, center.dy + radius + gap)..lineTo(center.dx - radius - gap + bl, center.dy + radius + gap), bracketPaint);
    // BR
    canvas.drawPath(Path()..moveTo(center.dx + radius + gap - bl, center.dy + radius + gap)..lineTo(center.dx + radius + gap, center.dy + radius + gap)..lineTo(center.dx + radius + gap, center.dy + radius + gap - bl), bracketPaint);

    // Scanning Line with Gradient Glow
    final lineY = center.dy - radius + (radius * 2 * scanValue);
    
    final scanLinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0891B2).withValues(alpha: 0),
          const Color(0xFF0891B2).withValues(alpha: 0.8),
          const Color(0xFF0891B2).withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTRB(center.dx - radius, lineY - 10, center.dx + radius, lineY + 10))
      ..strokeWidth = 3.0;

    canvas.drawLine(Offset(center.dx - radius + 15, lineY), Offset(center.dx + radius - 15, lineY), scanLinePaint);

    // Dynamic scanning particles / dots could be added here for extra "tech" feel
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) => true;
}