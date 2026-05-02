import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../providers/app_provider.dart';
import '../../utils/connectivity_service.dart';
import '../../utils/geofence_service.dart';
import '../../models/app_models.dart';
import '../option/option_page.dart';
import '../profile/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _timer;
  String _timeUntilWork = '';
  bool _isNearWork = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final p = Provider.of<AppProvider>(context, listen: false);
      
      if (p.hasClockedInToday) {
        setState(() {
          _timeUntilWork = 'Sudah Absen Masuk';
          _isNearWork = false;
        });
        return;
      }

      final start = DateTime(now.year, now.month, now.day, p.officeStartTime.hour, p.officeStartTime.minute);
      
      if (now.isBefore(start)) {
        final diff = start.difference(now);
        setState(() {
          _timeUntilWork = '${diff.inHours}j ${diff.inMinutes % 60}m ${diff.inSeconds % 60}s';
          _isNearWork = diff.inMinutes <= 15;
        });
      } else {
        setState(() {
          _timeUntilWork = 'Terlambat!';
          _isNearWork = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final conn = context.watch<ConnectivityService>();
    final geo = context.watch<GeofenceService>();
    final user = p.currentUser;
    
    final bg = p.isDarkMode ? const Color(0xFF0A1628) : const Color(0xFFF0F4F8);
    final cardBg = p.isDarkMode ? const Color(0xFF0D1F38) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, p, conn),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInDown(duration: const Duration(milliseconds: 500), child: _buildGreeting(user)),
                  const SizedBox(height: 20),
                  FadeInUp(duration: const Duration(milliseconds: 600), child: _buildCountdownCard(cardBg)),
                  const SizedBox(height: 16),
                  if (p.pendingSyncCount > 0)
                    FadeInLeft(child: _buildSyncBanner(p)),
                  const SizedBox(height: 16),
                  FadeInUp(duration: const Duration(milliseconds: 700), child: _buildAttendanceSummary(cardBg, p)),
                  const SizedBox(height: 16),
                  FadeInUp(duration: const Duration(milliseconds: 800), child: _buildHistoryQuickView(cardBg, p)),
                  const SizedBox(height: 16),
                  FadeInUp(duration: const Duration(milliseconds: 900), child: _buildOvertimePreview(cardBg, p)),
                  const SizedBox(height: 16),
                  FadeInUp(duration: const Duration(milliseconds: 1000), child: _buildGeofenceMap(cardBg, geo)),
                  const SizedBox(height: 16),
                  FadeInUp(duration: const Duration(milliseconds: 1100), child: _buildNotificationLog(cardBg, p)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionPage())),
        label: const Text('ABSENSI SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.camera_alt),
        backgroundColor: const Color(0xFFE31E24),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppProvider p, ConnectivityService conn) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0D1F38),
      flexibleSpace: FlexibleSpaceBar(
        title: Text('JNE ATTENDANCE', 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3A6B), Color(0xFF0D1F38)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 40,
              child: _buildConnectionIndicator(conn),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(p.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.white),
          onPressed: () => p.toggleTheme(),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
        ),
      ],
    );
  }

  Widget _buildConnectionIndicator(ConnectivityService conn) {
    IconData icon;
    Color color;
    String label;

    switch (conn.status) {
      case ConnectionStatus.wifi:
        icon = Icons.wifi; color = Colors.greenAccent; label = 'WiFi ✓';
        break;
      case ConnectionStatus.mobile:
        icon = Icons.signal_cellular_alt; color = Colors.orangeAccent; label = 'Data ⚠️';
        break;
      case ConnectionStatus.none:
        icon = Icons.wifi_off; color = Colors.redAccent; label = 'Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGreeting(UserModel? user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selamat Datang,', style: GoogleFonts.outfit(color: Colors.grey, fontSize: 14)),
        Text(user?.name ?? 'Karyawan JNE', 
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCountdownCard(Color bg) {
    final p = context.read<AppProvider>();
    final isDone = p.hasClockedInToday;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDone ? Colors.green : (_isNearWork ? const Color(0xFFE31E24) : bg),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isDone ? '✨ Status Kehadiran' : '⏰ Jam Kantor Countdown', 
                    style: TextStyle(color: (isDone || _isNearWork) ? Colors.white70 : Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_timeUntilWork, 
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              if (isDone)
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 40)
              else if (_isNearWork)
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40),
            ],
          ),
          if (_isNearWork && !isDone) ...[
            const SizedBox(height: 10),
            const Text('🔴 BELUM ABSEN (Terlambat dalam 5 menit!)', 
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ]
        ],
      ),
    );
  }

  Widget _buildSyncBanner(AppProvider p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Ada ${p.pendingSyncCount} data absensi pending (Offline)', 
              style: const TextStyle(color: Colors.white, fontSize: 13)),
          ),
          TextButton(
            onPressed: () => p.syncPendingAttendance(),
            child: const Text('SYNC SEKARANG', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceSummary(Color bg, AppProvider p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅ Last Successful Absensi', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          _rowInfo('Absen Masuk', 'Hari ini 08:15', 'Tepat Waktu', Colors.green),
          const Divider(color: Colors.white10, height: 24),
          _rowInfo('Absen Pulang', 'Kemarin 17:30', 'Selesai', Colors.blue),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String time, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ]),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        )
      ],
    );
  }

  Widget _buildHistoryQuickView(Color bg, AppProvider p) {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('📅 MINGGU INI', style: TextStyle(color: Colors.grey, fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/history'),
                child: const Text('Detail →', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday = i == DateTime.now().weekday - 1;
              Color c = i < 2 ? Colors.green : (i == 2 ? Colors.orange : (i > 3 ? Colors.grey : Colors.blue));
              return Column(
                children: [
                  Text(days[i], style: TextStyle(color: isToday ? Colors.white : Colors.grey, fontSize: 10)),
                  const SizedBox(height: 8),
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: isToday ? Border.all(color: Colors.white) : null,
                    ),
                    child: Icon(i < 4 ? Icons.check : Icons.question_mark, color: c, size: 14),
                  ),
                ],
              );
            }),
          )
        ],
      ),
    );
  }

  Widget _buildOvertimePreview(Color bg, AppProvider p) {
    final ot = p.calculateOvertime();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⏱️ Lembur Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${ot['hours']} jam ${ot['minutes']} menit', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Estimasi: Rp ${NumberFormat.decimalPattern('id').format(ot['pay'])}', 
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildGeofenceMap(Color bg, GeofenceService geo) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(GeofenceService.officeLat, GeofenceService.officeLng),
              zoom: 15,
            ),
            myLocationEnabled: true,
            circles: {
              Circle(
                circleId: const CircleId('office'),
                center: const LatLng(GeofenceService.officeLat, GeofenceService.officeLng),
                radius: GeofenceService.radiusInMeters,
                fillColor: geo.isInRange ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                strokeColor: geo.isInRange ? Colors.green : Colors.red,
                strokeWidth: 2,
              ),
            },
          ),
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Text(geo.isInRange ? '📍 AREA KANTOR ✓' : '⭕ AREA LAIN ⚠️', 
                style: TextStyle(color: geo.isInRange ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
              child: Text('${geo.distanceFromOffice.toInt()}m dari kantor', 
                style: const TextStyle(color: Colors.white, fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationLog(Color bg, AppProvider p) {
    final notifs = p.myNotifications;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📬 NOTIFIKASI TERAKHIR', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          if (notifs.isEmpty)
            const Text('Tidak ada notifikasi', style: TextStyle(color: Colors.grey, fontSize: 12))
          else
            ...notifs.take(3).map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Color(0xFFE31E24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(n['body'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                  ),
                  Text(DateFormat('HH:mm').format(n['time']), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              ),
            )),
          const Divider(color: Colors.white10),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/notifications'),
              child: const Text('Lihat Semua Notifikasi', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}