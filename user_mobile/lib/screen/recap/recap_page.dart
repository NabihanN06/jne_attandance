import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_strings.dart';

/// Recap kinerja bulan berjalan untuk karyawan yang login.
class RecapPage extends StatefulWidget {
  const RecapPage({super.key});

  @override
  State<RecapPage> createState() => _RecapPageState();
}

class _RecapData {
  final int present, late, absent, leave, workMinutes, overtimeMinutes, packages;
  const _RecapData({
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.leave = 0,
    this.workMinutes = 0,
    this.overtimeMinutes = 0,
    this.packages = 0,
  });
  int get onTimeRate =>
      present == 0 ? 100 : (((present - late) / present) * 100).round();
}

class _RecapPageState extends State<RecapPage> {
  late final Future<_RecapData> _future;

  bool _isCourier(String dept) =>
      RegExp(r'rider|driver|delivery|kurir', caseSensitive: false).hasMatch(dept);

  @override
  void initState() {
    super.initState();
    final user = context.read<AppProvider>().currentUser;
    _future = _load(user?.uid ?? '', user?.department ?? '');
  }

  Future<_RecapData> _load(String uid, String dept) async {
    if (uid.isEmpty) return const _RecapData();
    final db = FirebaseFirestore.instance;
    final monthPrefix = DateFormat('yyyy-MM').format(DateTime.now());

    // Query userId saja (single-field, tanpa index khusus), filter bulan lokal.
    final attSnap =
        await db.collection('attendance').where('userId', isEqualTo: uid).get();
    int present = 0, late = 0, absent = 0, leave = 0, workMin = 0, otMin = 0;
    for (final d in attSnap.docs) {
      final data = d.data();
      final date = (data['date'] ?? data['attendanceDate'] ?? '').toString();
      if (!date.startsWith(monthPrefix)) continue;
      final s = (data['status'] ?? '').toString();
      if (s == 'present' || s == 'late' || s == 'overtime') present++;
      if (s == 'late') late++;
      if (s == 'absent') absent++;
      if (s == 'leave') leave++;
      workMin += (data['totalWorkMinutes'] as num?)?.toInt() ?? 0;
      otMin += (data['overtimeMinutes'] as num?)?.toInt() ?? 0;
    }

    int packages = 0;
    if (_isCourier(dept)) {
      final pkgSnap = await db
          .collection('courier_packages')
          .where('userId', isEqualTo: uid)
          .get();
      for (final d in pkgSnap.docs) {
        final data = d.data();
        if (!(data['date'] ?? '').toString().startsWith(monthPrefix)) continue;
        packages += (data['count'] as num?)?.toInt() ?? 0;
      }
    }

    return _RecapData(
      present: present,
      late: late,
      absent: absent,
      leave: leave,
      workMinutes: workMin,
      overtimeMinutes: otMin,
      packages: packages,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pal = context.palette;
    final user = provider.currentUser;
    final monthLabel = DateFormat(
            'MMMM yyyy', provider.language == 'en' ? 'en' : 'id')
        .format(DateTime.now());

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(),
        centerTitle: true,
        title: Text(
          context.tr('recap_title'),
          style: GoogleFonts.plusJakartaSans(
              color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<_RecapData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          }
          final r = snap.data ?? const _RecapData();
          final isCourier = _isCourier(user?.department ?? '');
          final hours = (r.workMinutes / 60).toStringAsFixed(r.workMinutes % 60 == 0 ? 0 : 1);
          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _hero(pal, user?.name ?? '', monthLabel, r),
              const SizedBox(height: 22),
              SectionLabel(context.tr('recap_detail')),
              const SizedBox(height: 4),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _stat(pal, '${r.present}', context.tr('recap_present'),
                      Icons.check_circle_rounded, AppColors.green),
                  _stat(pal, '${r.onTimeRate}%', context.tr('recap_ontime'),
                      Icons.timer_rounded, AppColors.blue),
                  _stat(pal, '${r.late}', context.tr('recap_late'),
                      Icons.schedule_rounded, AppColors.amber),
                  _stat(pal, '$hours ${context.tr('recap_hours')}',
                      context.tr('recap_workhours'), Icons.work_history_rounded,
                      AppColors.brandRed),
                  if (r.leave > 0)
                    _stat(pal, '${r.leave}', context.tr('recap_leave'),
                        Icons.beach_access_rounded, const Color(0xFF8B5CF6)),
                  if (r.overtimeMinutes > 0)
                    _stat(pal, '${(r.overtimeMinutes / 60).toStringAsFixed(1)} ${context.tr('recap_hours')}',
                        context.tr('recap_overtime'), Icons.bolt_rounded,
                        const Color(0xFFF59E0B)),
                  if (isCourier)
                    _stat(pal, '${r.packages}', context.tr('recap_packages'),
                        Icons.local_shipping_rounded, AppColors.brandRed),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _hero(AppPalette pal, String name, String monthLabel, _RecapData r) {
    final rate = r.onTimeRate;
    final msg = rate >= 95
        ? context.tr('recap_msg_great')
        : rate >= 80
            ? context.tr('recap_msg_good')
            : context.tr('recap_msg_improve');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(monthLabel.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                  color: AppColors.brandRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            '${context.tr('recap_hi')} ${name.split(' ').first} 👋',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(msg,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Row(children: [
            _heroNum('${r.present}', context.tr('recap_present')),
            _heroDivider(),
            _heroNum('$rate%', context.tr('recap_ontime')),
            _heroDivider(),
            _heroNum('${r.absent}', context.tr('recap_absent')),
          ]),
        ],
      ),
    );
  }

  Widget _heroNum(String v, String l) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(l,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _heroDivider() => Container(
      width: 1, height: 34, color: Colors.white.withValues(alpha: 0.1));

  Widget _stat(AppPalette pal, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: pal.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    color: pal.textPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 1),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: pal.textSub, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }
}
