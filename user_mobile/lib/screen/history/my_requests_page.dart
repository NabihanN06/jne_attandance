
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color zenNavy = Color(0xFF121826);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenSlate = Color(0xFF94A3B8);

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

    return Scaffold(
      backgroundColor: zenOffWhite,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
        title: Text(
          'REQUEST CENTER',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: zenCyan,
          indicatorWeight: 4,
          labelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          unselectedLabelColor: Colors.white38,
          labelColor: zenCyan,
          tabs: const [
            Tab(text: 'LEAVES'),
            Tab(text: 'OVERTIME'),
            Tab(text: 'DISPUTES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList<LeaveRequest>(
            items: p.myLeaveRequests,
            onCancel: (req) => p.cancelLeaveRequest(req.id),
          ),
          _buildRequestList<OvertimeRequest>(
            items: p.myOvertimeRequests,
            onCancel: (req) => p.cancelOvertimeRequest(req.id),
          ),
          _buildRequestList<DisputeRequest>(
            items: p.myDisputeRequests,
            onCancel: null, // Disputes can't be cancelled for now
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList<T>({
    required List<T> items,
    required Future<void> Function(T)? onCancel,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: zenSlate.withValues(alpha: 0.2), size: 64),
            const SizedBox(height: 16),
            Text(
              'NO ACTIVE REQUESTS',
              style: GoogleFonts.outfit(color: zenSlate.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 400),
          delay: Duration(milliseconds: index * 50),
          child: _RequestCard(
            item: item,
            onCancel: onCancel != null ? () => _handleCancel(item, onCancel) : null,
          ),
        );
      },
    );
  }

  Future<void> _handleCancel<T>(T item, Future<void> Function(T) cancelFn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('CANCEL REQUEST?', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('Are you sure you want to withdraw this request?', style: GoogleFonts.plusJakartaSans(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: zenRose),
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await cancelFn(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request cancelled successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
        }
      }
    }
  }
}

class _RequestCard<T> extends StatelessWidget {
  final T item;
  final VoidCallback? onCancel;

  const _RequestCard({required this.item, this.onCancel});

  @override
  Widget build(BuildContext context) {
    String title = '';
    String subtitle = '';
    String status = '';
    String dateStr = '';
    Color statusColor = Colors.amber;

    if (item is LeaveRequest) {
      final req = item as LeaveRequest;
      title = 'Leave: ${req.type.toUpperCase()}';
      subtitle = req.reason;
      status = req.status;
      dateStr = '${DateFormat('dd MMM').format(req.startDate)} - ${DateFormat('dd MMM yyyy').format(req.endDate)}';
    } else if (item is OvertimeRequest) {
      final req = item as OvertimeRequest;
      title = 'Overtime';
      subtitle = req.reason;
      status = req.status;
      dateStr = DateFormat('EEEE, dd MMM yyyy').format(DateTime.tryParse(req.date) ?? DateTime.now());
    } else if (item is DisputeRequest) {
      final req = item as DisputeRequest;
      title = 'Complaint / Dispute';
      subtitle = req.description;
      status = req.status;
      dateStr = DateFormat('dd MMM yyyy HH:mm').format(req.createdAt);
    }

    statusColor = status == 'approved' || status == 'resolved' ? const Color(0xFF10B981) : 
                  status == 'rejected' ? const Color(0xFFF43F5E) : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF121826).withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
        border: Border.all(color: const Color(0xFF121826).withValues(alpha: 0.02)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr.toUpperCase(),
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.outfit(color: statusColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(color: const Color(0xFF121826), fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
          ),
          if (status == 'pending' && onCancel != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF8FAFC)),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFF43F5E)),
                label: Text(
                  'WITHDRAW REQUEST',
                  style: GoogleFonts.outfit(color: const Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFFF43F5E).withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
