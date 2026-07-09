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
import '../../widgets/live_location_map.dart';
import '../../utils/app_strings.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  // Status negatif (gagal scan, luar area, GPS palsu) WAJIB merah brand JNE.
  static const Color zenRed = Color(0xFFE31E24);

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
  bool _scanError =
      false; // true sebentar saat gagal (no face / luar area / GPS palsu)
  int _faceAttempts =
      0; // hitung gagal deteksi wajah (batas dari admin: maxFaceAttempts)

  void _flashError() {
    if (!mounted) return;
    setState(() => _scanError = true);
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _scanError = false);
    });
  }

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
    final camNotDetected = context.tr('camera_not_detected');
    final errPrefix = context.tr('error_occurred');
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _errorMessage = camNotDetected);
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
      setState(() {
        _cameraController = ctrl;
        _isCameraReady = true;
      });
    } on CameraException catch (e) {
      _handleCameraError(e);
    } catch (e) {
      setState(() => _errorMessage = '$errPrefix: $e');
    }
  }

  void _handleCameraError(CameraException e) {
    if (e.code == 'CameraAccessDenied') {
      setState(() => _errorMessage = context.tr('camera_denied'));
    } else {
      setState(
        () => _errorMessage =
            '${context.tr('camera_start_failed')}: ${e.description}',
      );
    }
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;

    final geo = Provider.of<GeofenceService>(context, listen: false);
    final app = Provider.of<AppProvider>(context, listen: false);
    final isRemoteAllowed = app.canBypassGeofence;

    // Ambil fix akurasi tinggi terbaru dulu kalau belum ada posisi atau posisi
    // saat ini bilang di luar radius — sering kali itu fix kasar (network/cell)
    // yang menyangkut karena distanceFilter. Refresh mencegah penolakan palsu.
    if (geo.currentPosition == null || !geo.isInRange) {
      _showFeedback(context.tr('waiting_gps'), zenNavy);
      await geo.refresh();
      if (!mounted) return;
    }

    if (geo.currentPosition == null) {
      _showFeedback(context.tr('waiting_gps'), zenNavy);
      return;
    }

    if (geo.isLocationMocked) {
      _flashError();
      _showFeedback(context.tr('mock_location_rejected'), zenRed);
      return;
    }

    if (!geo.isInRange && !isRemoteAllowed) {
      HapticFeedback.vibrate();
      _flashError();
      _showFeedback(
        '${context.tr('out_of_radius_office')} (${(geo.distanceFromOffice / 1000).toStringAsFixed(1)} km)',
        zenRed,
      );
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

    // Ambil teks terjemahan sebelum await (hindari pakai context lintas async gap).
    final faceFailPre = context.tr('face_detect_failed');
    final timesTryLater = context.tr('times_try_later');
    final faceNotDetectedPre = context.tr('face_not_detected_pre');
    final attemptsWord = context.tr('attempts_word');
    final alreadyCheckedIn = context.tr('already_checked_in');
    final noCheckinYet = context.tr('no_checkin_yet');
    final connIssue = context.tr('connection_issue');
    final saveFailed = context.tr('save_attendance_failed');
    final checkInLabel = context.tr('check_in_label');
    final checkOutLabel = context.tr('check_out_label');
    final doneCheck = context.tr('done_check');
    final lateCheck = context.tr('late_check');
    final ontimeCheck = context.tr('ontime_check');
    final outsideOfficeLoc = context.tr('outside_office_loc');

    try {
      final XFile photo = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(photo.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        _faceAttempts++;
        _flashError();
        if (_faceAttempts >= app.maxFaceAttempts) {
          _showFeedback('$faceFailPre $_faceAttempts $timesTryLater', zenRed);
          await Future.delayed(const Duration(milliseconds: 1300));
          if (mounted) Navigator.pop(context);
          return;
        }
        final sisa = app.maxFaceAttempts - _faceAttempts;
        _showFeedback('$faceNotDetectedPre $sisa $attemptsWord', zenRed);
      } else {
        _faceAttempts = 0; // reset saat berhasil
        if (!mounted) return;
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
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
            MaterialPageRoute(
              builder: (_) => SucceedPage(
                jenis: isCheckOut ? checkOutLabel : checkInLabel,
                waktu:
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WITA',
                status: isCheckOut
                    ? doneCheck
                    : (app.isLateForClockIn ? lateCheck : ontimeCheck),
                lokasi: isRemoteAllowed ? outsideOfficeLoc : app.hubName,
              ),
            ),
            (route) => route.isFirst,
          );
        }
      }
    } catch (e) {
      _flashError();
      final clean = e.toString().replaceFirst('Exception: ', '').trim();
      final lower = clean.toLowerCase();
      final msg = clean.contains('sudah melakukan absensi')
          ? alreadyCheckedIn
          : clean.contains('tidak ditemukan')
          ? noCheckinYet
          : lower.contains('network') || lower.contains('unavailable')
          ? connIssue
          // Alasan lain diteruskan apa adanya (mis. "periksa koneksi internet",
          // "offline dinonaktifkan admin") — jangan tutupi dgn pesan generik.
          : (clean.isEmpty ? saveFailed : clean);
      _showFeedback(msg, zenRed);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _showFeedback(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
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
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
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
      child: PackageLoading(
        message: context.tr('saving_attendance'),
        isLight: true,
      ),
    );
  }

  Widget _buildOverlay(GeofenceService geo, AppProvider app) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final remoteAllowed = app.canBypassGeofence;
    final geoOk = geo.isInRange || remoteAllowed;
    // Merah saat: baru gagal scan, GPS palsu, atau di luar area (setelah GPS dapat).
    final frameColor =
        (_scanError ||
            geo.isLocationMocked ||
            (!geoOk && geo.currentPosition != null))
        ? zenRed
        : zenIndigo;
    return Stack(
      children: [
        _buildScannerOverlay(frameColor),

        // ── APP BAR ──
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 32),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        context.tr('face_verification'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        app.hubName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: zenCyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
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

        // ── LIVE MINI MAP (glance where you are vs office) ──
        Positioned(
          top: topInset + 150,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 90,
                child: LiveLocationMap(
                  compact: true,
                  height: 90,
                  borderRadius: 18,
                  showStatusPill: false,
                  onTap: () => Navigator.pushNamed(context, '/lokasi'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('tap_for_map'),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // ── BOTTOM SHUTTER AREA ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(32, 40, 32, bottomInset + 28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  zenNavy.withValues(alpha: 0.95),
                  zenNavy.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              children: [
                if (_isCameraReady)
                  GestureDetector(
                    onTap: (_isCapturing || app.isProcessing)
                        ? null
                        : _onShutterTap,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: (_isCapturing || app.isProcessing) ? 0.3 : 1.0,
                      child: Container(
                        width: 96,
                        height: 96,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: frameColor,
                          ),
                          child: _isCapturing
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                )
                              : Icon(
                                  _scanError
                                      ? Icons.error_outline_rounded
                                      : Icons.fingerprint_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isCapturing
                            ? context.tr('processing')
                            : context.tr('position_face'),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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
    final topInset = MediaQuery.of(context).padding.top;
    final isRemoteAllowed = app.canBypassGeofence;
    final isAllowed = geo.isInRange || isRemoteAllowed;

    String statusText = '';
    IconData icon = Icons.gps_fixed_rounded;
    Color color = isAllowed ? zenCyan : zenRed;

    if (isRemoteAllowed) {
      statusText = context.tr('remote_attendance_active');
      icon = Icons.satellite_alt_rounded;
    } else if (geo.isInRange) {
      statusText = '${app.hubName} • ${context.tr('in_area')}';
      icon = Icons.location_on_rounded;
    } else {
      statusText =
          '${context.tr('out_of_area_label')} • ${(geo.distanceFromOffice / 1000).toStringAsFixed(1)} km';
      icon = Icons.warning_amber_rounded;
    }

    return Positioned(
      top: topInset + 96,
      left: 0,
      right: 0,
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
                  shadows: [
                    Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScannerOverlay(Color color) {
    return AnimatedBuilder(
      animation: _scanAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: ScannerPainter(_scanAnimController.value, color),
          child: Container(),
        );
      },
    );
  }
}

class ScannerPainter extends CustomPainter {
  final double scanValue;
  final Color color;
  ScannerPainter(this.scanValue, [this.color = const Color(0xFF4F46E5)]);

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

    // Main Circle Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    // Corner brackets (Zen Style)
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    const bl = 45.0; // bracket length

    // TL
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius, center.dy - radius + bl)
        ..lineTo(center.dx - radius, center.dy - radius)
        ..lineTo(center.dx - radius + bl, center.dy - radius),
      bracketPaint,
    );
    // TR
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - bl, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy - radius + bl),
      bracketPaint,
    );
    // BL
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - radius, center.dy + radius - bl)
        ..lineTo(center.dx - radius, center.dy + radius)
        ..lineTo(center.dx - radius + bl, center.dy + radius),
      bracketPaint,
    );
    // BR
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + radius - bl, center.dy + radius)
        ..lineTo(center.dx + radius, center.dy + radius)
        ..lineTo(center.dx + radius, center.dy + radius - bl),
      bracketPaint,
    );

    // Scanning Line with Gradient Glow
    final lineY = center.dy - radius + (radius * 2 * scanValue);

    final scanLinePaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              color.withValues(alpha: 0),
              color.withValues(alpha: 0.9),
              color.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromLTRB(
              center.dx - radius,
              lineY - 15,
              center.dx + radius,
              lineY + 15,
            ),
          )
      ..strokeWidth = 4.0;

    canvas.drawLine(
      Offset(center.dx - radius + 10, lineY),
      Offset(center.dx + radius - 10, lineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(ScannerPainter oldDelegate) => true;
}
