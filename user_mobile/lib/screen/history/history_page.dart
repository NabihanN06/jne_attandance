import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../widgets/package_loading.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Premium Color Palette
  static const Color zenCream   = Color(0xFFF9F7F2);
  static const Color zenNavy    = Color(0xFF0F172A);
  static const Color zenIndigo  = Color(0xFF4F46E5);
  static const Color zenAmber   = Color(0xFFF59E0B);
  static const Color zenSlate   = Color(0xFF64748B);
  static const Color zenRose    = Color(0xFFF43F5E);
  static const Color zenGreen   = Color(0xFF10B981);
  static const Color zenCyan    = Color(0xFF06B6D4);

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isSyncing = false;

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
    final records  = provider.monthlyAttendance;
    final isLoading = provider.isLoadingHistory;

    final presentCount = records.where((r) => r.status == 'present').length;
    final leaveCount   = records.where((r) => r.status == 'leave').length;
    final lateCount    = records.where((r) => r.status == 'late').length;

    return Scaffold(
      backgroundColor: zenCream,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── STATS SECTION (Bento Box) ──
          FadeInDown(
            duration: const Duration(milliseconds: 400),
            child: _buildHeaderSection(presentCount, leaveCount, lateCount),
          ),

          // ── LIST SECTION ──
          Expanded(
            child: Column(
              children: [
                if (provider.hasPendingAttendance) 
                  FadeIn(child: _buildSyncBanner(context, provider)),
                
                Expanded(
                  child: isLoading
                      ? const Center(child: PackageLoading())
                      : records.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                              physics: const BouncingScrollPhysics(),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final r = records[index];
                                return FadeInUp(
                                  duration: Duration(milliseconds: 300 + (index * 50)),
                                  child: _buildAttendanceCard(r),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: zenCream,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: const Icon(Icons.chevron_left_rounded, color: zenNavy, size: 28),
          ),
        ),
      ),
      title: Text(
        'RIWAYAT',
        style: GoogleFonts.outfit(
          color: zenNavy,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeaderSection(int present, int leave, int late) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: zenCream,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // Month/Year Selectors
          Row(
            children: [
              Expanded(child: _buildElegantDropdown(
                value: _selectedMonth,
                items: List.generate(12, (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text(_monthName(i + 1)),
                )),
                onChanged: (val) {
                  if (val != null) { setState(() => _selectedMonth = val); _onFilterChanged(); }
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildElegantDropdown(
                value: _selectedYear,
                items: List.generate(3, (i) => DateTime.now().year - i).map((y) => DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                )).toList(),
                onChanged: (val) {
                  if (val != null) { setState(() => _selectedYear = val); _onFilterChanged(); }
                },
              )),
            ],
          ),
          const SizedBox(height: 24),
          // Mini Stats
          Row(
            children: [
              _buildStatChip('Hadir', present, zenGreen),
              const SizedBox(width: 12),
              _buildStatChip('Izin', leave, zenIndigo),
              const SizedBox(width: 12),
              _buildStatChip('Late', late, zenRose),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: zenSlate, size: 20),
          isExpanded: true,
          style: GoogleFonts.outfit(color: zenNavy, fontSize: 14, fontWeight: FontWeight.w700),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Text(
              count.toString().padLeft(2, '0'),
              style: GoogleFonts.outfit(
                color: color, fontSize: 24, fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: zenSlate, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceRecord r) {
    final date = DateTime.tryParse(r.date) ?? DateTime.now();
    
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    
    switch (r.status) {
      case 'late':
        statusColor = zenRose; statusLabel = 'TERLAMBAT'; statusIcon = Icons.access_time_rounded;
        break;
      case 'absent':
        statusColor = zenRose; statusLabel = 'ABSEN'; statusIcon = Icons.close_rounded;
        break;
      case 'leave':
        statusColor = zenIndigo; statusLabel = 'IZIN/CUTI'; statusIcon = Icons.article_rounded;
        break;
      default:
        statusColor = zenGreen; statusLabel = 'HADIR'; statusIcon = Icons.verified_user_rounded;
    }

    final checkIn  = r.checkIn?.time  != null ? DateFormat('HH:mm').format(r.checkIn!.time!)  : '--:--';
    final checkOut = r.checkOut?.time != null ? DateFormat('HH:mm').format(r.checkOut!.time!) : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          // Top Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM yyyy', 'id').format(date).toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: zenNavy, fontSize: 13, fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        statusLabel,
                        style: GoogleFonts.outfit(
                          color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: zenNavy.withValues(alpha: 0.05)),
          // Time Info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo('IN', checkIn, zenCyan),
                _buildTimeInfo('OUT', checkOut, zenIndigo),
                if (r.checkIn?.time != null && r.checkOut?.time != null)
                  _buildDurationChip(r.checkIn!.time!, r.checkOut!.time!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: zenSlate, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: GoogleFonts.outfit(
            color: zenNavy, fontSize: 20, fontWeight: FontWeight.w900,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildDurationChip(DateTime cin, DateTime cout) {
    final dur = cout.difference(cin);
    final h = dur.inHours;
    final m = dur.inMinutes % 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: zenGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: zenGreen.withValues(alpha: 0.1)),
      ),
      child: Text(
        '${h}j ${m}m',
        style: GoogleFonts.outfit(color: zenGreen, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildSyncBanner(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: zenAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: zenAmber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, color: zenAmber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ada data yang belum sinkron',
              style: GoogleFonts.outfit(color: zenAmber, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: _isSyncing ? null : () async {
              setState(() => _isSyncing = true);
              await provider.syncPendingRecords();
              if (mounted) setState(() => _isSyncing = false);
            },
            child: Text('SYNC', style: GoogleFonts.outfit(color: zenAmber, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, color: zenSlate.withValues(alpha: 0.2), size: 80),
          const SizedBox(height: 24),
          Text(
            'Tidak Ada Riwayat',
            style: GoogleFonts.outfit(color: zenNavy, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan pilih bulan lain\natau lakukan absensi hari ini.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: zenSlate, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    return months[m - 1];
  }
}
