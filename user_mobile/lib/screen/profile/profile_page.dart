import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';

class ProfilePage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox();

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
          'PROFIL SAYA',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // ── Top Header Section ──
            Stack(
              children: [
                Container(height: 80, color: jneBlue),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: jneBlue.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_rounded, color: jneBlue, size: 40),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('${user.position} · ${user.department}', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Info Sections ──
            _buildInfoSection('Data Pribadi', [
              _buildInfoItem(Icons.email_rounded, 'Alamat Email', user.email),
              _buildInfoItem(Icons.phone_rounded, 'Nomor Telepon', user.phone.isEmpty ? '+62 000-0000-0000' : user.phone),
              _buildInfoItem(Icons.badge_rounded, 'ID Karyawan', user.nik),
            ]),

            const SizedBox(height: 20),

            _buildInfoSection('Pengaturan Keamanan', [
              _buildActionItem(context, Icons.face_unlock_rounded, 'Registrasi Ulang Wajah', 'Perbarui data biometrik Anda', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollPage()))),
              _buildActionItem(context, Icons.lock_outline_rounded, 'Ganti Kata Sandi', 'Ubah kredensial akses Anda', () {}),
            ]),

            const SizedBox(height: 32),

            // ── Logout Button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _confirmLogout(context, provider),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: jneRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: jneRed.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text('Keluar dari Akun', style: GoogleFonts.outfit(color: jneRed, fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: jneBlue, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('KELUAR AKUN?', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text('Anda perlu melakukan login kembali untuk dapat melakukan absensi dan mengakses data kerja Anda.', style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('BATAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: jneRed,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('YA, KELUAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}