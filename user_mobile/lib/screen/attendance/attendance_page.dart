import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:provider/provider.dart';
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

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
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
      _startFaceDetectionStream();
    } on CameraException catch (e) {
      _handleCameraError(e);
    } catch (e) {
      setState(() => _errorMessage = 'Error: $e');
    }
  }

  void _handleCameraError(CameraException e) {
    if (e.code == 'CameraAccessDenied') {
      setState(() => _errorMessage = 'AKSES KAMERA DITOLAK\n\nSolusi:\n1. Buka Settings > Aplikasi > JNE Attendance\n2. Izinkan akses ke "Kamera"\n3. Kembali ke app ini');
    } else {
      setState(() => _errorMessage = 'Gagal membuka kamera: ${e.description}');
    }
  }

  void _startFaceDetectionStream() {
    // Basic implementation: we'll detect face when user taps shutter for better performance
  }

  Future<void> _onShutterTap() async {
    if (!_isCameraReady || _isCapturing) return;
    
    final geo = Provider.of<GeofenceService>(context, listen: false);
    if (!geo.isInRange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda berada di luar area kantor. Tidak bisa absen.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isCapturing = true);
    HapticFeedback.mediumImpact();

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
          'Tepat Waktu',
          'JNE Martapura',
          isOffline: !conn.isOnline,
          localImagePath: photo.path,
          lat: geo.currentPosition?.latitude ?? 0,
          lng: geo.currentPosition?.longitude ?? 0,
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SucceedPage()),
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
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final geo = context.watch<GeofenceService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Konfirmasi Kehadiran'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isCameraReady && _cameraController != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AspectRatio(
                      aspectRatio: 1 / _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildError()
                else
                  const CircularProgressIndicator(),
                
                _buildOverlay(),
                
                Positioned(
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        Icon(geo.isInRange ? Icons.location_on : Icons.location_off, 
                          color: geo.isInRange ? Colors.green : Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(geo.isInRange ? 'Dalam Jangkauan' : 'Luar Jangkauan', 
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomControl(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      width: 250,
      height: 350,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 2),
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }

  Widget _buildBottomControl() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _onShutterTap,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE31E24), width: 4),
              ),
              child: _isCapturing 
                ? const CircularProgressIndicator(color: Color(0xFFE31E24))
                : const Icon(Icons.camera_alt, color: Color(0xFFE31E24), size: 32),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Ketuk untuk Ambil Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Text('Pastikan wajah terlihat jelas dalam bingkai', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 24),
          if (_errorMessage!.contains('AKSES'))
            ElevatedButton(
              onPressed: () => Provider.of<GeofenceService>(context, listen: false).openAppSettings(),
              child: const Text('BUKA SETTINGS'),
            ),
        ],
      ),
    );
  }
}