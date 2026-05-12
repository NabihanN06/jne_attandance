import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});
  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> with SingleTickerProviderStateMixin {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF9F7F2);

  late TabController _tab;
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ──
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'STATISTIK KERJA',
                style: GoogleFonts.outfit(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              background: Container(
                color: Colors.white,
                child: Center(
                  child: Opacity(
                    opacity: 0.03,
                    child: Icon(Icons.analytics_rounded, size: 200, color: jneBlue),
                  ),
                ),
              ),
            ),
          ),

          // ── Tab Bar ──
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TabBar(
                  controller: _tab,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: jneBlue,
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                  tabs: const [
                    Tab(text: 'BULANAN'),
                    Tab(text: 'PEKANAN'),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SliverFillRemaining(
            child: TabBarView(
              controller: _tab,
              children: [
                _buildMonthlyStats(),
                _buildWeeklyStats(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyStats() {
    final provider = context.watch<AppProvider>();
    final stats = provider.getStatsForMonth(_bulan, _tahun);

    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Month Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: jneBlue),
                onPressed: () => setState(() {
                  _bulan--; if (_bulan < 1) { _bulan = 12; _tahun--; }
                }),
              ),
              Text(
                '${_months[_bulan - 1]} $_tahun'.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: const Color(0xFF1E293B),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: jneBlue),
                onPressed: () => setState(() {
                  _bulan++; if (_bulan > 12) { _bulan = 1; _tahun++; }
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
                _buildBentoStat(stats['present'], 'Hari Hadir', Icons.check_circle_rounded, const Color(0xFF10B981), itemWidth),
                _buildBentoStat(stats['leaves'], 'Izin/Sakit', Icons.assignment_rounded, const Color(0xFFF59E0B), itemWidth),
                _buildBentoStat(stats['late'], 'Menit Telat', Icons.alarm_rounded, jneRed, itemWidth),
                _buildBentoStat(stats['hours'], 'Total Jam', Icons.timer_rounded, const Color(0xFF3B82F6), itemWidth),
              ],
            );
          },
        ),
        
        const SizedBox(height: 32),
        
        // Performance Analysis Section
        _buildPerformanceAnalysis(stats['punctuality']),
      ],
    );
  }

  Widget _buildWeeklyStats() {
    final provider = context.watch<AppProvider>();
    final records = provider.monthlyAttendance;

    // Get current week (Mon-Sun)
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    final dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Count per-day status from loaded records
    Map<String, String?> dayStatus = {};
    for (final day in weekDays) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final match = records.where((r) => r.date == key).firstOrNull;
      dayStatus[key] = match?.status;
    }

    final presentCount = dayStatus.values.where((s) => s == 'present' || s == 'overtime').length;
    final lateCount = dayStatus.values.where((s) => s == 'late').length;
    int absentCount = 0;
    for (final day in weekDays) {
      final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (dayStatus[key] == null && day.isBefore(DateTime(now.year, now.month, now.day))) absentCount++;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Week Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_view_week_rounded, color: jneBlue, size: 18),
              const SizedBox(width: 8),
              Text(
                '${weekDays.first.day}/${weekDays.first.month} – ${weekDays.last.day}/${weekDays.last.month}/${weekDays.last.year}',
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Day bars
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('KEHADIRAN MINGGU INI', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final day = weekDays[i];
                  final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final status = dayStatus[key];
                  final isPast = day.isBefore(DateTime(now.year, now.month, now.day));
                  final isToday = day.year == now.year && day.month == now.month && day.day == now.day;
                  final isFuture = day.isAfter(now);

                  Color barColor;
                  double barHeight;
                  if (isFuture) {
                    barColor = const Color(0xFFF1F5F9);
                    barHeight = 30;
                  } else if (status == 'present' || status == 'overtime') {
                    barColor = const Color(0xFF10B981);
                    barHeight = 70;
                  } else if (status == 'late') {
                    barColor = const Color(0xFFF59E0B);
                    barHeight = 50;
                  } else if (status == 'leave') {
                    barColor = const Color(0xFF3B82F6);
                    barHeight = 40;
                  } else if (isPast) {
                    barColor = jneRed.withValues(alpha: 0.6);
                    barHeight = 20;
                  } else {
                    barColor = const Color(0xFFF1F5F9);
                    barHeight = 30;
                  }

                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 400 + (i * 80)),
                        curve: Curves.easeOutBack,
                        width: 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isToday ? Border.all(color: jneBlue, width: 2) : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dayLabels[i],
                        style: GoogleFonts.outfit(
                          color: isToday ? jneBlue : const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Legend
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegend('Hadir', const Color(0xFF10B981)),
                  _buildLegend('Terlambat', const Color(0xFFF59E0B)),
                  _buildLegend('Izin', const Color(0xFF3B82F6)),
                  _buildLegend('Absen', jneRed.withValues(alpha: 0.6)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Weekly Summary
        Row(
          children: [
            Expanded(child: _buildWeekCard('$presentCount', 'Hari Hadir', const Color(0xFF10B981), Icons.check_circle_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildWeekCard('$lateCount', 'Terlambat', const Color(0xFFF59E0B), Icons.alarm_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildWeekCard('$absentCount', 'Absen', jneRed, Icons.cancel_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildWeekCard(String value, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.outfit(color: const Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildBentoStat(String value, String label, IconData icon, Color color, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
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

  Widget _buildPerformanceAnalysis(double punctuality) {
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: 12),
              Text(
                'ANALISIS PERFORMA',
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
          _buildAnalysisRow('Ketepatan Waktu', punctuality, const Color(0xFF10B981)),
          const SizedBox(height: 24),
          _buildAnalysisRow('Kepatuhan Lokasi', 1.0, const Color(0xFF3B82F6)),
          const SizedBox(height: 24),
          _buildAnalysisRow('Efektivitas Jam', 0.92, const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, double percent, Color color) {
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
              '${(percent * 100).toInt()}%',
              style: GoogleFonts.outfit(
                color: Colors.white,
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
            AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              height: 6,
              width: (MediaQuery.of(context).size.width - 112) * percent,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
