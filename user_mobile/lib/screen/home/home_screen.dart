import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';
import '../../widgets/live_location_map.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isNavigating = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();
    final pal = context.palette;

    final user = p.currentUser;
    final firstName = (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim().split(' ').first : 'Rekan';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AuroraBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (!conn.isOnline) _offlineBanner(),
              if (p.dataError != null) _dataErrorBanner(p),
              Expanded(
                child: Stack(
                  children: [
                    ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                      children: [
                        _header(firstName, pal, p.unreadNotificationCount),
                        const SizedBox(height: 22),
                        FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: _attendanceHero(p, geo),
                        ),
                        const SizedBox(height: 26),
                        _sectionHeader('Statistik Bulan Ini', 'Lihat', pal, () => _go('/statistic')),
                        const SizedBox(height: 14),
                        FadeInUp(duration: const Duration(milliseconds: 450), child: _monthlyStats(p, pal)),
                        const SizedBox(height: 26),
                        _sectionHeader('Lokasi Saya', 'Peta', pal, () => _go('/lokasi')),
                        const SizedBox(height: 14),
                        FadeInUp(
                          duration: const Duration(milliseconds: 450),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: LiveLocationMap(compact: true, height: 172, borderRadius: 24, onTap: () => _go('/lokasi')),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _sectionHeader('Saldo Cuti', 'Ajukan', pal, () => _go('/leave')),
                        const SizedBox(height: 14),
                        _leaveBalance(p, pal),
                        const SizedBox(height: 26),
                        _sectionHeader('Menu Cepat', null, pal, null),
                        const SizedBox(height: 14),
                        _quickMenu(p, geo, pal),
                      ],
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _floatingNav(pal, p.unreadNotificationCount),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Banners
  Widget _offlineBanner() => Container(
        width: double.infinity,
        color: AppColors.brandRed,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text('Mode Offline • data akan tersinkron otomatis',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _dataErrorBanner(AppProvider p) => GestureDetector(
        onTap: () => _showDataErrorDialog(p),
        child: Container(
          width: double.infinity,
          color: AppColors.brandRedDark,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Sebagian data gagal dimuat • ketuk untuk detail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 18),
          ]),
        ),
      );

  void _showDataErrorDialog(AppProvider p) {
    final pal = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Detail Error Data',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16, color: pal.textPrimary)),
        content: SingleChildScrollView(
          child: SelectableText(p.dataError ?? '-',
              style: GoogleFonts.robotoMono(fontSize: 11.5, height: 1.5, color: pal.textPrimary)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              p.clearDataError();
              Navigator.pop(ctx);
            },
            child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.brandRed)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────── Header
  Widget _header(String firstName, AppPalette pal, int unread) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? 'Selamat Pagi'
        : hour < 15
            ? 'Selamat Siang'
            : hour < 18
                ? 'Selamat Sore'
                : 'Selamat Malam';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$greeting,',
                  style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 13.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(firstName,
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textPrimary, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
            ],
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          radius: 16,
          onTap: () => _go('/notification'),
          child: SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded, color: pal.textPrimary, size: 24),
                if (unread > 0)
                  Positioned(
                    top: 11,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: pal.bg, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(unread > 9 ? '9+' : '$unread',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────── Attendance hero (bold gradient)
  Widget _attendanceHero(AppProvider p, GeofenceService geo) {
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
    final inRange = geo.isInRange;

    String badge;
    IconData badgeIcon;
    if (todayRec == null || checkIn == null) {
      badge = 'Belum Absen';
      badgeIcon = Icons.schedule_rounded;
    } else if (checkOut != null) {
      badge = 'Selesai';
      badgeIcon = Icons.check_circle_rounded;
    } else if (todayRec.status == 'late') {
      badge = 'Terlambat';
      badgeIcon = Icons.running_with_errors_rounded;
    } else {
      badge = 'Hadir';
      badgeIcon = Icons.verified_rounded;
    }

    final roleLabel = (p.currentUser?.position.trim().isNotEmpty ?? false)
        ? p.currentUser!.position.trim()
        : 'Absensi Hari Ini';

    return Container(
      decoration: context.palette.brandHeroDecoration(radius: 30),
      child: Stack(
        children: [
          // dekor lingkaran translucent untuk kedalaman
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now()),
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(roleLabel,
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(badgeIcon, color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(badge, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _heroStat('Masuk', checkInStr, Icons.login_rounded),
                    _heroDivider(),
                    _heroStat('Keluar', checkOutStr, Icons.logout_rounded),
                    _heroDivider(),
                    _heroStat('Lokasi', inRange ? 'Dalam Area' : 'Luar Area', Icons.location_on_rounded, small: true),
                  ],
                ),
                const SizedBox(height: 18),
                _attendanceCta(p, geo, clockedIn),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, String value, IconData icon, {bool small = false}) {
    return Expanded(
      child: Column(children: [
        Icon(icon, color: Colors.white, size: 17),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: small ? 12 : 16, fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Widget _heroDivider() => Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.2));

  Widget _attendanceCta(AppProvider p, GeofenceService geo, bool clockedIn) {
    final label = clockedIn ? 'Absen Keluar Sekarang' : 'Absen Masuk Sekarang';
    final icon = clockedIn ? Icons.logout_rounded : Icons.login_rounded;
    return GestureDetector(
      onTap: p.isProcessing ? null : () => _handleAttendance(p, geo),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.brandRed, size: 19),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.brandRed, fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Monthly stats (glass)
  Widget _monthlyStats(AppProvider p, AppPalette pal) {
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

    return Row(children: [
      _statCard('$hadir', 'Hadir', Icons.check_circle_rounded, AppColors.green, pal),
      const SizedBox(width: 12),
      _statCard('$terlambat', 'Telat', Icons.schedule_rounded, AppColors.amber, pal),
      const SizedBox(width: 12),
      _statCard('$absen', 'Absen', Icons.cancel_rounded, AppColors.brandRed, pal),
      const SizedBox(width: 12),
      _statCard('$cuti', 'Cuti', Icons.beach_access_rounded, AppColors.blue, pal),
    ]);
  }

  Widget _statCard(String value, String label, IconData icon, Color color, AppPalette pal) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        radius: 18,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.18),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12)],
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.plusJakartaSans(color: pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 1),
          Text(label, style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────── Leave balance (glass)
  Widget _leaveBalance(AppProvider p, AppPalette pal) {
    final b = p.leaveBalance;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Row(children: [
        _balanceCol('${b.remainingAnnual}', 'Cuti Tahunan', 'sisa', AppColors.amber, pal),
        _balanceVDivider(pal),
        _balanceCol('${b.usedSick}', 'Cuti Sakit', 'terpakai', AppColors.blue, pal),
        _balanceVDivider(pal),
        _balanceCol('${b.usedPermission}', 'Cuti Pribadi', 'terpakai', AppColors.green, pal),
      ]),
    );
  }

  Widget _balanceCol(String value, String label, String sub, Color color, AppPalette pal) {
    return Expanded(
      child: Column(children: [
        RichText(
          text: TextSpan(children: [
            TextSpan(text: value, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 24, fontWeight: FontWeight.w800)),
            TextSpan(text: ' hari', style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.plusJakartaSans(color: pal.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 1),
        Text(sub, style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 10, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _balanceVDivider(AppPalette pal) =>
      Container(width: 1, height: 44, color: pal.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06));

  // ─────────────────────────────────────────── Quick menu (glass + gradient icons)
  Widget _quickMenu(AppProvider p, GeofenceService geo, AppPalette pal) {
    return Row(children: [
      _menuTile(Icons.chat_bubble_rounded, 'Chat HR', AppColors.green, pal, () => _go('/chat')),
      const SizedBox(width: 12),
      _menuTile(Icons.assignment_rounded, 'Pengajuan', AppColors.blue, pal, () => _go('/my_requests')),
      const SizedBox(width: 12),
      _menuTile(Icons.map_rounded, 'Lokasi', AppColors.jneOrange, pal, () => _go('/lokasi')),
      const SizedBox(width: 12),
      _menuTile(Icons.sos_rounded, 'SOS', AppColors.brandRed, pal, () => _showSOSConfirm(p, geo)),
    ]);
  }

  Widget _menuTile(IconData icon, String label, Color color, AppPalette pal, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(color: pal.textPrimary, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────── Section header
  Widget _sectionHeader(String title, String? action, AppPalette pal, VoidCallback? onAction) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: GoogleFonts.plusJakartaSans(color: pal.textPrimary, fontSize: 16.5, fontWeight: FontWeight.w800)),
      if (action != null && onAction != null)
        GestureDetector(
          onTap: onAction,
          child: Text(action, style: GoogleFonts.plusJakartaSans(color: AppColors.jneOrange, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
    ]);
  }

  // ─────────────────────────────────────────── Floating glass bottom nav
  Widget _floatingNav(AppPalette pal, int unread) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      radius: 24,
      blur: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_rounded, 'Beranda', true, pal, 0, () {}),
          _navItem(Icons.history_rounded, 'Riwayat', false, pal, 0, () => _go('/history')),
          _navItem(Icons.beach_access_rounded, 'Cuti', false, pal, 0, () => _go('/leave')),
          _navItem(Icons.person_rounded, 'Profil', false, pal, unread, () => _go('/profile')),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, AppPalette pal, int badge, VoidCallback onTap) {
    final inactive = pal.textFaint;
    final color = active ? Colors.white : inactive;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: active ? 16 : 14, vertical: 8),
        decoration: active
            ? BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.brandGradient),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.brandRed.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(icon, color: color, size: 22),
              if (badge > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(color: AppColors.brandRed, shape: BoxShape.circle, border: Border.all(color: pal.bg, width: 1.5)),
                    constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Text(badge > 9 ? '9+' : '$badge',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800)),
                  ),
                ),
            ]),
            if (active) ...[
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
            ],
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
      Navigator.pushNamed(context, '/attendance', arguments: {'isCheckOut': p.hasClockedInToday}).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    } else {
      _toast('Anda berada di luar radius kantor. Mendekatlah ke lokasi kantor.', AppColors.brandRed);
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
    final pal = context.palette;
    bool dialogLoading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: pal.card,
          surfaceTintColor: pal.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.brandRed.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.brandRed, size: 38),
              ),
              const SizedBox(height: 20),
              Text('Kirim Sinyal SOS?',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 19, color: pal.textPrimary)),
              const SizedBox(height: 10),
              Text('Lokasi dan sinyal darurat Anda akan langsung dipantau oleh admin hub. Gunakan hanya saat darurat.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 13, fontWeight: FontWeight.w500, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                    child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontWeight: FontWeight.w700)),
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
                                await p.sendSOS(geo.currentPosition!.latitude, geo.currentPosition!.longitude, '${p.hubName} Area');
                              }
                              navigator.pop();
                              _toast('Sinyal SOS terkirim!', AppColors.brandRed);
                            } catch (e) {
                              navigator.pop();
                              _toast('Gagal mengirim SOS: $e', AppColors.brandRed);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandRed,
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
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
