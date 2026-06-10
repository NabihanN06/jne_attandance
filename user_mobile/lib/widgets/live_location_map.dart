import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/geofence_service.dart';

/// Lets a parent widget command a [LiveLocationMap] (e.g. recenter button).
class LiveMapController {
  _LiveLocationMapState? _state;

  void _bind(_LiveLocationMapState state) => _state = state;
  void _unbind(_LiveLocationMapState state) {
    if (_state == state) _state = null;
  }

  /// Re-fit the camera to show both the user and the office.
  void recenter() => _state?._recenterFromContext();
}

/// Reusable live geofence map.
///
/// Shows the employee's live position, the office marker and the geofence
/// radius circle. Two modes:
///  - [compact] : lightweight lite-mode preview (a tappable bitmap, used on
///    Home / Attendance). Gestures disabled; tapping fires [onTap].
///  - full      : interactive map (used on the dedicated "Lokasi Saya" screen).
class LiveLocationMap extends StatefulWidget {
  const LiveLocationMap({
    super.key,
    this.compact = false,
    this.height,
    this.borderRadius = 24,
    this.onTap,
    this.showStatusPill = true,
    this.controller,
  });

  final bool compact;
  final double? height;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool showStatusPill;
  final LiveMapController? controller;

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  final Completer<GoogleMapController> _controller = Completer();
  GoogleMapController? _map;
  bool _followedOnce = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._bind(this);
  }

  @override
  void didUpdateWidget(covariant LiveLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._unbind(this);
      widget.controller?._bind(this);
    }
  }

  void _recenterFromContext() {
    if (!mounted) return;
    _recenter(context.read<AppProvider>(), context.read<GeofenceService>());
  }

  // Dark map styling so the map blends with the app's navy theme.
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
  {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
  {"featureType":"landscape.man_made","elementType":"geometry.stroke","stylers":[{"color":"#334e87"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#283d6a"}]},
  {"featureType":"poi.park","elementType":"geometry.fill","stylers":[{"color":"#023e58"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#98a5be"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]}
]
''';

  @override
  void dispose() {
    widget.controller?._unbind(this);
    _map?.dispose();
    super.dispose();
  }

  LatLng _office(AppProvider app) => LatLng(app.officeLat, app.officeLng);

  LatLng? _user(GeofenceService geo) {
    final pos = geo.currentPosition;
    if (pos == null) return null;
    return LatLng(pos.latitude, pos.longitude);
  }

  void _recenter(AppProvider app, GeofenceService geo) {
    if (_map == null) return;
    final user = _user(geo);
    final office = _office(app);
    if (user == null) {
      _map!.animateCamera(CameraUpdate.newLatLngZoom(office, 15.5));
      return;
    }
    final bounds = LatLngBounds(
      southwest: LatLng(
        user.latitude < office.latitude ? user.latitude : office.latitude,
        user.longitude < office.longitude ? user.longitude : office.longitude,
      ),
      northeast: LatLng(
        user.latitude > office.latitude ? user.latitude : office.latitude,
        user.longitude > office.longitude ? user.longitude : office.longitude,
      ),
    );
    _map!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final isDark = app.isDarkMode;

    final office = _office(app);
    final user = _user(geo);

    // Auto-follow the user the first time a fix arrives (full map only).
    if (!widget.compact && user != null && !_followedOnce && _map != null) {
      _followedOnce = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _recenter(app, geo));
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('office'),
        position: office,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(title: app.hubName, snippet: 'Lokasi Kantor'),
      ),
      if (user != null)
        Marker(
          markerId: const MarkerId('user'),
          position: user,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Posisi Anda'),
        ),
    };

    final inRange = geo.isInRange;
    final circleColor = inRange ? const Color(0xFF10B981) : const Color(0xFFF43F5E);

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('geofence'),
        center: office,
        radius: app.officeRadius,
        fillColor: circleColor.withValues(alpha: 0.12),
        strokeColor: circleColor.withValues(alpha: 0.7),
        strokeWidth: 2,
      ),
    };

    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: user ?? office,
        zoom: widget.compact ? 15.5 : 16,
      ),
      onMapCreated: (c) async {
        _map = c;
        if (!_controller.isCompleted) _controller.complete(c);
        if (isDark) {
          // setMapStyle is deprecated in newer SDKs but works on 2.7.x.
          // ignore: deprecated_member_use
          await c.setMapStyle(_darkMapStyle);
        }
      },
      markers: markers,
      circles: circles,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: !widget.compact,
      liteModeEnabled: widget.compact,
      scrollGesturesEnabled: !widget.compact,
      zoomGesturesEnabled: !widget.compact,
      rotateGesturesEnabled: !widget.compact,
      tiltGesturesEnabled: !widget.compact,
      onTap: widget.compact ? (_) => widget.onTap?.call() : null,
    );

    final content = Stack(
      children: [
        Positioned.fill(child: map),
        if (geo.currentPosition == null) _gpsWaitingOverlay(isDark),
        if (widget.showStatusPill)
          Positioned(
            left: 12,
            top: 12,
            child: _statusPill(geo, app),
          ),
        if (widget.compact)
          Positioned(
            right: 12,
            bottom: 12,
            child: _expandHint(),
          ),
      ],
    );

    final rounded = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        height: widget.height ?? (widget.compact ? 160 : double.infinity),
        width: double.infinity,
        child: content,
      ),
    );

    if (widget.compact && widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: rounded,
        ),
      );
    }

    return rounded;
  }

  Widget _gpsWaitingOverlay(bool isDark) {
    return Container(
      color: (isDark ? const Color(0xFF0B1120) : Colors.white).withValues(alpha: 0.6),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
            ),
            const SizedBox(width: 10),
            Text(
              'Mencari sinyal GPS…',
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(GeofenceService geo, AppProvider app) {
    final inRange = geo.isInRange;
    final mocked = geo.isLocationMocked;
    final Color color = mocked
        ? const Color(0xFFF59E0B)
        : (inRange ? const Color(0xFF10B981) : const Color(0xFFF43F5E));
    final String text = mocked
        ? 'Lokasi Palsu'
        : (inRange
            ? 'Dalam Area'
            : '${(geo.distanceFromOffice / 1000).toStringAsFixed(geo.distanceFromOffice < 1000 ? 2 : 1)} km dari kantor');
    final IconData icon = mocked
        ? Icons.gps_off_rounded
        : (inRange ? Icons.verified_rounded : Icons.location_searching_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _expandHint() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 15),
    );
  }
}
