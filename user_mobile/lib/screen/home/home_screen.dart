import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_strings.dart';
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
  bool _forceUpdateShown = false;

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();
    final pal = context.palette;

    if (p.forceUpdate && !_forceUpdateShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showForceUpdate(p));
    }

    final user = p.currentUser;
    final firstName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim().split(' ').first
        : context.tr('buddy');

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
                        if (p.updateAvailable) ...[
                          _updateBanner(p, pal),
                          const SizedBox(height: 18),
                        ],
                        FadeInDown(
                          duration: const Duration(milliseconds: 500),
                          child: _attendanceHero(p, geo),
                        ),
                        const SizedBox(height: 26),
                        _sectionHeader(
                          context.tr('sec_stats'),
                          context.tr('open'),
                          pal,
                          () => _go('/statistic'),
                        ),
                        const SizedBox(height: 14),
                        FadeInUp(
                          duration: const Duration(milliseconds: 450),
                          child: _monthlyStats(p, pal),
                        ),
                        const SizedBox(height: 26),
                        _sectionHeader(
                          context.tr('sec_location'),
                          context.tr('open_map'),
                          pal,
                          () => _go('/lokasi'),
                        ),
                        const SizedBox(height: 14),
                        FadeInUp(
                          duration: const Duration(milliseconds: 450),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: LiveLocationMap(
                              compact: true,
                              height: 172,
                              borderRadius: 24,
                              onTap: () => _go('/lokasi'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        _sectionHeader(
                          context.tr('sec_leave_balance'),
                          context.tr('submit'),
                          pal,
                          () => _go('/leave'),
                        ),
                        const SizedBox(height: 14),
                        _leaveBalance(p, pal),
                        const SizedBox(height: 26),
                        _sectionHeader(
                          context.tr('sec_quick_menu'),
                          null,
                          pal,
                          null,
                        ),
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
      child: Text(
        context.tr('offline_banner'),
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );

  Widget _dataErrorBanner(AppProvider p) => GestureDetector(
    onTap: () => _showDataErrorDialog(p),
    child: Container(
      width: double.infinity,
      color: AppColors.brandRedDark,
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('data_error_banner'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.white70,
            size: 18,
          ),
        ],
      ),
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
        title: Text(
          'Detail Error Data',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: pal.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: SelectableText(
            p.dataError ?? '-',
            style: GoogleFonts.robotoMono(
              fontSize: 11.5,
              height: 1.5,
              color: pal.textPrimary,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              p.clearDataError();
              Navigator.pop(ctx);
            },
            child: Text(
              'Tutup',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.brandRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────── Header
  // ── Banner update (APK sideload, lihat AppProvider._checkAppUpdate) ──
  Widget _updateBanner(AppProvider p, AppPalette pal) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: AppColors.blue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('update_available'),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: pal.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v${p.latestVersionName}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: pal.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _launchUpdate(p.updateApkUrl),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              context.tr('update_now'),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUpdate(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showForceUpdate(AppProvider p) {
    if (_forceUpdateShown || !mounted) return;
    _forceUpdateShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(context.tr('update_force_title')),
          content: Text(context.tr('update_force_desc')),
          actions: [
            ElevatedButton(
              onPressed: () => _launchUpdate(p.updateApkUrl),
              child: Text(context.tr('update_now')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(String firstName, AppPalette pal, int unread) {
    final hour = DateTime.now().hour;
    final greeting = hour < 11
        ? context.tr('greet_morning')
        : hour < 15
        ? context.tr('greet_afternoon')
        : hour < 18
        ? context.tr('greet_evening')
        : context.tr('greet_night');
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting,',
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textSub,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                firstName,
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
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
                Icon(
                  Icons.notifications_none_rounded,
                  color: pal.textPrimary,
                  size: 24,
                ),
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
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
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

  // ─────────────────────────────────────────── Attendance hero (solid navy)
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
    final checkInStr = checkIn != null
        ? DateFormat('HH:mm').format(checkIn)
        : '--:--';
    final checkOutStr = checkOut != null
        ? DateFormat('HH:mm').format(checkOut)
        : '--:--';
    final clockedIn = p.hasClockedInToday;
    final inRange = geo.isInRange;

    String badge;
    IconData badgeIcon;
    if (todayRec == null || checkIn == null) {
      badge = context.tr('status_not_yet');
      badgeIcon = Icons.schedule_rounded;
    } else if (checkOut != null) {
      badge = context.tr('status_done');
      badgeIcon = Icons.check_circle_rounded;
    } else if (todayRec.status == 'late') {
      badge = context.tr('status_late');
      badgeIcon = Icons.running_with_errors_rounded;
    } else {
      badge = context.tr('status_present');
      badgeIcon = Icons.verified_rounded;
    }

    final roleLabel = (p.currentUser?.position.trim().isNotEmpty ?? false)
        ? p.currentUser!.position.trim()
        : context.tr('attendance_today');

    return Container(
      decoration: context.palette.heroDecoration(radius: 30),
      child: Stack(
        children: [
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
                          Text(
                            DateFormat(
                              'EEEE, d MMMM yyyy',
                              'id',
                            ).format(DateTime.now()),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            roleLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text(
                            badge,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _heroStat(
                      context.tr('check_in'),
                      checkInStr,
                      Icons.login_rounded,
                    ),
                    _heroDivider(),
                    _heroStat(
                      context.tr('check_out'),
                      checkOutStr,
                      Icons.logout_rounded,
                    ),
                    _heroDivider(),
                    _heroStat(
                      context.tr('location'),
                      inRange ? context.tr('in_area') : context.tr('out_area'),
                      Icons.location_on_rounded,
                      small: true,
                    ),
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

  Widget _heroStat(
    String label,
    String value,
    IconData icon, {
    bool small = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: small ? 12 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(
    width: 1,
    height: 38,
    color: Colors.white.withValues(alpha: 0.2),
  );

  Widget _attendanceCta(AppProvider p, GeofenceService geo, bool clockedIn) {
    final label = clockedIn
        ? context.tr('do_check_out')
        : context.tr('do_check_in');
    final icon = clockedIn ? Icons.logout_rounded : Icons.login_rounded;
    return GestureDetector(
      onTap: p.isProcessing ? null : () => _handleAttendance(p, geo),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.brandRed, size: 19),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.brandRed,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
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
    final hadir = monthRecords
        .where((r) => ['present', 'late', 'overtime'].contains(r.status))
        .length;
    final terlambat = monthRecords.where((r) => r.status == 'late').length;
    final absen = monthRecords.where((r) => r.status == 'absent').length;
    final cuti = p.myLeaveRequests
        .where(
          (l) =>
              l.status == 'approved' &&
              l.startDate.month == now.month &&
              l.startDate.year == now.year,
        )
        .fold<int>(0, (s, l) => s + l.totalDays);

    return Row(
      children: [
        _statCard(
          '$hadir',
          context.tr('stat_present'),
          Icons.check_circle_rounded,
          AppColors.green,
          pal,
        ),
        const SizedBox(width: 12),
        _statCard(
          '$terlambat',
          context.tr('stat_late'),
          Icons.schedule_rounded,
          AppColors.amber,
          pal,
        ),
        const SizedBox(width: 12),
        _statCard(
          '$absen',
          context.tr('stat_absent'),
          Icons.cancel_rounded,
          AppColors.brandRed,
          pal,
        ),
        const SizedBox(width: 12),
        _statCard(
          '$cuti',
          context.tr('stat_leave'),
          Icons.beach_access_rounded,
          AppColors.blue,
          pal,
        ),
      ],
    );
  }

  Widget _statCard(
    String value,
    String label,
    IconData icon,
    Color color,
    AppPalette pal,
  ) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
        radius: 18,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: pal.textSub,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Leave balance (glass)
  Widget _leaveBalance(AppProvider p, AppPalette pal) {
    final b = p.leaveBalance;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      child: Row(
        children: [
          _balanceCol(
            '${b.remainingAnnual}',
            context.tr('leave_annual'),
            context.tr('remaining'),
            AppColors.amber,
            pal,
          ),
          _balanceVDivider(pal),
          _balanceCol(
            '${b.usedSick}',
            context.tr('leave_sick'),
            context.tr('used'),
            AppColors.blue,
            pal,
          ),
          _balanceVDivider(pal),
          _balanceCol(
            '${b.usedPermission}',
            context.tr('leave_personal'),
            context.tr('used'),
            AppColors.green,
            pal,
          ),
        ],
      ),
    );
  }

  Widget _balanceCol(
    String value,
    String label,
    String sub,
    Color color,
    AppPalette pal,
  ) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' hari',
                  style: GoogleFonts.plusJakartaSans(
                    color: pal.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: pal.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              color: pal.textSub,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceVDivider(AppPalette pal) => Container(
    width: 1,
    height: 44,
    color: pal.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.06),
  );

  // ─────────────────────────────────────────── Quick menu (glass + gradient icons)
  Widget _quickMenu(AppProvider p, GeofenceService geo, AppPalette pal) {
    return Row(
      children: [
        _menuTile(
          Icons.chat_bubble_rounded,
          context.tr('menu_chat'),
          AppColors.green,
          pal,
          () => _go('/chat'),
        ),
        const SizedBox(width: 12),
        _menuTile(
          Icons.assignment_rounded,
          context.tr('menu_requests'),
          AppColors.blue,
          pal,
          () => _go('/my_requests'),
        ),
        const SizedBox(width: 12),
        _menuTile(
          Icons.map_rounded,
          context.tr('menu_location'),
          AppColors.jneOrange,
          pal,
          () => _go('/lokasi'),
        ),
        const SizedBox(width: 12),
        _menuTile(
          Icons.sos_rounded,
          context.tr('menu_sos'),
          AppColors.brandRed,
          pal,
          () => _showSOSConfirm(p, geo),
        ),
      ],
    );
  }

  Widget _menuTile(
    IconData icon,
    String label,
    Color color,
    AppPalette pal,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Column(
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withValues(alpha: pal.isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────── Section header
  Widget _sectionHeader(
    String title,
    String? action,
    AppPalette pal,
    VoidCallback? onAction,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: pal.textPrimary,
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (action != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              action,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.jneOrange,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
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
          _navItem(
            Icons.home_rounded,
            context.tr('nav_home'),
            true,
            pal,
            0,
            () {},
          ),
          _navItem(
            Icons.history_rounded,
            context.tr('nav_history'),
            false,
            pal,
            0,
            () => _go('/history'),
          ),
          _navItem(
            Icons.beach_access_rounded,
            context.tr('nav_leave'),
            false,
            pal,
            0,
            () => _go('/leave'),
          ),
          _navItem(
            Icons.person_rounded,
            context.tr('nav_profile'),
            false,
            pal,
            unread,
            () => _go('/profile'),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    AppPalette pal,
    int badge,
    VoidCallback onTap,
  ) {
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
        padding: EdgeInsets.symmetric(
          horizontal: active ? 16 : 14,
          vertical: 8,
        ),
        decoration: active
            ? BoxDecoration(
                color: AppColors.brandRed,
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 22),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: pal.bg, width: 1.5),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 15,
                        minHeight: 15,
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
    if (geo.isInRange || p.canBypassGeofence) {
      setState(() => _isNavigating = true);
      Navigator.pushNamed(
        context,
        '/attendance',
        arguments: {'isCheckOut': p.hasClockedInToday},
      ).then((_) {
        if (mounted) setState(() => _isNavigating = false);
      });
    } else {
      _toast(context.tr('out_of_radius'), AppColors.brandRed);
    }
  }

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.brandRed,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('sos_title'),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                  color: pal.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.tr('sos_desc'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: dialogLoading
                          ? null
                          : () => Navigator.pop(ctx),
                      child: Text(
                        context.tr('cancel'),
                        style: GoogleFonts.plusJakartaSans(
                          color: pal.textSub,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: dialogLoading
                          ? null
                          : () async {
                              final navigator = Navigator.of(ctx);
                              final sentMsg = context.tr('sos_sent');
                              setDialogState(() => dialogLoading = true);
                              try {
                                if (geo.currentPosition != null) {
                                  await p.sendSOS(
                                    geo.currentPosition!.latitude,
                                    geo.currentPosition!.longitude,
                                    '${p.hubName} Area',
                                  );
                                }
                                navigator.pop();
                                _toast(sentMsg, AppColors.brandRed);
                              } catch (e) {
                                navigator.pop();
                                _toast(
                                  'Gagal mengirim SOS: $e',
                                  AppColors.brandRed,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: dialogLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              context.tr('send'),
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
