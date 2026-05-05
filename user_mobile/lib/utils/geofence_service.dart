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

  Position? get currentPosition => _currentPosition;
  double get distanceFromOffice => _distanceFromOffice;
  bool get isInRange => _isInRange;
  String get errorMessage => _errorMessage;

  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  double get radiusInMeters => _radiusInMeters;

  void updateOfficeConfig(double lat, double lng, double radius) {
    _officeLat = lat;
    _officeLng = lng;
    _radiusInMeters = radius;
    _calculateDistance();
  }

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
