import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  // JNE Brand Colors
  static const Color jneOrange = Color(0xFFFF6B00);
  static const Color jneNavy = Color(0xFF0D1B2A);
  static const Color jneGrey = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ── FORTRESS OFFLINE BANNER ──
          if (!conn.isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Text(
                    'MODUS OFFLINE - DATA AKAN DISINKRONKAN OTOMATIS',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          // ── PREMIUM TOP HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 240,
            child: Container(
              decoration: const BoxDecoration(
                color: jneNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DASHBOARD KURIR',
                                style: GoogleFonts.outfit(
                                  color: jneOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.currentUser?.name.toUpperCase() ?? 'COURIER',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusIndicator(p, conn),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // JNE LOGO MINI
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/images/jne.png', height: 25),
                          const SizedBox(width: 12),
                          Container(width: 1.5, height: 20, color: Colors.white24),
                          const SizedBox(width: 12),
                          Text(
                            'MARTAPURA HUB',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── MAIN BENTO GRID ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 140), // Gap for header content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // 1. ABSENSI MAIN TILE (📍)
                        FadeInDown(
                          duration: const Duration(milliseconds: 600),
                          child: _buildMainBentoTile(
                            context,
                            p.hasClockedInToday ? 'ABSEN PULANG' : 'ABSEN MASUK',
                            p.hasClockedInToday ? 'Selesai tugas hari ini' : 'Mulai tugas hari ini',
                            '📍',
                            p.hasClockedInToday ? Colors.redAccent : jneOrange,
                            () => _handleAttendance(context, p, geo),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. GRID TILES (LOOPER CONCEPT)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.1,
                          children: [
                            _BentoItem('IZIN', 'Kirim surat izin', '✉️', const Color(0xFF3B82F6), '/leave'),
                            _BentoItem('LEMBUR', 'Ajukan overtime', '💰', const Color(0xFF10B981), '/overtime'),
                            _BentoItem('RIWAYAT', 'Cek absen lalu', '📜', jneNavy, '/history'),
                            _BentoItem('STATS', 'Performa Anda', '📊', const Color(0xFF8B5CF6), '/statistic'),
                          ].asMap().entries.map((entry) {
                            int idx = entry.key;
                            var item = entry.value;
                            return FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: Duration(milliseconds: 200 + (idx * 100)),
                              child: _buildSmallBentoTile(
                                context,
                                item.title,
                                item.sub,
                                item.emoji,
                                item.color,
                                () => Navigator.pushNamed(context, item.route),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // 4. RECENT ADMIN RESPONSE FEEDBACK
                        _buildRecentFeedback(p),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── SOS BUTTON ──
          Positioned(
            bottom: 110,
            right: 24,
            child: _buildSOSButton(p, geo),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
      extendBody: true,
    );
  }

  Widget _buildStatusIndicator(AppProvider p, ConnectivityService conn) {
    bool isOnline = conn.status != ConnectionStatus.none;
    bool isFortressActive = p.fortressStatus.isNotEmpty;
    
    String statusText = isFortressActive ? p.fortressStatus : (p.hasClockedInToday ? 'HADIR' : 'ABSEN');
    Color statusColor = isFortressActive ? Colors.orange : (p.hasClockedInToday ? const Color(0xFF10B981) : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isOnline ? statusColor : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: isOnline ? [BoxShadow(color: statusColor.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)] : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isFortressActive ? statusText.toUpperCase() : 'STATUS: $statusText',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainBentoTile(BuildContext context, String title, String sub, String emoji, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: jneNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub,
                    style: GoogleFonts.outfit(
                      color: jneGrey,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: jneGrey.withValues(alpha: 0.3), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBentoTile(BuildContext context, String title, String sub, String emoji, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 15)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: jneNavy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.outfit(
                color: jneGrey,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFeedback(AppProvider p) {
    // Show the most recent leave or overtime request status
    final latestRequest = p.myLeaveRequests.isNotEmpty ? p.myLeaveRequests.first : null;
    if (latestRequest == null) return const SizedBox.shrink();

    Color statusColor = latestRequest.status == 'approved' ? const Color(0xFF10B981) : 
                        latestRequest.status == 'rejected' ? Colors.redAccent : Colors.orange;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      delay: const Duration(milliseconds: 600),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: jneNavy,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOTIFIKASI TERAKHIR',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    latestRequest.status.toUpperCase(),
                    style: GoogleFonts.outfit(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Pengajuan ${latestRequest.type} Anda telah ${latestRequest.status == 'approved' ? 'DISETUJUI' : latestRequest.status == 'rejected' ? 'DITOLAK' : 'DIPROSES'} oleh Admin.',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(AppProvider p, GeofenceService geo) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.vibrate();
        _showSOSConfirm(context, p, geo);
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: jneOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: jneOrange.withValues(alpha: 0.4), blurRadius: 25, spreadRadius: 2, offset: const Offset(0, 10)),
          ],
        ),
        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 36),
      ),
    );
  }

  void _handleAttendance(BuildContext context, AppProvider p, GeofenceService geo) {
    if (geo.isInRange) {
      Navigator.pushNamed(context, '/attendance', arguments: {'isCheckOut': p.hasClockedInToday});
    } else {
      _showSimpleError(context, '⚠️ Diluar Area JNE Martapura');
    }
  }

  void _showSimpleError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        backgroundColor: jneNavy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context, AppProvider p, GeofenceService geo) {
     showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEB), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 24),
            Text('KIRIM SINYAL SOS?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20, color: jneNavy)),
            const SizedBox(height: 12),
            Text(
              'Lokasi darurat Anda akan dikirimkan ke Admin JNE Martapura sekarang.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: jneGrey, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('BATAL', style: GoogleFonts.outfit(color: jneGrey, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (geo.currentPosition != null) {
                        p.sendSOS(geo.currentPosition!.latitude, geo.currentPosition!.longitude, 'Area JNE Martapura');
                      }
                      Navigator.pop(ctx);
                      _showSimpleError(context, '🚨 SOS TERKIRIM!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jneOrange,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('KIRIM', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 70,
      decoration: BoxDecoration(
        color: jneNavy,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(color: jneNavy.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 'Beranda', true, () {}),
          _buildNavItem(Icons.chat_bubble_rounded, 'Pesan', false, () => Navigator.pushNamed(context, '/chat')),
          _buildNavItem(Icons.notifications_rounded, 'Notif', false, () => Navigator.pushNamed(context, '/notification')),
          _buildNavItem(Icons.person_rounded, 'Profil', false, () => Navigator.pushNamed(context, '/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? jneOrange : Colors.white54, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? jneOrange : Colors.white54,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
class _BentoItem {
  final String title;
  final String sub;
  final String emoji;
  final Color color;
  final String route;
  _BentoItem(this.title, this.sub, this.emoji, this.color, this.route);
}
