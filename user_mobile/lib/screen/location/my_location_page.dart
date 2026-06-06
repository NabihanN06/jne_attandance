import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../../widgets/live_location_map.dart';

/// Full-screen live location screen — shows where the employee is relative to
/// the office geofence ("arena"), distance, and verification status.
class MyLocationPage extends StatefulWidget {
  const MyLocationPage({super.key});

  @override
  State<MyLocationPage> createState() => _MyLocationPageState();
}

class _MyLocationPageState extends State<MyLocationPage> {
  final LiveMapController _mapController = LiveMapController();

  static const Color zenNavy = Color(0xFF0B1120);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenGreen = Color(0xFF10B981);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenAmber = Color(0xFFF59E0B);

  String _fmtDistance(double meters) {
    if (meters <= 0) return '—';
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final remoteAllowed = app.currentUser?.allowRemoteAttendance ?? false;
    final pos = geo.currentPosition;

    return Scaffold(
      backgroundColor: zenNavy,
      body: Stack(
        children: [
          // ── Full interactive map ──
          Positioned.fill(
            child: LiveLocationMap(
              compact: false,
              borderRadius: 0,
              showStatusPill: false,
              controller: _mapController,
            ),
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [zenNavy.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  _circleButton(Icons.chevron_left_rounded, () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi Saya',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          app.hubName,
                          style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF22D3EE),
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Recenter FAB ──
          Positioned(
            right: 20,
            bottom: 280,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _mapController.recenter();
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.my_location_rounded, color: zenIndigo, size: 24),
              ),
            ),
          ),

          // ── Bottom info card ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _infoCard(geo, app, remoteAllowed, pos),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(GeofenceService geo, AppProvider app, bool remoteAllowed, dynamic pos) {
    final inRange = geo.isInRange;
    final mocked = geo.isLocationMocked;

    Color statusColor;
    IconData statusIcon;
    String statusTitle;
    String statusSub;

    if (mocked) {
      statusColor = zenAmber;
      statusIcon = Icons.gps_off_rounded;
      statusTitle = 'Lokasi Palsu Terdeteksi';
      statusSub = 'Nonaktifkan aplikasi lokasi palsu (fake GPS) untuk bisa absen.';
    } else if (inRange) {
      statusColor = zenGreen;
      statusIcon = Icons.verified_rounded;
      statusTitle = 'Anda di Dalam Area Kantor';
      statusSub = 'Posisi terverifikasi. Anda bisa melakukan absensi.';
    } else if (remoteAllowed) {
      statusColor = const Color(0xFF22D3EE);
      statusIcon = Icons.satellite_alt_rounded;
      statusTitle = 'Absensi Luar Kantor Aktif';
      statusSub = 'Anda diizinkan absen dari luar radius kantor.';
    } else {
      statusColor = zenRose;
      statusIcon = Icons.location_searching_rounded;
      statusTitle = 'Anda di Luar Area Kantor';
      statusSub = 'Mendekatlah ke kantor hingga masuk radius untuk absen.';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 36),
      decoration: BoxDecoration(
        color: const Color(0xFF15203A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, -10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusTitle,
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(statusSub,
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _metric('Jarak ke Kantor', _fmtDistance(geo.distanceFromOffice),
                  Icons.straighten_rounded),
              const SizedBox(width: 12),
              _metric('Radius Area', _fmtDistance(app.officeRadius),
                  Icons.adjust_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.place_rounded, color: Colors.white38, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pos != null
                        ? '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}'
                        : 'Menunggu sinyal GPS…',
                    style: GoogleFonts.robotoMono(
                        color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                if (geo.errorMessage.isEmpty && pos != null)
                  const Icon(Icons.gps_fixed_rounded, color: zenGreen, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF22D3EE), size: 18),
            const SizedBox(height: 10),
            Text(value,
                style: GoogleFonts.outfit(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
