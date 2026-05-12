import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';
import '../notifications/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primary     = Color(0xFF081F3F); // Deep Blue
  static const Color primaryDark = Color(0xFF06152A);
  static const Color bgLight     = Color(0xFFF1F5F9);
  static const Color textDark    = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);

  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final p    = context.watch<AppProvider>();
    final geo  = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();

    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Selamat Pagi' : hour < 17 ? 'Selamat Siang' : 'Selamat Sore';
    final name = p.currentUser?.name.split(' ').first ?? 'Karyawan';

    return Scaffold(
      backgroundColor: bgLight,
      extendBody: true,
      body: Stack(
        children: [
          // ── OFFLINE BANNER ──
          if (!conn.isOnline)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                bottom: false,
                child: Container(
                  color: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Mode Offline · Data akan disinkronkan',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Column(
            children: [
              // ── BLUE HEADER ──
              _buildHeader(context, p, geo, conn, greeting, name),

              // ── BODY (STATIC) ──
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(), // Static as requested
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ATTENDANCE CARD
                      _buildAttendanceCard(context, p, geo),
                      const SizedBox(height: 24),

                      // MENU GRID TITLE
                      Text(
                        'Menu Utama',
                        style: GoogleFonts.plusJakartaSans(
                          color: textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // MENU GRID
                      _buildMenuGrid(context),
                      const SizedBox(height: 24),

                      // LATEST REQUEST STATUS
                      _buildLatestStatus(p),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── SOS BUTTON ──
          Positioned(
            bottom: 110,
            right: 20,
            child: _buildSOSButton(p, geo),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ──────────────────────────────────────────
  // HEADER
  // ──────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    AppProvider p,
    GeofenceService geo,
    ConnectivityService conn,
    String greeting,
    String name,
  ) {
    final isOnline = conn.status != ConnectionStatus.none;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primary, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNotificationBell(context, p),
                      const SizedBox(width: 12),
                      _buildConnBadge(conn),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // ATTENDANCE CARD
  // ──────────────────────────────────────────
  Widget _buildAttendanceCard(BuildContext context, AppProvider p, GeofenceService geo) {
    final hasClockedIn = p.hasClockedInToday;
    final isInRange    = geo.isInRange;
    final isRemote     = p.currentUser?.allowRemoteAttendance ?? false;
    final canAbsen     = isInRange || isRemote;
    final role         = (p.currentUser?.role ?? '').toLowerCase();
    final isKurir      = role == 'kurir' || role == 'driver';

    // Label & subtitle differ by role
    final String title;
    final String subtitle;
    if (isKurir) {
      title    = hasClockedIn ? 'Selesai Tugas' : 'Mulai Tugas';
      subtitle = hasClockedIn
          ? 'Absen keluar setelah paket terkirim'
          : canAbsen ? 'Siap untuk memulai pengiriman' : 'Di luar radius area kantor';
    } else {
      title    = hasClockedIn ? 'Check Out' : 'Check In';
      subtitle = hasClockedIn
          ? 'Tekan untuk mengakhiri sesi kerja'
          : canAbsen ? 'Anda berada di area kantor ✓' : 'Di luar radius area kantor';
    }

    final accentColor = hasClockedIn ? primary : const Color(0xFF16A34A);
    final bgColor     = hasClockedIn ? const Color(0xFFFFF5F5) : const Color(0xFFF0FDF4);
    final iconBg      = hasClockedIn ? const Color(0xFFFFE4E4) : const Color(0xFFDCFCE7);

    return GestureDetector(
      onTap: () => _handleAttendance(context, p, geo),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.07), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
              child: Icon(
                hasClockedIn
                    ? (isKurir ? Icons.check_circle_rounded : Icons.logout_rounded)
                    : (isKurir ? Icons.delivery_dining_rounded : Icons.fingerprint_rounded),
                color: accentColor, size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(color: textDark, fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      if (isKurir) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF005596).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Kurir',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF005596), fontSize: 9, fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: canAbsen || hasClockedIn ? accentColor : textMuted,
                      fontSize: 12, fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // MENU GRID
  // ──────────────────────────────────────────
  Widget _buildMenuGrid(BuildContext context) {
    final items = [
      _MenuItem('Izin / Cuti',  Icons.event_note_rounded,         const Color(0xFFE31E24), const Color(0xFFFFF5F5), '/leave'),
      _MenuItem('Lembur',       Icons.access_time_filled_rounded,  const Color(0xFFF59E0B), const Color(0xFFFFFBEB), '/overtime'),
      _MenuItem('Riwayat',      Icons.history_rounded,             const Color(0xFF10B981), const Color(0xFFECFDF5), '/history'),
      _MenuItem('Statistik',    Icons.bar_chart_rounded,           const Color(0xFF005596), const Color(0xFFEFF6FF), '/statistic'),
      _MenuItem('Kalender',     Icons.calendar_month_rounded,      const Color(0xFF0EA5E9), const Color(0xFFF0F9FF), '/calendar'),
      _MenuItem('Chat',         Icons.chat_bubble_rounded,         const Color(0xFF8B5CF6), const Color(0xFFF5F3FF), '/chat'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, item.route);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────
  // LATEST STATUS
  // ──────────────────────────────────────────
  Widget _buildLatestStatus(AppProvider p) {
    final req = p.myLeaveRequests.isNotEmpty ? p.myLeaveRequests.first : null;
    if (req == null) return const SizedBox.shrink();

    final statusColor = req.status == 'approved'
        ? const Color(0xFF16A34A)
        : req.status == 'rejected'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    final statusLabel = req.status == 'approved'
        ? 'Disetujui'
        : req.status == 'rejected'
            ? 'Ditolak'
            : 'Menunggu';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.assignment_rounded, color: statusColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengajuan ${req.type}',
                  style: GoogleFonts.plusJakartaSans(
                    color: textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: $statusLabel',
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  // SOS BUTTON
  // ──────────────────────────────────────────
  Widget _buildSOSButton(AppProvider p, GeofenceService geo) {
    return GestureDetector(
      onLongPress: () {
        HapticFeedback.vibrate();
        _showSOSConfirm(context, p, geo);
      },
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  // ──────────────────────────────────────────
  // BOTTOM NAV
  // ──────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    final items = [
      _NavItem(Icons.home_rounded,          Icons.home_outlined,         'Home',     true,  () {}),
      _NavItem(Icons.chat_bubble_rounded,   Icons.chat_bubble_outline,   'Chat',     false, () => Navigator.pushNamed(context, '/chat')),
      _NavItem(Icons.notifications_rounded, Icons.notifications_outlined, 'Notifikasi', false, () => Navigator.pushNamed(context, '/notification')),
      _NavItem(Icons.person_rounded,        Icons.person_outline_rounded, 'Profil',   false, () => Navigator.pushNamed(context, '/profile')),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                item.onTap();
              },
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.isActive ? item.activeIcon : item.icon,
                      color: item.isActive ? primary : textMuted,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: GoogleFonts.plusJakartaSans(
                        color: item.isActive ? primary : textMuted,
                        fontSize: 10,
                        fontWeight: item.isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────
  void _handleAttendance(BuildContext context, AppProvider p, GeofenceService geo) {
    if (_isNavigating) return;
    final role     = (p.currentUser?.role ?? '').toLowerCase();
    final isKurir  = role == 'kurir' || role == 'driver';
    final isRemote = p.currentUser?.allowRemoteAttendance ?? false;
    // Kurir can check out from anywhere; regular staff needs to be in range or remote
    final canProceed = geo.isInRange || isRemote || (isKurir && p.hasClockedInToday);

    if (canProceed) {
      setState(() => _isNavigating = true);
      Navigator.pushNamed(context, '/attendance', arguments: {'isCheckOut': p.hasClockedInToday})
          .then((_) => setState(() => _isNavigating = false));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Anda berada di luar area kantor',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          backgroundColor: const Color(0xFFE31E24),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showSOSConfirm(BuildContext context, AppProvider p, GeofenceService geo) {
    bool dialogLoading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kirim SOS?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sinyal darurat dan lokasi Anda akan segera dilihat oleh Admin Hub.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textMuted,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Batal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: dialogLoading ? null : () async {
                          setDialogState(() => dialogLoading = true);
                          try {
                            if (geo.currentPosition != null) {
                              await p.sendSOS(geo.currentPosition!.latitude, geo.currentPosition!.longitude, 'Martapura Hub');
                            }
                            if (!ctx.mounted) return;
                            Navigator.pop(ctx);
                          } catch (e) {
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: dialogLoading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text('Kirim SOS', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
  Widget _buildNotificationBell(BuildContext context, AppProvider p) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnBadge(ConnectivityService conn) {
    final isOnline = conn.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline 
          ? const Color(0xFF10B981).withValues(alpha: 0.15)
          : const Color(0xFFEF4444).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: GoogleFonts.outfit(
              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String route;
  _MenuItem(this.label, this.icon, this.color, this.bgColor, this.route);
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  _NavItem(this.activeIcon, this.icon, this.label, this.isActive, this.onTap);
}
