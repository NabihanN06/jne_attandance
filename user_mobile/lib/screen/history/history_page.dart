import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color slate950 = Color(0xFF0F172A);

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().fetchAttendanceByMonth(_selectedMonth, _selectedYear);
    });
  }

  void _onFilterChanged() {
    context.read<AppProvider>().fetchAttendanceByMonth(_selectedMonth, _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.monthlyAttendance;
    final isLoading = provider.isLoadingHistory;

    final presentCount = records.where((r) => r.checkInStatus == 'Tepat Waktu').length;
    final leaveCount = records.where((r) => r.checkInStatus == 'Izin').length;
    final lateCount = records.where((r) => r.checkInStatus == 'Terlambat').length;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: slate950,
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
          // ── Filter Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            decoration: const BoxDecoration(
              color: slate950,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDropdownMonth()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdownYear()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _headerStat('Hadir', presentCount.toString().padLeft(2, '0'), Colors.greenAccent),
                    const SizedBox(width: 12),
                    _headerStat('Izin', leaveCount.toString().padLeft(2, '0'), Colors.orangeAccent),
                    const SizedBox(width: 12),
                    _headerStat('Telat', lateCount.toString().padLeft(2, '0'), Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: isLoading
              ? const Center(child: CircularProgressIndicator(color: jneRed))
              : records.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    physics: const BouncingScrollPhysics(),
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return FadeInUp(
                        key: ValueKey(r.id),
                        duration: Duration(milliseconds: 300 + (index * 30)),
                        child: _buildAttendanceCard(context, r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownMonth() {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          dropdownColor: slate950,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          isExpanded: true,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedMonth = val);
              _onFilterChanged();
            }
          },
          items: List.generate(12, (index) => DropdownMenuItem(
            value: index + 1,
            child: Text(months[index]),
          )),
        ),
      ),
    );
  }

  Widget _buildDropdownYear() {
    final currentYear = DateTime.now().year;
    final years = List.generate(3, (index) => currentYear - index);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: slate950,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          isExpanded: true,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedYear = val);
              _onFilterChanged();
            }
          },
          items: years.map((y) => DropdownMenuItem(
            value: y,
            child: Text(y.toString()),
          )).toList(),
        ),
      ),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
          Text('Tidak ada riwayat di bulan ini', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord r) {
    bool isLate = r.checkInStatus == 'Terlambat';
    bool isAbsent = r.checkInStatus == 'Alpha';
    bool isLeave = r.checkInStatus == 'Izin';
    
    Color statusColor = Colors.green;
    if (isLate) statusColor = Colors.orange;
    if (isAbsent) statusColor = jneRed;
    if (isLeave) statusColor = Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, d MMM yyyy', 'id').format(r.date),
                    style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    r.shift,
                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.checkInStatus.toUpperCase(),
                  style: GoogleFonts.outfit(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          Row(
            children: [
              _timeBox('MASUK', r.checkIn ?? '--:--', Icons.login_rounded, Colors.blue),
              const Spacer(),
              const SizedBox(
                height: 30,
                child: VerticalDivider(color: Color(0xFFF1F5F9), width: 1),
              ),
              const Spacer(),
              _timeBox('PULANG', r.checkOut ?? '--:--', Icons.logout_rounded, Colors.orange),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: const Color(0xFFCBD5E1), size: 14),
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
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}