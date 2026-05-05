import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color bgLight = Color(0xFFF8FAFC);

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          'PENGATURAN',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Preferensi Aplikasi'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSettingItem(Icons.dark_mode_outlined, 'Mode Gelap', 'Sesuaikan tampilan aplikasi', trailing: Switch(value: false, onChanged: (v) {}, activeTrackColor: jneBlue.withValues(alpha: 0.3), activeThumbColor: jneBlue)),
              _buildSettingItem(Icons.notifications_none_rounded, 'Notifikasi Push', 'Aktifkan pengingat absensi', trailing: Switch(value: true, onChanged: (v) {}, activeTrackColor: jneBlue.withValues(alpha: 0.3), activeThumbColor: jneBlue)),
              _buildSettingItem(Icons.language_rounded, 'Bahasa', 'Bahasa Indonesia'),
            ]),
            const SizedBox(height: 32),
            _buildSectionTitle('Tentang Kami'),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSettingItem(Icons.info_outline_rounded, 'Versi Aplikasi', 'v4.2.0 (Stable)'),
              _buildSettingItem(Icons.policy_outlined, 'Kebijakan Privasi', 'Baca selengkapnya'),
              _buildSettingItem(Icons.description_outlined, 'Syarat & Ketentuan', 'Baca selengkapnya'),
            ]),
            const SizedBox(height: 40),
            Center(
              child: Text(
                '© 2026 JNE Martapura. All Rights Reserved.',
                style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Text(t.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1));
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: jneBlue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: jneBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
                Text(subtitle, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}
