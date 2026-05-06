import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class NotificationPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color bgLight = Color(0xFFF8FAFC);

  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications;

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
          'NOTIFIKASI',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return FadeInUp(
                  key: ValueKey(notif.id),
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: _buildNotifCard(notif),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, color: const Color(0xFFCBD5E1), size: 64),
          const SizedBox(height: 16),
          Text('Tidak ada notifikasi', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNotifCard(AdminNotification notif) {
    bool isRead = notif.isRead;
    // Determine icon and color based on type
    IconData iconData;
    Color color;
    switch (notif.type) {
      case 'leave_request':
        iconData = Icons.description_rounded;
        color = const Color(0xFFD97706);
        break;
      case 'face_enrolled':
        iconData = Icons.face_retouching_natural_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'face_failed':
        iconData = Icons.error_outline_rounded;
        color = const Color(0xFFEF4444);
        break;
      case 'new_employee':
        iconData = Icons.person_add_rounded;
        color = jneBlue;
        break;
      case 'attendance_alert':
        iconData = Icons.warning_amber_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'meeting_reminder':
        iconData = Icons.event_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: isRead ? null : Border.all(color: jneBlue.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(notif.title, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(_formatTime(notif.createdAt), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notif.message, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, height: 1.4, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 2),
              width: 8, height: 8,
              decoration: const BoxDecoration(color: jneBlue, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
