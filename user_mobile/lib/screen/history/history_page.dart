import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class HistoryPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);

  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.myAttendance;
    final presentCount = records.where((r) => r.checkInStatus == 'Tepat Waktu').length;
    final leaveCount = records.where((r) => r.checkInStatus == 'Izin').length;
    final lateCount = records.where((r) => r.checkInStatus == 'Terlambat').length;

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
          'RIWAYAT KEHADIRAN',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Header Summary ──
          Container(
            padding: const EdgeInsets.all(24),
            color: jneBlue,
            child: Row(
              children: [
                _headerStat('Hadir', presentCount.toString().padLeft(2, '0'), Colors.greenAccent),
                const SizedBox(width: 16),
                _headerStat('Izin', leaveCount.toString().padLeft(2, '0'), Colors.orangeAccent),
                const SizedBox(width: 16),
                _headerStat('Telat', lateCount.toString().padLeft(2, '0'), Colors.redAccent),
              ],
            ),
          ),

          Expanded(
            child: records.isEmpty
              ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return FadeInUp(
                        key: ValueKey(r.id),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: _buildAttendanceCard(context, r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            Text(label, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: const Color(0xFFCBD5E1), size: 64),
          const SizedBox(height: 16),
          Text('Belum ada riwayat absensi', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord r) {
    bool isLate = r.checkInStatus.contains('Lambat');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE, d MMM yyyy', 'id').format(r.date), style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
                  Text(r.shift, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: (isLate ? jneRed : Colors.green).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(r.checkInStatus.toUpperCase(), style: GoogleFonts.outfit(color: isLate ? jneRed : Colors.green, fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          Row(
            children: [
              _timeBox('Masuk', r.checkIn ?? '--:--', Icons.login_rounded, Colors.blue),
              const SizedBox(width: 24),
              _timeBox('Pulang', r.checkOut ?? '--:--', Icons.logout_rounded, Colors.orange),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String label, String time, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(time, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}