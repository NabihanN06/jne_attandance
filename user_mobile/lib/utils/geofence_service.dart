import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

class GeofenceService extends ChangeNotifier {
  // Office location (Default: JNE Martapura)
  double _officeLat = -3.4150;
  double _officeLng = 114.8465;
  double _radiusInMeters = 500.0;

  Position? _currentPosition;
  double _distanceFromOffice = 0.0;
  bool _isInRange = false;
  String _errorMessage = '';
  bool _isLocating = false;

  Position? get currentPosition => _currentPosition;
  double get distanceFromOffice => _distanceFromOffice;
  bool get isInRange => _isInRange;
  String get errorMessage => _errorMessage;
  bool get isLocationMocked => _currentPosition?.isMocked ?? false;
  bool get isLocating => _isLocating;

  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  double get radiusInMeters => _radiusInMeters;

  /// Terapkan konfigurasi kantor dari admin. Tolak nilai tak masuk akal
  /// (0/luar Indonesia/radius non-positif) supaya typo di panel admin tidak
  /// membuat SEMUA karyawan "di luar radius kantor".
  void updateOfficeConfig(double lat, double lng, double radius) {
    if (_isValidLat(lat) && _isValidLng(lng)) {
      _officeLat = lat;
      _officeLng = lng;
    }
    if (radius.isFinite && radius > 0) {
      _radiusInMeters = radius < 20 ? 20 : radius;
    }
    _calculateDistance();
  }

  static bool _isValidLat(double v) =>
      v.isFinite && v != 0 && v >= -11 && v <= 6;
  static bool _isValidLng(double v) =>
      v.isFinite && v != 0 && v >= 95 && v <= 141;

  GeofenceService() {
    _init();
  }

  Future<void> _init() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = 'Location services are disabled.';
      notifyListeners();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Location permissions are denied.';
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = 'Location permissions are permanently denied.';
      notifyListeners();
      return;
    }

    // Seed satu fix segera. getPositionStream(distanceFilter) tidak menjamin
    // emisi awal saat karyawan diam di meja → tanpa ini _currentPosition bisa
    // null lama ("menunggu GPS") atau memakai fix kasar yang tak pernah
    // diperbarui. Ambil sekali secara eksplisit (akurasi tinggi).
    await refresh();
    _startTracking();
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _calculateDistance();
    });
  }

  /// Ambil satu fix akurasi tinggi secara eksplisit. Dipanggil saat layar
  /// absen dibuka / tepat sebelum verifikasi geofence supaya keputusan pakai
  /// lokasi terbaik, bukan fix kasar (network/cell) yang menyangkut karena
  /// distanceFilter memblok pembaruan selama karyawan diam.
  Future<Position?> refresh() async {
    if (_isLocating) return _currentPosition;
    _isLocating = true;
    notifyListeners();
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _currentPosition = pos;
      _errorMessage = '';
      _calculateDistance();
      return pos;
    } catch (e) {
      // Timeout/izin dicabut di tengah jalan — pertahankan posisi terakhir.
      debugPrint('Geofence refresh failed: $e');
      return _currentPosition;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }

  void _calculateDistance() {
    if (_currentPosition == null) return;

    _distanceFromOffice = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLat,
      _officeLng,
    );
    _isInRange = _distanceFromOffice <= _radiusInMeters;
    notifyListeners();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}
