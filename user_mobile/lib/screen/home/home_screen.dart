import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Brand palette ──
  static const Color brandRed = Color(0xFFE31E24);
  static const Color jneOrange = Color(0xFFFF6B00);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);

  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();
    final isDark = p.isDarkMode;

    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final user = p.currentUser;
    final firstName = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim().split(' ').first : 'Rekan';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!conn.isOnline) _offlineBanner(),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _header(firstName, textPrimary, textSub, p.unreadNotificationCount, isDark),
                  const SizedBox(height: 20),
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: _attendanceCard(p, geo),
                  ),
                  const SizedBox(height: 28),
                  _sectionHeader('Statistik Bulan Ini', 'Lihat Semua', textPrimary, () => _go('/statistic')),
                  const SizedBox(height: 14),
                  _monthlyStats(p, isDark),
                  const SizedBox(height: 28),
                  _sectionHeader('Saldo Cuti', 'Ajukan', textPrimary, () => _go('/leave')),
                  const SizedBox(height: 14),
                  _leaveBalance(p, isDark, textPrimary, textSub),
                  const SizedBox(height: 28),
                  _sectionHeader('Menu Cepat', null, textPrimary, null),
                  const SizedBox(height: 14),
                  _quickMenu(p, geo, isDark, textPrimary, textSub),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(isDark, p.unreadNotificationCount),
    );
  }

  // ─────────────────────────────────────────── Offline banner
  Widget _offlineBanner() {
    return Container(
      width: double.infinity,
      color: brandRed,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(
          'Mode Offline • data akan tersinkron otomatis',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Header
  Widget _header(String firstName, Color textPrimary, Color textSub, int unread, bool isDark) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,',
                  style: GoogleFonts.plusJakartaSans(color: textSub, fontSize: 13.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('$firstName 👋',
                  style: GoogleFonts.plusJakartaSans(
                      color: textPrimary, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _go('/notification'),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF15203A) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, color: textPrimary, size: 23),
                if (unread > 0)
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9), width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────── Attendance hero card
  Widget _attendanceCard(AppProvider p, GeofenceService geo) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    AttendanceRecord? todayRec;
    for (final r in p.myAttendance) {
      if (r.date == today) {
        todayRec = r;
        break;
      }
    }

    final checkIn = todayRec?.checkIn?.time;
    final checkOut = todayRec?.checkOut?.time;
    final checkInStr = checkIn != null ? DateFormat('HH:mm').format(checkIn) : '--:--';
    final checkOutStr = checkOut != null ? DateFormat('HH:mm').format(checkOut) : '--:--';
    final clockedIn = p.hasClockedInToday;

    // Status badge
    String badge;
    Color badgeColor;
    IconData badgeIcon;
    if (todayRec == null || checkIn == null) {
      badge = 'Belum Absen';
      badgeColor = accentAmber;
      badgeIcon = Icons.schedule_rounded;
    } else if (checkOut != null) {
      badge = 'Selesai';
      badgeColor = accentBlue;
      badgeIcon = Icons.check_circle_rounded;
    } else if (todayRec.status == 'late') {
      badge = 'Terlambat';
      badgeColor = accentAmber;
      badgeIcon = Icons.running_with_errors_rounded;
    } else {
      badge = 'Hadir';
      badgeColor = accentGreen;
      badgeIcon = Icons.verified_rounded;
    }

    final inRange = geo.isInRange;
    final roleLabel = (p.currentUser?.position.trim().isNotEmpty ?? false)
        ? p.currentUser!.position.trim()
        : 'Absensi Hari Ini';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
                      style: GoogleFonts.plusJakartaSans(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      roleLabel,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 13),
                    const SizedBox(width: 5),
                    Text(badge,
                        style: GoogleFonts.plusJakartaSans(color: badgeColor, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _heroStat('Masuk', checkInStr, Icons.login_rounded, accentGreen),
                _heroDivider(),
                _heroStat('Keluar', checkOutStr, Icons.logout_rounded, brandRed),
                _heroDivider(),
                _heroStat(
                  'Lokasi',
                  inRange ? 'Terverifikasi' : 'Di Luar Area',
                  Icons.location_on_rounded,
                  inRange ? accentBlue : Colors.white38,
                  small: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _attendanceButton(p, geo, clockedIn),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon, Color color, {bool small = false}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                color: color == Colors.white38 ? Colors.white60 : Colors.white,
                fontSize: small ? 11.5 : 15,
                fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.08));

  Widget _attendanceButton(AppProvider p, GeofenceService geo, bool clockedIn) {
    final label = clockedIn ? 'Absen Keluar' : 'Absen Masuk';
    final icon = clockedIn ? Icons.logout_rounded : Icons.login_rounded;
    final color = clockedIn ? brandRed : accentGreen;
    return GestureDetector(
      onTap: p.isProcessing ? null : () => _handleAttendance(p, geo),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.82)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: 10),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Monthly stats
  Widget _monthlyStats(AppProvider p, bool isDark) {
    final now = DateTime.now();
    final monthRecords = p.myAttendance.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.month == now.month && d.year == now.year;
    }).toList();

    final hadir = monthRecords.where((r) => ['present', 'late', 'overtime'].contains(r.status)).length;
    final terlambat = monthRecords.where((r) => r.status == 'late').length;
    final absen = monthRecords.where((r) => r.status == 'absent').length;
    final cuti = p.myLeaveRequests
        .where((l) => l.status == 'approved' && l.startDate.month == now.month && l.startDate.year == now.year)
        .fold<int>(0, (s, l) => s + l.totalDays);

    return Row(
      children: [
        _statCard('$hadir', 'Hadir', Icons.check_circle_rounded, accentGreen, isDark),
        const SizedBox(width: 12),
        _statCard('$terlambat', 'Terlambat', Icons.schedule_rounded, accentAmber, isDark),
        const SizedBox(width: 12),
        _statCard('$absen', 'Absen', Icons.cancel_rounded, brandRed, isDark),
        const SizedBox(width: 12),
        _statCard('$cuti', 'Cuti', Icons.beach_access_rounded, accentBlue, isDark),
      ],
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF15203A) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
          boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Leave balance
  Widget _leaveBalance(AppProvider p, bool isDark, Color textPrimary, Color textSub) {
    final b = p.leaveBalance;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15203A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          _balanceCol('${b.remainingAnnual}', 'Cuti Tahunan', 'sisa', accentAmber, textPrimary, textSub),
          _balanceVDivider(isDark),
          _balanceCol('${b.usedSick}', 'Cuti Sakit', 'terpakai', accentBlue, textPrimary, textSub),
          _balanceVDivider(isDark),
          _balanceCol('${b.usedPermission}', 'Cuti Pribadi', 'terpakai', accentGreen, textPrimary, textSub),
        ],
      ),
    );
  }

  Widget _balanceCol(String value, String label, String sub, Color color, Color textPrimary, Color textSub) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: value,
                    style: GoogleFonts.plusJakartaSans(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
                TextSpan(
                    text: ' hari',
                    style: GoogleFonts.plusJakartaSans(color: textSub, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 1),
          Text(sub, style: GoogleFonts.plusJakartaSans(color: textSub, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _balanceVDivider(bool isDark) =>
      Container(width: 1, height: 44, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0));

  // ─────────────────────────────────────────── Quick menu
  Widget _quickMenu(AppProvider p, GeofenceService geo, bool isDark, Color textPrimary, Color textSub) {
    return Row(
      children: [
        _menuTile(Icons.chat_bubble_rounded, 'Chat HR', accentGreen, isDark, textPrimary, () => _go('/chat')),
        const SizedBox(width: 12),
        _menuTile(Icons.assignment_rounded, 'Pengajuan', accentBlue, isDark, textPrimary, () => _go('/my_requests')),
        const SizedBox(width: 12),
        _menuTile(Icons.notifications_rounded, 'Notifikasi', jneOrange, isDark, textPrimary, () => _go('/notification')),
        const SizedBox(width: 12),
        _menuTile(Icons.sos_rounded, 'SOS Darurat', brandRed, isDark, textPrimary, () => _showSOSConfirm(p, geo)),
      ],
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, bool isDark, Color textPrimary, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Section header
  Widget _sectionHeader(String title, String? action, Color textPrimary, VoidCallback? onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 16.5, fontWeight: FontWeight.w800)),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(action,
                style: GoogleFonts.plusJakartaSans(color: jneOrange, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────── Bottom nav
  Widget _bottomNav(bool isDark, int unread) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF15203A) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Beranda', true, isDark, 0, () {}),
              _navItem(Icons.history_rounded, 'Riwayat', false, isDark, 0, () => _go('/history')),
              _navItem(Icons.beach_access_rounded, 'Cuti', false, isDark, 0, () => _go('/leave')),
              _navItem(Icons.person_rounded, 'Profil', false, isDark, unread, () => _go('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, bool isDark, int badge, VoidCallback onTap) {
    final inactive = isDark ? Colors.white38 : const Color(0xFF94A3B8);
    final color = active ? jneOrange : inactive;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        decoration: active
            ? BoxDecoration(color: jneOrange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16))
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 24),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: brandRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF15203A) : Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Text(badge > 9 ? '9+' : '$badge',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Actions
  void _go(String route) => Navigator.pushNamed(context, route);

  void _handleAttendance(AppProvider p, GeofenceService geo) {
    if (_isNavigating) return;
    if (geo.isInRange) {
      setState(() => _isNavigating = true);
      Navigator.pushNamed(context, '/attendance', arguments: {'isCheckOut': p.hasClockedInToday})
          .then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    } else {
      _toast('Anda berada di luar radius kantor. Mendekatlah ke lokasi kantor.', brandRed);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showSOSConfirm(AppProvider p, GeofenceService geo) {
    final isDark = context.read<AppProvider>().isDarkMode;
    final card = isDark ? const Color(0xFF15203A) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    bool dialogLoading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: card,
          surfaceTintColor: card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: brandRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: brandRed, size: 38),
              ),
              const SizedBox(height: 20),
              Text('Kirim Sinyal SOS?',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 19, color: txt)),
              const SizedBox(height: 10),
              Text(
                'Lokasi dan sinyal darurat Anda akan langsung dipantau oleh admin hub. Gunakan hanya saat darurat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: sub, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                      child: Text('Batal',
                          style: GoogleFonts.plusJakartaSans(color: sub, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: dialogLoading
                          ? null
                          : () async {
                              final navigator = Navigator.of(ctx);
                              setDialogState(() => dialogLoading = true);
                              try {
                                if (geo.currentPosition != null) {
                                  await p.sendSOS(geo.currentPosition!.latitude, geo.currentPosition!.longitude,
                                      '${p.hubName} Area');
                                }
                                navigator.pop();
                                _toast('Sinyal SOS terkirim!', brandRed);
                              } catch (e) {
                                navigator.pop();
                                _toast('Gagal mengirim SOS: $e', brandRed);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: dialogLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : Text('Kirim', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
