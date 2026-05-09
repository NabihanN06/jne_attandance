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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.query_stats_rounded, size: 64, color: jneBlue.withValues(alpha: 0.2)),
        const SizedBox(height: 24),
        Text(
          'ANALISIS PEKANAN',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2),
        ),
        const SizedBox(height: 8),
        Text(
          'Modul sedang dalam pengembangan.',
          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
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
