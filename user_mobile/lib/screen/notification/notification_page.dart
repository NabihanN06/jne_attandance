// ─────────────────────────────────────────────
// notification_page.dart - Smart inbox dengan tips otomatis + grouping
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const Color jneBlue = Color(0xFF005596);
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenAmber = Color(0xFFF59E0B);
  static const Color zenSlate = Color(0xFF94A3B8);
  static const Color bgLight = Color(0xFFF8FAFC);

  // Filter: 'all' | 'unread'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final allNotifications = provider.notifications;
    final unread = provider.unreadNotificationCount;
    final tips = provider.smartTips;
    final isDark = provider.isDarkMode;

    final filteredNotifications = _filter == 'unread'
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    final grouped = _groupByDate(filteredNotifications);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          SliverAppBar(
            backgroundColor: jneBlue,
            elevation: 0,
            pinned: true,
            expandedHeight: 100,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(bottom: 16),
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NOTIFIKASI',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  if (unread > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '$unread belum dibaca',
                        style: GoogleFonts.outfit(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              if (unread > 0)
                IconButton(
                  tooltip: 'Tandai semua dibaca',
                  icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await provider.markAllNotificationsRead();
                    messenger.showSnackBar(SnackBar(
                      content: Text('Semua ditandai dibaca', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ));
                  },
                ),
            ],
          ),

          // ── Filter Chips ──
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  _filterChip('Semua', 'all', allNotifications.length),
                  const SizedBox(width: 8),
                  _filterChip('Belum Dibaca', 'unread', unread),
                ],
              ),
            ),
          ),

          // ── Smart Tips (selalu di atas) ──
          if (tips.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    if (i == 0) return _smartSectionHeader(tips.length);
                    final tip = tips[i - 1];
                    return FadeInRight(
                      duration: Duration(milliseconds: 250 + (i * 50)),
                      child: _tipCard(tip),
                    );
                  },
                  childCount: tips.length + 1,
                ),
              ),
            ),

          // ── Notifications by date group ──
          if (grouped.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(),
            )
          else
            ..._buildGroupedSlivers(grouped, provider),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? jneBlue : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? jneBlue : const Color(0xFFE2E8F0)),
          boxShadow: active
              ? [BoxShadow(color: jneBlue.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? Colors.white : zenNavy,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withValues(alpha: 0.25) : zenSlate.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    color: active ? Colors.white : zenSlate,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smartSectionHeader(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: zenAmber, size: 16),
          const SizedBox(width: 8),
          Text(
            'UNTUK ANDA',
            style: GoogleFonts.outfit(color: zenNavy, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: zenAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(color: zenAmber, fontSize: 9, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard(SmartTip tip) {
    final color = _severityColor(tip.severity);
    final icon = _iconForName(tip.icon);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.2),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tip.title,
                        style: GoogleFonts.outfit(color: zenNavy, fontSize: 13, fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (tip.severity == 'urgent')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: zenRose,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PENTING',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  tip.message,
                  style: GoogleFonts.outfit(color: zenSlate, fontSize: 11, fontWeight: FontWeight.w600, height: 1.4),
                ),
                if (tip.action.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _handleTipAction(tip.action),
                    child: Text(
                      _actionLabel(tip.action),
                      style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(String action) {
    switch (action) {
      case 'attendance': return 'Absen Sekarang →';
      case 'leave_balance': return 'Lihat Saldo Cuti →';
      case 'dispute': return 'Buka Komplain →';
      case 'statistic': return 'Lihat Statistik →';
      default: return 'Buka →';
    }
  }

  void _handleTipAction(String action) {
    switch (action) {
      case 'attendance':
        Navigator.pushNamed(context, '/attendance');
        break;
      case 'leave_balance':
        Navigator.pushNamed(context, '/leave');
        break;
      case 'dispute':
        Navigator.pushNamed(context, '/my_requests');
        break;
      case 'statistic':
        Navigator.pushNamed(context, '/statistic');
        break;
    }
  }

  // ── Grouping by date ──
  Map<String, List<AdminNotification>> _groupByDate(List<AdminNotification> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final result = <String, List<AdminNotification>>{};
    for (final n in list) {
      final dt = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      String key;
      if (dt == today) {
        key = 'Hari Ini';
      } else if (dt == yesterday) {
        key = 'Kemarin';
      } else if (dt.isAfter(weekAgo)) {
        key = 'Minggu Ini';
      } else {
        key = 'Lebih Lama';
      }
      (result[key] ??= []).add(n);
    }
    return result;
  }

  List<Widget> _buildGroupedSlivers(Map<String, List<AdminNotification>> grouped, AppProvider provider) {
    final order = ['Hari Ini', 'Kemarin', 'Minggu Ini', 'Lebih Lama'];
    final out = <Widget>[];
    for (final key in order) {
      final items = grouped[key];
      if (items == null || items.isEmpty) continue;
      out.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Text(
            key.toUpperCase(),
            style: GoogleFonts.outfit(color: zenSlate, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ),
      ));
      out.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final notif = items[i];
              return FadeInUp(
                key: ValueKey(notif.id),
                duration: Duration(milliseconds: 200 + (i * 50)),
                child: _buildNotifCard(notif, provider),
              );
            },
            childCount: items.length,
          ),
        ),
      ));
    }
    return out;
  }

  Widget _buildEmptyState() {
    final isFiltered = _filter == 'unread';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88, height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: jneBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.mark_email_read_rounded : Icons.notifications_off_rounded,
                color: jneBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered ? 'Semua sudah dibaca' : 'Tidak ada notifikasi',
              style: GoogleFonts.outfit(color: zenNavy, fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              isFiltered
                  ? 'Inbox Anda bersih. Saatnya fokus kerja!'
                  : 'Notifikasi penting akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: zenSlate, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifCard(AdminNotification notif, AppProvider provider) {
    final isRead = notif.isRead;
    final iconData = _iconForType(notif.type);
    final color = _colorForType(notif.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (!notif.isRead) {
              await provider.markNotificationAsRead(notif.id);
            }
          },
          onLongPress: () => _showNotifActions(notif, provider),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isRead ? const Color(0xFFE2E8F0) : color.withValues(alpha: 0.25),
                width: isRead ? 1 : 1.2,
              ),
              boxShadow: isRead
                  ? null
                  : [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 42, height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(iconData, color: color, size: 20),
                    ),
                    if (!isRead)
                      Positioned(
                        right: 0, top: 0,
                        child: Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            color: zenRose,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: zenNavy,
                                fontSize: 13,
                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(notif.createdAt),
                            style: GoogleFonts.outfit(color: zenSlate, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          color: zenSlate,
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showNotifActions(AdminNotification notif, AppProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: zenSlate.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (!notif.isRead)
                ListTile(
                  leading: const Icon(Icons.mark_email_read_rounded, color: zenIndigo),
                  title: Text('Tandai sudah dibaca', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: zenNavy)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await provider.markNotificationAsRead(notif.id);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.close_rounded, color: zenSlate),
                title: Text('Tutup', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: zenSlate)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Icon & color mapping ──
  IconData _iconForType(String type) {
    switch (type) {
      case 'leave_request': return Icons.event_busy_rounded;
      case 'face_enrolled': return Icons.face_retouching_natural_rounded;
      case 'face_failed': return Icons.error_outline_rounded;
      case 'new_employee': return Icons.person_add_rounded;
      case 'attendance_alert': return Icons.warning_amber_rounded;
      case 'meeting_reminder': return Icons.event_rounded;
      case 'dispute':
      case 'dispute_response':
      case 'dispute_closed':
      case 'dispute_reopened':
      case 'dispute_reply':
        return Icons.report_problem_rounded;
      case 'sos_alert': return Icons.sos_rounded;
      case 'broadcast': return Icons.campaign_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'leave_request': return zenAmber;
      case 'face_enrolled': return zenEmerald;
      case 'face_failed': return zenRose;
      case 'new_employee': return jneBlue;
      case 'attendance_alert': return zenAmber;
      case 'meeting_reminder': return zenIndigo;
      case 'dispute':
      case 'dispute_response':
      case 'dispute_closed':
      case 'dispute_reopened':
      case 'dispute_reply':
        return const Color(0xFF8B5CF6);
      case 'sos_alert': return zenRose;
      case 'broadcast': return jneBlue;
      default: return zenSlate;
    }
  }

  Color _severityColor(String s) {
    switch (s) {
      case 'urgent': return zenRose;
      case 'warning': return zenAmber;
      case 'success': return zenEmerald;
      case 'info':
      default: return zenIndigo;
    }
  }

  IconData _iconForName(String name) {
    switch (name) {
      case 'access_time': return Icons.access_time_rounded;
      case 'logout': return Icons.logout_rounded;
      case 'beach_access': return Icons.beach_access_rounded;
      case 'task_alt': return Icons.task_alt_rounded;
      case 'trending_down': return Icons.trending_down_rounded;
      case 'emoji_events': return Icons.emoji_events_rounded;
      default: return Icons.lightbulb_rounded;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}j';
    if (diff.inDays < 7) return '${diff.inDays}h';
    return '${(diff.inDays / 7).floor()}mg';
  }
}
