
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../../widgets/package_loading.dart';
import '../attendance/dispute_submission_screen.dart';
import '../attendance/dispute_detail_screen.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  // Status negatif (telat/absen) memakai brand red yang sama dengan admin (#E31E24).
  static const Color zenRose = AppColors.brandRed;
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenSlate = Color(0xFF94A3B8);

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
    final records = provider.monthlyAttendance;
    final isLoading = provider.isLoadingHistory;
    final isDark = provider.isDarkMode;

    final presentCount = records.where((r) => r.status == 'present').length;
    final leaveCount = records.where((r) => r.status == 'leave').length;
    final lateCount = records.where((r) => r.status == 'late').length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : zenOffWhite,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        title: Text(
          context.tr('history_title'),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── FILTER SECTOR ──
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            decoration: const BoxDecoration(
              color: zenNavy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
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
                const SizedBox(height: 28),
                Row(
                  children: [
                    _headerStat(context.tr('stat_present'), presentCount.toString().padLeft(2, '0'), zenCyan),
                    const SizedBox(width: 12),
                    _headerStat(context.tr('leave_permit'), leaveCount.toString().padLeft(2, '0'), zenIndigo),
                    const SizedBox(width: 12),
                    _headerStat(context.tr('stat_late'), lateCount.toString().padLeft(2, '0'), zenRose),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                if (provider.hasPendingAttendance) _buildSyncBanner(context, provider),
                Expanded(
                  child: isLoading
                    ? const PackageLoading()
                    : records.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
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
          ),
        ],
      ),
    );
  }

   Widget _buildSyncBanner(BuildContext context, AppProvider provider) {
     return Container(
       margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
       decoration: BoxDecoration(
         color: Colors.amber.withValues(alpha: 0.06),
         borderRadius: BorderRadius.circular(20),
         border: Border.all(color: Colors.amber.withValues(alpha: 0.12)),
       ),
       child: Row(
         children: [
           const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 20),
           const SizedBox(width: 16),
           Expanded(
             child: Text(
               context.tr('unsynced_attendance'),
               style: GoogleFonts.plusJakartaSans(color: Colors.amber.shade900, fontSize: 12.5, fontWeight: FontWeight.w700),
             ),
           ),
           GestureDetector(
             onTap: _isSyncing ? null : () async {
               setState(() => _isSyncing = true);
               try {
                 await provider.syncPendingRecords();
               } finally {
                 if (mounted) setState(() => _isSyncing = false);
               }
             },
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
               decoration: BoxDecoration(
                 color: Colors.amber,
                 borderRadius: BorderRadius.circular(10),
               ),
               child: _isSyncing
                   ? const SizedBox(
                       height: 12, width: 12,
                       child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                     )
                   : Text('SYNC', style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
             ),
           ),
         ],
       ),
     );
   }

  Widget _buildDropdownMonth() {
    final months = AppStrings.months(context.read<AppProvider>().language);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedMonth,
          dropdownColor: zenNavy,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.white38),
          isExpanded: true,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedYear,
          dropdownColor: zenNavy,
          icon: const Icon(Icons.expand_more_rounded, color: Colors.white38),
          isExpanded: true,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.outfit(color: color, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 4),
            Text(label.toUpperCase(), style: GoogleFonts.outfit(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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
          Icon(Icons.inventory_2_outlined, color: zenSlate.withValues(alpha: 0.2), size: 64),
          const SizedBox(height: 20),
          Text(
            context.tr('no_history'),
            style: GoogleFonts.plusJakartaSans(color: zenSlate.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord r) {
    final pal = context.palette;
    final date = DateTime.tryParse(r.date) ?? DateTime.now();

    bool isLate = r.status == 'late';
    bool isAbsent = r.status == 'absent';
    bool isLeave = r.status == 'leave';
    
    Color statusColor = zenEmerald;
    String statusLabel = context.tr('status_present');

    if (isLate) { statusColor = zenRose; statusLabel = context.tr('status_late'); }
    if (isAbsent) { statusColor = zenRose; statusLabel = context.tr('status_absent_full'); }
    if (isLeave) { statusColor = zenIndigo; statusLabel = context.tr('status_leave_full'); }

    String checkInTime = r.checkIn?.time != null ? DateFormat('HH:mm').format(r.checkIn!.time!) : '--:--';
    String checkOutTime = r.checkOut?.time != null ? DateFormat('HH:mm').format(r.checkOut!.time!) : '--:--';

    final dispute = context.watch<AppProvider>().myDisputeRequests.where((d) => d.relatedAttendanceId == r.id).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(24),
      decoration: pal.cardDecoration(radius: 28),
      child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM yyyy', context.read<AppProvider>().language).format(date),
                        style: GoogleFonts.outfit(color: pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: zenIndigo, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            'JNE Martapura',
                            style: GoogleFonts.plusJakartaSans(color: zenSlate, fontSize: 11.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.plusJakartaSans(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: pal.border, thickness: 1, height: 1),
              ),
              Row(
                children: [
                  _timeBox(context.tr('check_in'), checkInTime, Icons.login_rounded, zenCyan, pal),
                  const Spacer(),
                  _timeBox(context.tr('check_out'), checkOutTime, Icons.logout_rounded, zenIndigo, pal),
                  const SizedBox(width: 12),
                  if (dispute == null && (isLate || isAbsent))
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DisputeSubmissionScreen(record: r)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: zenRose,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: zenRose.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Text(
                          context.tr('report_btn'),
                          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        if (dispute != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DisputeDetailScreen(dispute: dispute)),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DisputeSubmissionScreen(record: r)),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: dispute != null
                              ? (dispute.status == 'resolved' ? zenEmerald : (dispute.status == 'rejected' ? zenRose : Colors.amber)).withValues(alpha: 0.1)
                              : zenNavy.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          dispute != null
                              ? (dispute.status == 'resolved' ? Icons.check_circle_rounded : (dispute.status == 'rejected' ? Icons.cancel_rounded : Icons.pending_rounded))
                              : Icons.chevron_right_rounded,
                          color: dispute != null
                              ? (dispute.status == 'resolved' ? zenEmerald : (dispute.status == 'rejected' ? zenRose : Colors.amber))
                              : zenSlate,
                          size: 18
                        ),
                      ),
                    ),
                ],
              ),
              if (dispute != null) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DisputeDetailScreen(dispute: dispute)),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: pal.cardAlt,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              dispute.status == 'resolved' ? Icons.check_circle_rounded : dispute.status == 'rejected' ? Icons.cancel_rounded : Icons.report_problem_rounded,
                              size: 12,
                              color: dispute.status == 'resolved' ? zenEmerald : (dispute.status == 'rejected' ? zenRose : Colors.amber.shade700)
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${context.tr('dispute_status_prefix')}: ${_disputeStatusLabel(context, dispute.status)}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: dispute.status == 'resolved' ? zenEmerald : (dispute.status == 'rejected' ? zenRose : Colors.amber.shade900),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (dispute.needsUserConfirmation)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: zenEmerald,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr('confirm_badge'),
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1),
                                ),
                              ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, size: 14, color: zenSlate),
                          ],
                        ),
                        if (dispute.adminResponse != null && dispute.adminResponse!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            context.tr('tap_open_chat_admin'),
                            style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 10, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }

      String _disputeStatusLabel(BuildContext context, String status) {
        switch (status) {
          case 'resolved':
            return context.tr('ds_resolved');
          case 'rejected':
            return context.tr('ds_rejected');
          case 'in_review':
            return context.tr('ds_in_review');
          case 'reopened':
            return context.tr('ds_reopened');
          case 'closed':
            return context.tr('ds_closed');
          default:
            return context.tr('ds_pending');
        }
      }

      Widget _timeBox(String label, String time, IconData icon, Color color, AppPalette pal) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color.withValues(alpha: 0.6)),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontSize: 11.5, fontWeight: FontWeight.w600)
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              time,
              style: GoogleFonts.outfit(
                color: pal.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFeatures: [const FontFeature.tabularFigures()]
              ),
            ),
          ],
        );
      }
}