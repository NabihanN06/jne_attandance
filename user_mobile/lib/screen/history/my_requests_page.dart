import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_strings.dart';
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
          context.tr('request_center'),
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
          tabs: [
            Tab(text: context.tr('nav_leave')),
            Tab(text: context.tr('overtime_word')),
            Tab(text: context.tr('complaint_word')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList<LeaveRequest>(
            items: p.myLeaveRequests,
            emptyLabel: context.tr('empty_leave_req'),
            onCancel: (req) => p.cancelLeaveRequest(req.id),
          ),
          _buildRequestList<OvertimeRequest>(
            items: p.myOvertimeRequests,
            emptyLabel: context.tr('empty_ot_req'),
            onCancel: (req) => p.cancelOvertimeRequest(req.id),
          ),
          _buildRequestList<DisputeRequest>(
            items: p.myDisputeRequests,
            emptyLabel: context.tr('empty_complaint'),
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
        title: context.tr('no_requests_yet'),
        subtitle: '${context.tr('list_prefix')} $emptyLabel ${context.tr('list_suffix')}',
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
    final okMsg = context.tr('request_cancelled');
    final failPre = context.tr('fail_prefix');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: pal.card,
        surfaceTintColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(context.tr('cancel_request_q'),
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800, fontSize: 18, color: pal.textPrimary)),
        content: Text(context.tr('cancel_request_desc'),
            style: GoogleFonts.plusJakartaSans(fontSize: 14, color: pal.textSub, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('no'),
                style: GoogleFonts.plusJakartaSans(color: pal.textSub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(context.tr('yes_cancel'),
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await cancelFn(item);
        if (mounted) showAppSnack(context, okMsg, color: AppColors.green);
      } catch (e) {
        if (mounted) {
          showAppSnack(context, '$failPre: ${e.toString().replaceAll('Exception: ', '')}',
              color: AppColors.brandRed);
        }
      }
    }
  }
}

String _leaveTypeLabel(BuildContext context, String type) {
  switch (type) {
    case 'annual': return context.tr('leave_annual');
    case 'sick': return context.tr('lt_sick');
    case 'permission': return context.tr('lt_permission');
    case 'personal': return context.tr('lt_personal');
    case 'urgent': return context.tr('lt_family');
    default: return type.toUpperCase();
  }
}

String _statusLabel(BuildContext context, String s) {
  switch (s) {
    case 'approved': return context.tr('st_approved');
    case 'rejected': return context.tr('st_rejected');
    case 'resolved': return context.tr('st_resolved');
    case 'pending': return context.tr('st_pending');
    case 'in_review': return context.tr('st_in_review');
    case 'reopened': return context.tr('st_reopened');
    case 'closed': return context.tr('st_closed');
    case 'cancelled': return context.tr('st_cancelled');
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
    final lang = context.read<AppProvider>().language;
    String title = '';
    String subtitle = '';
    String status = '';
    String dateStr = '';
    bool isDispute = false;

    const fmt = 'dd MMM yyyy';
    if (item is LeaveRequest) {
      final req = item as LeaveRequest;
      title = '${context.tr('nav_leave')}: ${_leaveTypeLabel(context, req.type)}';
      subtitle = req.reason;
      status = req.status;
      final sameDay = req.startDate.year == req.endDate.year &&
          req.startDate.month == req.endDate.month &&
          req.startDate.day == req.endDate.day;
      dateStr = sameDay
          ? DateFormat(fmt, lang).format(req.startDate)
          : '${DateFormat('dd MMM', lang).format(req.startDate)} – ${DateFormat(fmt, lang).format(req.endDate)}';
    } else if (item is OvertimeRequest) {
      final req = item as OvertimeRequest;
      title = '${context.tr('overtime_word')} ${req.overtimeHours} ${context.tr('hours_word')}';
      subtitle = req.reason;
      status = req.status;
      dateStr = DateFormat(fmt, lang).format(DateTime.tryParse(req.date) ?? DateTime.now());
    } else if (item is DisputeRequest) {
      final req = item as DisputeRequest;
      isDispute = true;
      title = '${context.tr('complaint_word')}: ${req.title}';
      subtitle = req.description;
      status = req.status;
      dateStr = DateFormat(fmt, lang).format(req.createdAt);
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
                        _statusLabel(context, status),
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
                      Text(context.tr('tap_see_admin_reply'),
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
                        context.tr('withdraw_request'),
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
