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
      final ctrl = CameraController(front, ResolutionPreset.high, enableAudio: false);
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
    final isCourier = app.currentUser?.department.toLowerCase().contains('kurir') ?? false;

    if (!geo.isInRange && !isCourier) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Anda berada di luar jangkauan kantor.'),
          backgroundColor: const Color(0xFFE31E24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          isCourier ? 'Lokasi Kurir (Bypass)' : 'JNE Martapura',
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
              lokasi: isCourier ? 'Lokasi Kurir' : 'JNE Martapura',
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
                  Expanded(
                    child: Text(
                      'VERIFIKASI WAJAH',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2),
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
              padding: const EdgeInsets.only(bottom: 60, top: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                ),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _onShutterTap,
                    child: Container(
                      width: 84, height: 84,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 4),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: _isCapturing 
                          ? const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: Color(0xFF005596), strokeWidth: 4))
                          : const Icon(Icons.camera_alt_rounded, color: Color(0xFF005596), size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'KETUK UNTUK ABSEN',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2),
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
    final isCourier = app.currentUser?.department.toLowerCase().contains('kurir') ?? false;
    final isAllowed = geo.isInRange || isCourier;
    final statusText = isCourier ? 'KURIR AKTIF' : (geo.isInRange ? 'LOKASI SESUAI' : 'DI LUAR RADIUS');
    final color = isAllowed ? Colors.greenAccent : const Color(0xFFE31E24);

    return Positioned(
      top: 110,
      left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 10),
              Text(statusText, style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
            const Icon(Icons.error_outline_rounded, color: Color(0xFFE31E24), size: 64),
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
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2 - 20);
    final radius = size.width * 0.35;
    
    // Draw Face Frame
    canvas.drawCircle(center, radius, paint);
    
    // Corner brackets
    final bracketPaint = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 4.0;
    const bl = 30.0; // bracket length
    
    // TL
    canvas.drawPath(Path()..moveTo(center.dx - radius, center.dy - radius + bl)..lineTo(center.dx - radius, center.dy - radius)..lineTo(center.dx - radius + bl, center.dy - radius), bracketPaint);
    // TR
    canvas.drawPath(Path()..moveTo(center.dx + radius - bl, center.dy - radius)..lineTo(center.dx + radius, center.dy - radius)..lineTo(center.dx + radius, center.dy - radius + bl), bracketPaint);
    // BL
    canvas.drawPath(Path()..moveTo(center.dx - radius, center.dy + radius - bl)..lineTo(center.dx - radius, center.dy + radius)..lineTo(center.dx - radius + bl, center.dy + radius), bracketPaint);
    // BR
    canvas.drawPath(Path()..moveTo(center.dx + radius - bl, center.dy + radius)..lineTo(center.dx + radius, center.dy + radius)..lineTo(center.dx + radius, center.dy + radius - bl), bracketPaint);

    // Scanning Line
    final scanLinePaint = Paint()..color = const Color(0xFF005596).withValues(alpha: 0.8)..strokeWidth = 2.0;
    final lineY = center.dy - radius + (radius * 2 * scanValue);
    canvas.drawLine(Offset(center.dx - radius + 20, lineY), Offset(center.dx + radius - 20, lineY), scanLinePaint);
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) => true;
}