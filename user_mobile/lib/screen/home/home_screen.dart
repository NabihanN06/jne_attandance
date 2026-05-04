import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:ui';
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
  String _timeUntilWork = '00:00:00';
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
          _timeUntilWork = 'COMPLETED';
          _isNearWork = false;
        });
        return;
      }

      final start = DateTime(now.year, now.month, now.day, p.officeStartTime.hour, p.officeStartTime.minute);
      
      if (now.isBefore(start)) {
        final diff = start.difference(now);
        setState(() {
          _timeUntilWork = '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
          _isNearWork = diff.inMinutes <= 15;
        });
      } else {
        setState(() {
          _timeUntilWork = 'LATE';
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
    
    const Color jneRed = Color(0xFFE31E24);
    const Color bgDark = Color(0xFF020617);
    const Color surfaceCard = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // ── Background Blobs (Premium Depth) ──
          Positioned(
            top: -50, right: -100,
            child: _BlurredBlob(color: jneRed.withValues(alpha: 0.15), size: 300),
          ),
          Positioned(
            bottom: 100, left: -50,
            child: _BlurredBlob(color: const Color(0xFF005596).withValues(alpha: 0.15), size: 250),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildModernAppBar(context, conn),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: _buildWelcomeHeader(user),
                      ),
                      const SizedBox(height: 32),
                      
                      FadeInUp(
                        duration: const Duration(milliseconds: 700),
                        child: _buildMainStatusCard(p, jneRed),
                      ),
                      const SizedBox(height: 24),

                      if (p.pendingSyncCount > 0)
                        FadeInLeft(child: _buildSyncBanner(p)),
                      
                      _buildSectionTitle('METRIK PERFORMA'),
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        child: _buildBentoGrid(p, surfaceCard),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('GEOLOKASI HUB'),
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 900),
                        child: _buildMapSection(geo, p, surfaceCard),
                      ),
                      
                      const SizedBox(height: 32),
                      _buildSectionTitle('LOG AKTIVITAS'),
                      const SizedBox(height: 16),
                      FadeInUp(
                        duration: const Duration(milliseconds: 1000),
                        child: _buildActivityTimeline(p, surfaceCard),
                      ),
                      
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: _buildActionButton(context, p, jneRed),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernAppBar(BuildContext context, ConnectivityService conn) {
    return SliverAppBar(
      expandedHeight: 0,
      toolbarHeight: 70,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: const Color(0xFF020617).withValues(alpha: 0.7),
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
            ),
            child: const Icon(Icons.local_shipping, color: Color(0xFFE31E24), size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'JNE HUB',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        _buildConnBadge(conn),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildConnBadge(ConnectivityService conn) {
    Color color = Colors.greenAccent;
    IconData icon = Icons.wifi_rounded;
    if (conn.status == ConnectionStatus.none) {
      color = Colors.redAccent;
      icon = Icons.wifi_off_rounded;
    } else if (conn.status == ConnectionStatus.mobile) {
      color = Colors.amberAccent;
      icon = Icons.signal_cellular_alt_rounded;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 6),
            Text(
              conn.status.name.toUpperCase(),
              style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Bekerja,',
              style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Text(
              user?.name ?? 'Karyawan JNE',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE31E24).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE31E24).withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              const Text('UNIT', style: TextStyle(color: Color(0xFFE31E24), fontSize: 8, fontWeight: FontWeight.w900)),
              Text(
                user?.department.toUpperCase() ?? '-',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatusCard(AppProvider p, Color accent) {
    bool isDone = p.hasClockedInToday;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDone ? Colors.green.withValues(alpha: 0.1) : (accent.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.3) : accent.withValues(alpha: 0.3)),
        image: DecorationImage(
          image: const AssetImage('assets/images/noise.png'),
          opacity: 0.05,
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDone ? 'Sesi Selesai' : 'Waktu Menuju Shift',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeUntilWork,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              _GlowingIcon(
                icon: isDone ? Icons.check_circle_rounded : Icons.timer_outlined,
                color: isDone ? Colors.green : accent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDone 
                      ? 'Absensi Anda telah tercatat hari ini. Terima kasih!'
                      : (_isNearWork ? 'Segera lakukan absensi di area kantor.' : 'Pastikan GPS aktif sebelum melakukan absensi.'),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(AppProvider p, Color cardBg) {
    final ot = p.calculateOvertime();
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _BentoItem(
          label: 'KEPATUHAN',
          value: '98%',
          sub: 'Bulan ini',
          icon: Icons.verified_user_rounded,
          color: const Color(0xFF10B981),
          bg: cardBg,
        ),
        _BentoItem(
          label: 'TOTAL LEMBUR',
          value: '${ot['hours']}j',
          sub: '${ot['minutes']}m',
          icon: Icons.history_toggle_off_rounded,
          color: Colors.blueAccent,
          bg: cardBg,
        ),
        _BentoItem(
          label: 'SHIFT AKTIF',
          value: '08:00',
          sub: 'WIB',
          icon: Icons.wb_sunny_rounded,
          color: Colors.orangeAccent,
          bg: cardBg,
        ),
        _BentoItem(
          label: 'ESTIMASI',
          value: 'Rp ${NumberFormat.compact().format(ot['pay'])}',
          sub: 'Bonus lembur',
          icon: Icons.payments_rounded,
          color: Colors.purpleAccent,
          bg: cardBg,
        ),
      ],
    );
  }

  Widget _buildMapSection(GeofenceService geo, AppProvider p, Color cardBg) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(GeofenceService.officeLat, GeofenceService.officeLng),
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            circles: {
              Circle(
                circleId: const CircleId('office'),
                center: const LatLng(GeofenceService.officeLat, GeofenceService.officeLng),
                radius: GeofenceService.radiusInMeters,
                fillColor: (geo.isInRange ? Colors.green : Colors.red).withValues(alpha: 0.15),
                strokeColor: geo.isInRange ? Colors.green : Colors.red,
                strokeWidth: 2,
              ),
            },
          ),
          Positioned(
            top: 16, left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: Colors.black.withValues(alpha: 0.5),
                  child: Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: geo.isInRange ? Colors.green : Colors.red,
                          boxShadow: [BoxShadow(color: (geo.isInRange ? Colors.green : Colors.red).withValues(alpha: 0.5), blurRadius: 4)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        geo.isInRange ? 'LOKASI SESUAI' : 'DI LUAR AREA',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(AppProvider p, Color cardBg) {
    final notifs = p.myNotifications;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: notifs.isEmpty
          ? const Center(child: Text('Belum ada aktivitas', style: TextStyle(color: Colors.grey, fontSize: 12)))
          : Column(
              children: [
                ...notifs.take(3).map((n) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE31E24),
                          boxShadow: [BoxShadow(color: const Color(0xFFE31E24).withValues(alpha: 0.3), blurRadius: 6)],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(n['body'], style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                          ],
                        ),
                      ),
                      Text(DateFormat('HH:mm').format(n['time']), style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                )),
                const Divider(color: Colors.white10, height: 32),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/notifications'),
                  child: const Text('LIHAT SEMUA LOG', style: TextStyle(color: Color(0xFFE31E24), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButton(BuildContext context, AppProvider p, Color accent) {
    return ZoomIn(
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 48),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionPage())),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'ABSENSI SEKARANG',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
    );
  }

  Widget _buildSyncBanner(AppProvider p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.sync_problem_rounded, color: Colors.orange, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text('${p.pendingSyncCount} data pending', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () => p.syncPendingAttendance(),
            child: const Text('SYNC', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurredBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4)],
      ),
    );
  }
}

class _GlowingIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _GlowingIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }
}

class _BentoItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final IconData icon;
  final Color color;
  final Color bg;
  const _BentoItem({required this.label, required this.value, required this.sub, required this.icon, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          Text(sub, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}