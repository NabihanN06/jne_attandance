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
  static const Color bgLight = Color(0xFFF8FAFC);

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

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'STATISTIK KERJA',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Tab Bar Section ──
          Container(
            color: jneBlue,
            padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                dividerColor: Colors.transparent,
                labelColor: jneBlue,
                unselectedLabelColor: Colors.white70,
                labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13),
                tabs: const [
                  Tab(text: 'BULANAN'),
                  Tab(text: 'PEKANAN'),
                ],
              ),
            ),
          ),

          Expanded(
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: jneBlue),
                  onPressed: () => setState(() {
                    _bulan--; if (_bulan < 1) { _bulan = 12; _tahun--; }
                  }),
                ),
                Text(
                  '${_months[_bulan - 1]} $_tahun'.toUpperCase(),
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: jneBlue),
                  onPressed: () => setState(() {
                    _bulan++; if (_bulan > 12) { _bulan = 1; _tahun++; }
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatBox(stats['present'], 'Hari Hadir', Icons.check_circle_rounded, Colors.green),
              _buildStatBox(stats['leaves'], 'Izin/Sakit', Icons.assignment_rounded, Colors.orange),
              _buildStatBox(stats['late'], 'Total Telat', Icons.alarm_rounded, jneRed),
              _buildStatBox(stats['hours'], 'Total Jam', Icons.timer_rounded, Colors.blue),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Detail Performance Card
          _buildPerformanceCard(stats['punctuality']),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return const Center(child: Text('Statistik Pekanan Segera Hadir'));
  }

  Widget _buildStatBox(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Spacer(),
          Text(value, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(double punctuality) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Analisis Kehadiran', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _buildPerformanceRow('Ketepatan Waktu', punctuality, Colors.green),
          const SizedBox(height: 12),
          _buildPerformanceRow('Kepatuhan Lokasi', 1.0, Colors.blue),
          const SizedBox(height: 12),
          _buildPerformanceRow('Efektivitas Jam', 0.9, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
            Text('${(percent * 100).toInt()}%', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
