import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_strings.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});
  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  static const Color jneBlue = Color(
    0xFF4F46E5,
  ); // indigo accent (selaras tema app)
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF1F5F9);

  // ── Theme-aware colors (mendukung dark/light mode) ──
  bool get _isDark => context.read<AppProvider>().isDarkMode;
  Color get _card => _isDark ? const Color(0xFF15203A) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF0F172A);
  Color get _border =>
      _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9);

  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;

  /// % record yang check-in dalam radius kantor (distance <= officeRadius).
  /// Return null jika belum ada data, supaya UI bisa tampilkan "—" daripada
  /// angka palsu 100%.
  double? _locationCompliance(AppProvider p) {
    final monthRecords = p.myAttendance.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null &&
          d.month == _bulan &&
          d.year == _tahun &&
          r.checkIn != null;
    }).toList();
    if (monthRecords.isEmpty) return null;
    final radius = p.officeRadius;
    final inside = monthRecords.where((r) {
      final dist = r.checkIn?.distance;
      return dist != null && dist <= radius;
    }).length;
    return inside / monthRecords.length;
  }

  /// % record dengan check-in DAN check-out (jam kerja komplit).
  double? _hourEffectiveness(AppProvider p) {
    final monthRecords = p.myAttendance.where((r) {
      final d = DateTime.tryParse(r.date);
      return d != null && d.month == _bulan && d.year == _tahun;
    }).toList();
    if (monthRecords.isEmpty) return null;
    final complete = monthRecords
        .where((r) => r.checkIn != null && r.checkOut != null)
        .length;
    return complete / monthRecords.length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ──
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: _card,
            surfaceTintColor: _card,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                context.tr('work_statistics').toUpperCase(),
                style: GoogleFonts.outfit(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              background: Container(
                color: _card,
                child: Center(
                  child: Opacity(
                    opacity: _isDark ? 0.06 : 0.04,
                    child: Icon(
                      Icons.insights_rounded,
                      size: 200,
                      color: jneBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverFillRemaining(child: _buildMonthlyStats()),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    final provider = context.watch<AppProvider>();
    final stats = provider.getStatsForMonth(_bulan, _tahun);

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Month Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _border),
            boxShadow: _isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: jneBlue),
                onPressed: () => setState(() {
                  _bulan--;
                  if (_bulan < 1) {
                    _bulan = 12;
                    _tahun--;
                  }
                }),
              ),
              Text(
                '${AppStrings.months(provider.language)[_bulan - 1]} $_tahun'
                    .toUpperCase(),
                style: GoogleFonts.outfit(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: jneBlue),
                onPressed: () => setState(() {
                  _bulan++;
                  if (_bulan > 12) {
                    _bulan = 1;
                    _tahun++;
                  }
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Bento Grid for Stats
        LayoutBuilder(
          builder: (context, constraints) {
            final double spacing = 16;
            final double itemWidth = (constraints.maxWidth - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _buildBentoStat(
                  stats['present'],
                  context.tr('days_present'),
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                  itemWidth,
                ),
                _buildBentoStat(
                  stats['leaves'],
                  context.tr('leave_sick_label'),
                  Icons.assignment_rounded,
                  const Color(0xFFF59E0B),
                  itemWidth,
                ),
                _buildBentoStat(
                  stats['late'],
                  context.tr('late_minutes'),
                  Icons.alarm_rounded,
                  jneRed,
                  itemWidth,
                ),
                _buildBentoStat(
                  stats['hours'],
                  context.tr('total_hours'),
                  Icons.timer_rounded,
                  const Color(0xFF3B82F6),
                  itemWidth,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 32),

        // Performance Analysis Section
        _buildPerformanceAnalysis(
          punctuality: (stats['punctuality'] as num?)?.toDouble() ?? 0.0,
          locationCompliance: _locationCompliance(provider),
          hourEffectiveness: _hourEffectiveness(provider),
        ),
      ],
    );
  }

  Widget _buildBentoStat(
    String value,
    String label,
    IconData icon,
    Color color,
    double width,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _border),
        boxShadow: _isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: _isDark ? 0.16 : 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceAnalysis({
    required double punctuality,
    required double? locationCompliance,
    required double? hourEffectiveness,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                context.tr('performance_analysis').toUpperCase(),
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildAnalysisRow(
            context.tr('punctuality_label'),
            punctuality,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
          _buildAnalysisRow(
            context.tr('location_compliance'),
            locationCompliance,
            const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          _buildAnalysisRow(
            context.tr('hour_effectiveness'),
            hourEffectiveness,
            const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, double? percent, Color color) {
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
              style: GoogleFonts.outfit(
                color: hasData ? Colors.white : Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Lebar bar = persentase nyata via widthFactor (presisi apa pun
            // padding layar; sebelumnya pakai MediaQuery.width - angka-ajaib).
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerLeft,
              widthFactor: ratio,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: hasData ? color : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: hasData
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
