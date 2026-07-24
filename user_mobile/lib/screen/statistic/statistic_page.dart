import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../../widgets/ui_kit.dart';

/// Rentang periode yang dipilih pengguna (mingguan/bulanan).
enum _Mode { weekly, monthly }

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});
  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  _Mode _mode = _Mode.monthly;

  // Anchor = hari mana pun di dalam periode terpilih. Untuk mingguan kita
  // normalisasi ke Senin; untuk bulanan ke tanggal 1.
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Tarik ulang data absensi (≈ 1 tahun) supaya statistik bulan/minggu lama
    // tetap akurat — listener utama hanya menyimpan 70 dokumen terakhir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchStatsRecords(force: true);
    });
  }

  // ── Rentang tanggal periode aktif ──
  DateTime get _rangeStart {
    if (_mode == _Mode.weekly) {
      final monday = _anchor.subtract(Duration(days: _anchor.weekday - 1));
      return DateTime(monday.year, monday.month, monday.day);
    }
    return DateTime(_anchor.year, _anchor.month, 1);
  }

  DateTime get _rangeEnd {
    if (_mode == _Mode.weekly) {
      return _rangeStart.add(const Duration(days: 6));
    }
    return DateTime(_anchor.year, _anchor.month + 1, 0);
  }

  void _shift(int dir) {
    setState(() {
      _anchor = _mode == _Mode.weekly
          ? _anchor.add(Duration(days: 7 * dir))
          : DateTime(_anchor.year, _anchor.month + dir, 1);
    });
  }

  void _setMode(_Mode m) {
    setState(() {
      _mode = m;
      _anchor = DateTime.now();
    });
  }

  String _periodLabel(String lang) {
    if (_mode == _Mode.weekly) {
      final s = _rangeStart;
      final e = _rangeEnd;
      final df = DateFormat(s.month == e.month ? 'd' : 'd MMM', lang);
      return '${df.format(s)} – ${DateFormat('d MMM yyyy', lang).format(e)}';
    }
    final months = AppStrings.months(lang);
    return '${months[_anchor.month - 1]} ${_anchor.year}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pal = context.palette;
    final lang = provider.language;
    final stats = provider.getStatsForRange(_rangeStart, _rangeEnd);
    final loading = provider.isLoadingStats && provider.myAttendance.isEmpty;

    final present = stats['present'] as int;
    final leaves = stats['leaves'] as int;
    final absent = stats['absent'] as int;
    final lateMinutes = stats['lateMinutes'] as int;
    final workMinutes = stats['workMinutes'] as int;
    final overtimeMinutes = stats['overtimeMinutes'] as int;
    final records = stats['records'] as List;
    final hasData = records.isNotEmpty;

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: pal.bg,
        leading: const AppBackButton(),
        centerTitle: true,
        title: Text(
          context.tr('work_statistics'),
          style: GoogleFonts.plusJakartaSans(
            color: pal.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildModeToggle(pal),
          const SizedBox(height: 16),
          _buildPeriodSelector(pal, lang),
          const SizedBox(height: 20),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasData)
            _buildEmpty()
          else ...[
            _buildStatGrid(
              pal,
              present: present,
              leaves: leaves,
              absent: absent,
              lateMinutes: lateMinutes,
              workMinutes: workMinutes,
              overtimeMinutes: overtimeMinutes,
            ),
            const SizedBox(height: 20),
            _buildPerformance(
              punctuality: stats['punctuality'] as double?,
              attendanceRate: (present + absent) > 0
                  ? present / (present + absent)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  // ── Toggle Mingguan / Bulanan ──
  Widget _buildModeToggle(AppPalette pal) {
    Widget seg(String label, _Mode m) {
      final active = _mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => _setMode(m),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.indigo : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.indigo.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: active ? Colors.white : pal.textSub,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border),
      ),
      child: Row(
        children: [
          seg(context.tr('weekly_word'), _Mode.weekly),
          seg(context.tr('monthly_word'), _Mode.monthly),
        ],
      ),
    );
  }

  // ── Navigasi periode (‹ label ›) ──
  Widget _buildPeriodSelector(AppPalette pal, String lang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: pal.border),
        boxShadow: pal.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.indigo,
            ),
            onPressed: () => _shift(-1),
          ),
          Expanded(
            child: Text(
              _periodLabel(lang),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.indigo,
            ),
            // Cegah lompat ke masa depan.
            onPressed: _rangeEnd.isBefore(DateTime.now())
                ? () => _shift(1)
                : null,
          ),
        ],
      ),
    );
  }

  // ── Grid statistik ──
  Widget _buildStatGrid(
    AppPalette pal, {
    required int present,
    required int leaves,
    required int absent,
    required int lateMinutes,
    required int workMinutes,
    required int overtimeMinutes,
  }) {
    final hours = workMinutes ~/ 60;
    final mins = workMinutes % 60;
    final tiles = <Widget>[
      _statTile(
        pal,
        present.toString().padLeft(2, '0'),
        context.tr('days_present'),
        Icons.check_circle_rounded,
        AppColors.green,
      ),
      _statTile(
        pal,
        leaves.toString().padLeft(2, '0'),
        context.tr('leave_sick_label'),
        Icons.assignment_rounded,
        AppColors.amber,
      ),
      _statTile(
        pal,
        lateMinutes.toString().padLeft(2, '0'),
        context.tr('late_minutes'),
        Icons.alarm_rounded,
        AppColors.brandRed,
      ),
      _statTile(
        pal,
        mins == 0 ? '$hours' : '${hours}j ${mins}m',
        context.tr('total_hours'),
        Icons.timer_rounded,
        AppColors.sky,
      ),
    ];
    // Baris kedua opsional: Alfa + Lembur bila relevan.
    if (absent > 0 || overtimeMinutes > 0) {
      tiles.add(
        _statTile(
          pal,
          absent.toString().padLeft(2, '0'),
          context.tr('alpha_word'),
          Icons.cancel_rounded,
          AppColors.brandRed,
        ),
      );
      final oh = overtimeMinutes ~/ 60;
      final om = overtimeMinutes % 60;
      tiles.add(
        _statTile(
          pal,
          om == 0 ? '${oh}j' : '${oh}j ${om}m',
          context.tr('overtime_word'),
          Icons.bolt_rounded,
          AppColors.violet,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 14.0;
        final w = (c.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }

  Widget _statTile(
    AppPalette pal,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: pal.cardDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: pal.isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: pal.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: pal.textSub,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Analisis performa ──
  /// Ringkasan performa — sengaja HANYA memuat dua angka yang benar-benar
  /// berarti bagi karyawan dan bisa mereka pengaruhi sendiri.
  ///
  /// Dua metrik lama dihapus karena menyesatkan:
  /// • "Kepatuhan Lokasi" — absen di luar radius memang sudah DITOLAK sistem,
  ///   jadi angkanya selalu 100% dan tidak memberi informasi apa pun. Lebih
  ///   buruk lagi, kurir yang memang diizinkan absen dari luar kantor justru
  ///   tampak "tidak patuh" padahal sedang bekerja sesuai aturan.
  /// • "Efektivitas Jam" — sebenarnya cuma menghitung absen yang ada jam
  ///   pulangnya, yakni "ingat absen pulang", sama sekali bukan efektivitas.
  Widget _buildPerformance({
    required double? punctuality,
    required double? attendanceRate,
  }) {
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
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amber,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                context.tr('performance_analysis').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _analysisRow(
            context.tr('punctuality_label'),
            punctuality,
            AppColors.green,
          ),
          const SizedBox(height: 20),
          _analysisRow(
            context.tr('attendance_rate_label'),
            attendanceRate,
            AppColors.sky,
          ),
        ],
      ),
    );
  }

  Widget _analysisRow(String label, double? percent, Color color) {
    final hasData = percent != null;
    final ratio = (percent ?? 0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              hasData ? '${(ratio * 100).toInt()}%' : '—',
              style: GoogleFonts.plusJakartaSans(
                color: hasData ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: hasData ? color : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: EmptyState(
        icon: Icons.insights_rounded,
        title: context.tr('no_stats_period'),
      ),
    );
  }
}
