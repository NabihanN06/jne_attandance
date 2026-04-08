import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const _months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
  static const _days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];

  String _fmtDate(DateTime d) => '${_days[d.weekday-1]}, ${d.day} ${_months[d.month-1]}';

  Color _statusColor(String status) {
    switch (status) {
      case 'Tepat Waktu': return const Color(0xFF4CAF50);
      case 'Terlambat': return const Color(0xFFE31E24);
      case 'Lembur': return const Color(0xFF1565C0);
      case 'Izin': return const Color(0xFFF57C00);
      case 'Alpha': return const Color(0xFF424242);
      default: return const Color(0xFF90A4AE);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.myAttendance;

    // Group by month
    final Map<String, List<AttendanceRecord>> grouped = {};
    for (final r in records) {
      final key = '${_months[r.date.month-1]} ${r.date.year}';
      grouped.putIfAbsent(key, () => []).add(r);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Riwayat Absensi'),
      ),
      body: records.isEmpty
          ? const Center(child: Text('Belum ada riwayat absensi', style: TextStyle(color: Color(0xFF90A4AE))))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                  decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(children: const [
                        Expanded(flex: 3, child: Text('Tanggal', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text('Absen Masuk', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text('Absen Pulang', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                    const Divider(color: Color(0xFF1E3A5F), height: 1),

                    for (final entry in grouped.entries) ...[
                      // Month separator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: const Color(0xFF162440),
                        child: Text('— ${entry.key} —',
                            style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
                      ),
                      for (int i = 0; i < entry.value.length; i++) ...[
                        _buildRow(entry.value[i]),
                        if (i < entry.value.length - 1) const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16, endIndent: 16),
                      ],
                    ],
                  ]),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _buildRow(AttendanceRecord r) {
    // Special full-width rows for Alpha / Izin
    if (r.checkInStatus == 'Alpha' || r.checkInStatus == 'Izin') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Expanded(flex: 3, child: Text(_fmtDate(r.date), style: const TextStyle(color: Colors.white, fontSize: 12))),
          Expanded(flex: 6, child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: r.checkInStatus == 'Izin' ? const Color(0xFFF57C00) : const Color(0xFF424242),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(r.checkInStatus, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          )),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(flex: 3, child: Text(_fmtDate(r.date), style: const TextStyle(color: Colors.white, fontSize: 12))),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.checkIn ?? '-', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 2),
          Text(r.checkInStatus, style: TextStyle(color: _statusColor(r.checkInStatus), fontSize: 10)),
        ])),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.checkOut ?? '-', style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 2),
          Text(r.checkOutStatus ?? 'Menunggu',
              style: TextStyle(color: _statusColor(r.checkOutStatus ?? 'Menunggu'), fontSize: 10)),
        ])),
      ]),
    );
  }
}