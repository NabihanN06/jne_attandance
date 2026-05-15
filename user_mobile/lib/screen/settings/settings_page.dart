import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;

    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final iconColor = isDark ? const Color(0xFF3B9EE8) : const Color(0xFF005596);
    final iconBg = isDark ? const Color(0xFF1A2640) : const Color(0xFF005596).withValues(alpha: 0.06);
    final divider = isDark ? const Color(0xFF1E3050) : const Color(0xFFF1F5F9);
    final appBarBg = isDark ? const Color(0xFF0B1120) : const Color(0xFF005596);
    final appBarFg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: appBarBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: appBarFg, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'PENGATURAN',
          style: GoogleFonts.outfit(color: appBarFg, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Preferensi Aplikasi', mutedColor),
            const SizedBox(height: 12),
            _settingsCard(cardBg, divider, [
              _settingItem(
                icon: Icons.dark_mode_outlined,
                title: 'Mode Gelap',
                subtitle: isDark ? 'Tema gelap aktif' : 'Tema terang aktif',
                iconColor: iconColor,
                iconBg: iconBg,
                titleColor: titleColor,
                mutedColor: mutedColor,
                trailing: Switch(
                  value: isDark,
                  onChanged: (_) => app.toggleTheme(),
                  activeTrackColor: iconColor.withValues(alpha: 0.3),
                  activeThumbColor: iconColor,
                ),
              ),
              Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
              _settingItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi Push',
                subtitle: app.isNotificationsEnabled
                    ? 'Notifikasi aktif'
                    : 'Notifikasi dinonaktifkan',
                iconColor: const Color(0xFF10B981),
                iconBg: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                titleColor: titleColor,
                mutedColor: mutedColor,
                trailing: Switch(
                  value: app.isNotificationsEnabled,
                  onChanged: (_) => app.toggleNotifications(),
                  activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                  activeThumbColor: const Color(0xFF10B981),
                ),
              ),
              Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
              _settingItem(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
                iconColor: const Color(0xFF8B5CF6),
                iconBg: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.15 : 0.08),
                titleColor: titleColor,
                mutedColor: mutedColor,
              ),
            ]),
            const SizedBox(height: 28),
            _sectionTitle('Tentang Aplikasi', mutedColor),
            const SizedBox(height: 12),
            _settingsCard(cardBg, divider, [
              _settingItem(
                icon: Icons.info_outline_rounded,
                title: 'Versi Aplikasi',
                subtitle: 'v4.2.0 (Stable)',
                iconColor: iconColor,
                iconBg: iconBg,
                titleColor: titleColor,
                mutedColor: mutedColor,
              ),
              Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
              _settingItem(
                icon: Icons.policy_outlined,
                title: 'Kebijakan Privasi',
                subtitle: 'Baca selengkapnya',
                iconColor: const Color(0xFF64748B),
                iconBg: const Color(0xFF64748B).withValues(alpha: isDark ? 0.15 : 0.08),
                titleColor: titleColor,
                mutedColor: mutedColor,
              ),
              Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
              _settingItem(
                icon: Icons.description_outlined,
                title: 'Syarat & Ketentuan',
                subtitle: 'Baca selengkapnya',
                iconColor: const Color(0xFF64748B),
                iconBg: const Color(0xFF64748B).withValues(alpha: isDark ? 0.15 : 0.08),
                titleColor: titleColor,
                mutedColor: mutedColor,
              ),
            ]),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 JNE Martapura. All Rights Reserved.',
                style: GoogleFonts.outfit(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, Color color) => Text(
    text.toUpperCase(),
    style: GoogleFonts.outfit(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
  );

  Widget _settingsCard(Color bg, Color divider, List<Widget> items) => Container(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(children: items),
  );

  Widget _settingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBg,
    required Color titleColor,
    required Color mutedColor,
    Widget? trailing,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(13)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(color: titleColor, fontSize: 14, fontWeight: FontWeight.w700, height: 1.2)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.outfit(color: mutedColor, fontSize: 11, fontWeight: FontWeight.w500, height: 1.3, letterSpacing: 0.1)),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded, color: mutedColor.withValues(alpha: 0.5), size: 20),
          ],
        ),
      );
}
