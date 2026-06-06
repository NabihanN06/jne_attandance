import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../attendance/dispute_detail_screen.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final pal = context.palette;

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          'Pusat Pengajuan',
          style: GoogleFonts.plusJakartaSans(
              color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.jneOrange,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600),
          unselectedLabelColor: pal.textFaint,
          labelColor: pal.textPrimary,
          tabs: const [
            Tab(text: 'Cuti'),
            Tab(text: 'Lembur'),
            Tab(text: 'Komplain'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList<LeaveRequest>(
            items: p.myLeaveRequests,
            emptyLabel: 'pengajuan cuti',
            onCancel: (req) => p.cancelLeaveRequest(req.id),
          ),
          _buildRequestList<OvertimeRequest>(
            items: p.myOvertimeRequests,
            emptyLabel: 'pengajuan lembur',
            onCancel: (req) => p.cancelOvertimeRequest(req.id),
          ),
          _buildRequestList<DisputeRequest>(
            items: p.myDisputeRequests,
            emptyLabel: 'komplain',
            onCancel: null, // Komplain tidak bisa dibatalkan
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList<T>({
    required List<T> items,
    required String emptyLabel,
    required Future<void> Function(T)? onCancel,
  }) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.inbox_rounded,
        title: 'Belum Ada Pengajuan',
        subtitle: 'Daftar $emptyLabel kamu akan muncul & terpantau statusnya di sini.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 350),
          delay: Duration(milliseconds: index * 40),
          child: _RequestCard(
            item: item,
            onTap: item is DisputeRequest
                ? () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DisputeDetailScreen(dispute: item)),
                    )
                : null,
            onCancel: onCancel != null ? () => _handleCancel(item, onCancel) : null,
          ),
        );
      },
    );
  }

  Future<void> _handleCancel<T>(T item, Future<void> Function(T) cancelFn) async {
    final pal = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Batalkan Pengajuan?',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18, color: pal.textPrimary)),
        content: Text('Yakin ingin menarik pengajuan ini? Tindakan tidak bisa dibatalkan.',
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: pal.textSub, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tidak',
                style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Ya, Batalkan',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await cancelFn(item);
        if (mounted) showAppSnack(context, 'Pengajuan berhasil dibatalkan', color: AppColors.green);
      } catch (e) {
        if (mounted) {
          showAppSnack(context, 'Gagal: ${e.toString().replaceAll('Exception: ', '')}',
              color: AppColors.brandRed);
        }
      }
    }
  }
}

String _leaveTypeLabel(String type) {
  switch (type) {
    case 'annual': return 'Cuti Tahunan';
    case 'sick': return 'Sakit';
    case 'permission': return 'Izin Mendadak';
    case 'personal': return 'Keperluan Pribadi';
    case 'urgent': return 'Keperluan Keluarga';
    default: return type.toUpperCase();
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'approved': return 'Disetujui';
    case 'rejected': return 'Ditolak';
    case 'resolved': return 'Selesai';
    case 'pending': return 'Menunggu';
    case 'in_review': return 'Ditinjau';
    case 'reopened': return 'Dibuka Lagi';
    case 'closed': return 'Ditutup';
    case 'cancelled': return 'Dibatalkan';
    default: return s.toUpperCase();
  }
}

Color _statusColor(String s) {
  if (s == 'approved' || s == 'resolved') return AppColors.green;
  if (s == 'rejected') return AppColors.brandRed;
  if (s == 'in_review' || s == 'reopened') return AppColors.blue;
  return AppColors.amber; // pending & lainnya
}

class _RequestCard<T> extends StatelessWidget {
  final T item;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const _RequestCard({required this.item, this.onTap, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    String title = '';
    String subtitle = '';
    String status = '';
    String dateStr = '';
    bool isDispute = false;

    const fmt = 'dd MMM yyyy';
    if (item is LeaveRequest) {
      final req = item as LeaveRequest;
      title = 'Cuti: ${_leaveTypeLabel(req.type)}';
      subtitle = req.reason;
      status = req.status;
      final sameDay = req.startDate.year == req.endDate.year &&
          req.startDate.month == req.endDate.month &&
          req.startDate.day == req.endDate.day;
      dateStr = sameDay
          ? DateFormat(fmt, 'id').format(req.startDate)
          : '${DateFormat('dd MMM', 'id').format(req.startDate)} – ${DateFormat(fmt, 'id').format(req.endDate)}';
    } else if (item is OvertimeRequest) {
      final req = item as OvertimeRequest;
      title = 'Lembur ${req.overtimeHours} jam';
      subtitle = req.reason;
      status = req.status;
      dateStr = DateFormat(fmt, 'id').format(DateTime.tryParse(req.date) ?? DateTime.now());
    } else if (item is DisputeRequest) {
      final req = item as DisputeRequest;
      isDispute = true;
      title = 'Komplain: ${req.title}';
      subtitle = req.description;
      status = req.status;
      dateStr = DateFormat(fmt, 'id').format(req.createdAt);
    }

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: pal.cardDecoration(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                          color: pal.textFaint, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: GoogleFonts.plusJakartaSans(
                            color: statusColor, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textPrimary, fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textSub, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4),
                ),
                if (isDispute) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.forum_rounded, size: 13, color: AppColors.blue),
                      const SizedBox(width: 5),
                      Text('Ketuk untuk lihat balasan admin',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
                if (status == 'pending' && onCancel != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: AppRowDivider(indent: 0),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.brandRed),
                      label: Text(
                        'Tarik Pengajuan',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppColors.brandRed, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.brandRed.withValues(alpha: 0.06),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
