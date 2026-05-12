import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.notifications;
    final isDark = provider.isDarkMode;

    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFEFF6FF);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final appBarBg = isDark ? const Color(0xFF0B1120) : const Color(0xFF2563EB);
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final timeColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final unreadBorderColor = isDark
        ? const Color(0xFF2563EB).withValues(alpha: 0.35)
        : const Color(0xFF2563EB).withValues(alpha: 0.18);
    final emptyIconColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    final emptyTextColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifikasi',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(emptyIconColor, emptyTextColor)
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return FadeInUp(
                  key: ValueKey(notif.id),
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  child: _buildNotifCard(
                    notif,
                    cardBg: cardBg,
                    titleColor: titleColor,
                    subtitleColor: subtitleColor,
                    timeColor: timeColor,
                    unreadBorderColor: unreadBorderColor,
                    isDark: isDark,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(Color iconColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, color: iconColor, size: 64),
          const SizedBox(height: 16),
          Text(
            'Tidak ada notifikasi',
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifCard(
    AdminNotification notif, {
    required Color cardBg,
    required Color titleColor,
    required Color subtitleColor,
    required Color timeColor,
    required Color unreadBorderColor,
    required bool isDark,
  }) {
    final isRead = notif.isRead;

    IconData iconData;
    Color iconColor;
    switch (notif.type) {
      case 'leave_request':
        iconData = Icons.description_rounded;
        iconColor = const Color(0xFFD97706);
        break;
      case 'face_enrolled':
        iconData = Icons.face_retouching_natural_rounded;
        iconColor = const Color(0xFF10B981);
        break;
      case 'face_failed':
        iconData = Icons.error_outline_rounded;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'new_employee':
        iconData = Icons.person_add_rounded;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'attendance_alert':
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'meeting_reminder':
        iconData = Icons.event_rounded;
        iconColor = const Color(0xFF8B5CF6);
        break;
      default:
        iconData = Icons.notifications_rounded;
        iconColor = const Color(0xFF64748B);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isRead
            ? null
            : Border.all(color: unreadBorderColor, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        style: GoogleFonts.outfit(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(notif.createdAt),
                      style: GoogleFonts.outfit(
                        color: timeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: GoogleFonts.outfit(
                    color: subtitleColor,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 3),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
