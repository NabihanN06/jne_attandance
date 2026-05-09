import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';
import '../../widgets/bento_tile.dart';
import 'package:animate_do/animate_do.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color jneOrange = Color(0xFFFF6B00);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color slate400 = Color(0xFF94A3B8);

  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();

    return Scaffold(
      backgroundColor: offWhite,
      body: Stack(
        children: [
          // ── OFFLINE BANNER ──
          if (!conn.isOnline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                color: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Text(
                      'OFFLINE MODE • DATA WILL SYNC LATER',
                      style: GoogleFonts.outfit(
                        color: Colors.white, 
                        fontSize: 10, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 2
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
          // ── PREMIUM HEADER (ZEN STYLE) ──
          Positioned(
            top: 0, left: 0, right: 0,
            height: 280,
            child: Container(
              decoration: const BoxDecoration(
                color: zenNavy,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OPERATIONAL STATUS',
                                style: GoogleFonts.outfit(
                                  color: zenCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.currentUser?.name.toUpperCase() ?? 'COURIER',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          _buildStatusIndicator(p, conn),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // JNE BRANDING BLOCK
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/images/jne.png', height: 20),
                            const SizedBox(width: 16),
                            Container(width: 1, height: 16, color: Colors.white10),
                            const SizedBox(width: 16),
                            Text(
                              'MARTAPURA HUB',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── SCROLLABLE SECTOR ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 180), 
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // 1. PRIMARY TELEMETRY ACTION
                        FadeInDown(
                          duration: const Duration(milliseconds: 700),
                          child: BentoTile(
                            title: p.hasClockedInToday ? 'PULANG OPERASIONAL' : 'MASUK OPERASIONAL',
                            subtitle: p.hasClockedInToday ? 'Akhiri sesi penugasan hari ini' : 'Mulai sinkronisasi kehadiran hari ini',
                            emoji: '⚡',
                            color: p.hasClockedInToday ? Colors.redAccent : zenIndigo,
                            isLarge: true,
                            onTap: () => _handleAttendance(context, p, geo),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 2. OPERATIONAL GRID
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.0,
                          children: [
                            _BentoItem('CUTI / IZIN', 'Sistem pengajuan', '📄', const Color(0xFF6366F1), '/leave'),
                            _BentoItem('OVERTIME', 'Input lembur', '⏳', zenCyan, '/overtime'),
                            _BentoItem('HISTORY', 'Log kehadiran', '🏛️', zenNavy, '/history'),
                            _BentoItem('ANALYTICS', 'Grafik performa', '📈', const Color(0xFFEC4899), '/statistic'),
                          ].asMap().entries.map((entry) {
                            int idx = entry.key;
                            var item = entry.value;
                            return FadeInUp(
                              duration: const Duration(milliseconds: 700),
                              delay: Duration(milliseconds: 100 + (idx * 50)),
                              child: BentoTile(
                                title: item.title,
                                subtitle: item.sub,
                                emoji: item.emoji,
                                color: item.color,
                                isLarge: false,
                                onTap: () => Navigator.pushNamed(context, item.route),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),

                        // 3. SYSTEM FEEDBACK
                        _buildRecentFeedback(p),

                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── EMERGENCY SOS ──
          Positioned(
            bottom: 120,
            right: 32,
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
    
    String statusText = isFortressActive ? p.fortressStatus : (p.hasClockedInToday ? 'CONNECTED' : 'STANDBY');
    Color statusColor = isFortressActive ? jneOrange : (p.hasClockedInToday ? const Color(0xFF10B981) : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: isOnline ? statusColor : slate400,
              shape: BoxShape.circle,
              boxShadow: isOnline ? [BoxShadow(color: statusColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 2)] : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentFeedback(AppProvider p) {
    final latestRequest = p.myLeaveRequests.isNotEmpty ? p.myLeaveRequests.first : null;
    if (latestRequest == null) return const SizedBox.shrink();

    Color statusColor = latestRequest.status == 'approved' ? const Color(0xFF10B981) : 
                        latestRequest.status == 'rejected' ? Colors.redAccent : jneOrange;
    
    return FadeInUp(
      duration: const Duration(milliseconds: 800),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(color: zenNavy.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SISTEM FEEDBACK',
                  style: GoogleFonts.outfit(
                    color: slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: statusColor.withValues(alpha: 0.1)),
                  ),
                  child: Text(
                    latestRequest.status.toUpperCase(),
                    style: GoogleFonts.outfit(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Pengajuan ${latestRequest.type.toUpperCase()} Anda telah ${latestRequest.status == 'approved' ? 'DISETUJUI' : latestRequest.status == 'rejected' ? 'DITOLAK' : 'DIPROSES'} oleh departemen terkait.',
              style: GoogleFonts.plusJakartaSans(
                color: zenNavy,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.6,
                letterSpacing: -0.2,
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
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          color: jneOrange,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: jneOrange.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 12)),
          ],
        ),
        child: const Center(
          child: Icon(Icons.sos_rounded, color: Colors.white, size: 38),
        ),
      ),
    );
  }

  void _handleAttendance(BuildContext context, AppProvider p, GeofenceService geo) {
    if (_isNavigating) return;
    if (geo.isInRange) {
      setState(() => _isNavigating = true);
      Navigator.pushNamed(context, '/attendance', arguments: {'isCheckOut': p.hasClockedInToday})
          .then((_) => setState(() => _isNavigating = false));
    } else {
      _showSimpleError(context, '⚠️ LOKASI DILUAR RADIUS');
    }
  }

  void _showSimpleError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        backgroundColor: zenNavy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  void _showSOSConfirm(BuildContext context, AppProvider p, GeofenceService geo) {
    bool dialogLoading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: jneOrange.withValues(alpha: 0.05), shape: BoxShape.circle),
                child: const Icon(Icons.warning_rounded, color: jneOrange, size: 40),
              ),
              const SizedBox(height: 24),
              Text('SEND SOS SIGNAL?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: zenNavy, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(
                'Sinyal darurat dan lokasi Anda akan segera dipantau oleh Admin Hub.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: slate400, fontSize: 14, fontWeight: FontWeight.w600, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                      child: Text('CANCEL', style: GoogleFonts.outfit(color: slate400, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: dialogLoading ? null : () async {
                        setDialogState(() => dialogLoading = true);
                        try {
                          if (geo.currentPosition != null) {
                            await p.sendSOS(geo.currentPosition!.latitude, geo.currentPosition!.longitude, 'Martapura Hub Area');
                          }
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _showSimpleError(context, '🚨 SOS SIGNAL TRANSMITTED!');
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          setDialogState(() => dialogLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: zenNavy,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: dialogLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text('SEND NOW', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 32),
      height: 80,
      decoration: BoxDecoration(
        color: zenNavy,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: zenNavy.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 15)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.grid_view_rounded, 'HUB', true, () {}),
          _buildNavItem(Icons.message_rounded, 'CHAT', false, () => Navigator.pushNamed(context, '/chat')),
          _buildNavItem(Icons.notifications_rounded, 'ALERT', false, () => Navigator.pushNamed(context, '/notification')),
          _buildNavItem(Icons.person_rounded, 'SELF', false, () => Navigator.pushNamed(context, '/profile')),
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
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? zenCyan : Colors.white24, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: active ? zenCyan : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
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
