import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});
  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  // Bulanan
  int _bulan = 2;
  int _tahun = 2026;
  // Pekanan — track current week index
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agt',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  DateTime _weekStart(int offset) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return monday.add(Duration(days: offset * 7));
  }

  DateTime _weekEnd(int offset) =>
      _weekStart(offset).add(const Duration(days: 4));

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.myAttendance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Statistik Absensi'),
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TabBar(
              controller: _tab,
              indicator: BoxDecoration(
                color: const Color(0xFFE31E24),
                borderRadius: BorderRadius.circular(16),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF90A4AE),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Bulanan'),
                Tab(text: 'Pekanan'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [_buildBulanan(records), _buildPekanan(records)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulanan(List records) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => setState(() {
                    _bulan--;
                    if (_bulan < 1) {
                      _bulan = 12;
                      _tahun--;
                    }
                  }),
                ),
                Text(
                  '${_months[_bulan - 1]} $_tahun',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
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
          const SizedBox(height: 12),
          _statsGrid(
            hadir: 17,
            telat: '7j 30m',
            lembur: '5j 30m',
            izin: 2,
            alpha: 1,
            totalJam: '141j',
          ),
        ],
      ),
    );
  }

  Widget _buildPekanan(List records) {
    final start = _weekStart(_weekOffset);
    final end = _weekEnd(_weekOffset);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Week navigator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.white),
                  onPressed: () => setState(() => _weekOffset--),
                ),
                Text(
                  '${_fmtDate(start)} – ${_fmtDate(end)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Colors.white),
                  onPressed: () => setState(() => _weekOffset++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _statsGrid(
            hadir: 4,
            telat: '3j 30m',
            lembur: '3j',
            izin: 1,
            alpha: 0,
            totalJam: '31j 30m',
          ),
          const SizedBox(height: 16),

          // Tanggal Izin section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F38),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tanggal Izin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _izinRow(
                  'Senin\n17 Feb',
                  'Sesuai Target ✓',
                  const Color(0xFF4CAF50),
                ),
                _divLine(),
                _izinRow(
                  'Selasa\n18 Feb',
                  'Tidak Sesuai ✗',
                  const Color(0xFFE31E24),
                ),
                _divLine(),
                _izinRow(
                  'Rabu\n19 Feb',
                  'Libur / Izin',
                  const Color(0xFF90A4AE),
                ),
                _divLine(),
                _izinRow(
                  'Kamis\n20 Feb',
                  'Sesuai Target ✓',
                  const Color(0xFF4CAF50),
                ),
                _divLine(),
                _izinRow(
                  'Jumat\n21 Feb',
                  'Sesuai Target ✓',
                  const Color(0xFF4CAF50),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsGrid({
    required int hadir,
    required String telat,
    required String lembur,
    required int izin,
    required int alpha,
    required String totalJam,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _box('$hadir', 'Hari hadir', const Color(0xFF4CAF50)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _box(telat, 'Total Jam Telat', const Color(0xFFE65100)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _box(lembur, 'Total Jam lembur', const Color(0xFF1565C0)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _box('$izin', 'Hari Izin', const Color(0xFFF57C00)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _box('$alpha', 'Alpha', const Color(0xFF212121))),
            const SizedBox(width: 8),
            Expanded(
              child: _box(totalJam, 'Total Jam Kerja', const Color(0xFF6A1B9A)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _box(String val, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    ),
  );

  Widget _izinRow(String date, String status, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          date,
          style: const TextStyle(
            color: Color(0xFF90A4AE),
            fontSize: 12,
            height: 1.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _divLine() => const Divider(color: Color(0xFF1E3A5F), height: 1);
}
