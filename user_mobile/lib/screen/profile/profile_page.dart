import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';
import '../help/faq_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Brand palette ──
  static const Color brandRed = Color(0xFFE31E24);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentAmber = Color(0xFFF59E0B);

  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox();
    final isDark = provider.isDarkMode;

    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);
    final card = isDark ? const Color(0xFF15203A) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0);
    final balance = provider.leaveBalance;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
        ),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Identity header ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: border),
              boxShadow: isDark
                  ? null
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                _buildAvatar(user.photoUrl, isDark),
                const SizedBox(height: 18),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: brandRed.withValues(alpha: isDark ? 0.16 : 0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    [
                      if (user.position.isNotEmpty) user.position,
                      if (user.department.isNotEmpty) user.department,
                    ].join(' • '),
                    style: GoogleFonts.plusJakartaSans(
                      color: brandRed,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Leave balance ──
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa Cuti Tahunan',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${balance.remainingAnnual}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 5, left: 5),
                              child: Text(
                                'dari ${balance.annualQuota} hari',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white38,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 26),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: balance.usagePercent,
                    backgroundColor: Colors.white10,
                    color: accentGreen,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniStat('Terpakai', '${balance.usedAnnual} hari'),
                    _miniStat('Sakit', '${balance.usedSick} hari'),
                    _miniStat('Izin', '${balance.usedPermission} hari'),
                    _miniStat('Diajukan', '${balance.pendingDays} hari', color: accentAmber),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Account info ──
          _sectionLabel('Informasi Akun', textSub),
          _card(card, border, isDark, [
            _infoRow(Icons.alternate_email_rounded, 'Email', user.email, textPrimary, textSub),
            _divider(border),
            _infoRow(Icons.phone_iphone_rounded, 'Nomor HP',
                user.phone.isEmpty ? 'Belum diatur' : user.phone, textPrimary, textSub),
            _divider(border),
            _infoRow(Icons.badge_outlined, 'ID Karyawan',
                user.employeeId.isEmpty ? '-' : user.employeeId, textPrimary, textSub),
          ]),

          const SizedBox(height: 24),

          // ── Services ──
          _sectionLabel('Layanan', textSub),
          _card(card, border, isDark, [
            _actionRow(Icons.assignment_outlined, accentBlue, 'Pusat Pengajuan',
                'Pantau cuti, lembur & komplain', textPrimary, textSub,
                () => Navigator.pushNamed(context, '/my_requests')),
            _divider(border),
            _actionRow(Icons.support_agent_rounded, accentGreen, 'Chat HR',
                'Hubungi admin secara langsung', textPrimary, textSub,
                () => Navigator.pushNamed(context, '/chat')),
            _divider(border),
            _actionRow(Icons.help_outline_rounded, accentAmber, 'Bantuan & FAQ',
                'Pertanyaan yang sering diajukan', textPrimary, textSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
          ]),

          const SizedBox(height: 24),

          // ── Card & biometric ──
          _sectionLabel('Kartu & Biometrik', textSub),
          _card(card, border, isDark, [
            _actionRow(Icons.contact_mail_outlined, brandRed, 'Kartu Identitas',
                'Kartu pegawai resmi JNE', textPrimary, textSub,
                () => Navigator.pushNamed(context, '/profile/id_card')),
            _divider(border),
            _actionRow(Icons.face_retouching_natural_rounded, const Color(0xFF6366F1), 'Daftar Ulang Wajah',
                'Perbarui data pengenalan wajah', textPrimary, textSub,
                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollPage()))),
          ]),

          const SizedBox(height: 24),

          // ── Security ──
          _sectionLabel('Keamanan', textSub),
          _card(card, border, isDark, [
            _actionRow(Icons.lock_outline_rounded, const Color(0xFF0EA5E9), 'Ganti Kata Sandi',
                'Perbarui kata sandi akun Anda', textPrimary, textSub,
                () => _showChangePasswordDialog(context, provider, isDark)),
          ]),

          const SizedBox(height: 28),

          // ── Logout ──
          GestureDetector(
            onTap: () => _confirmLogout(context, provider, isDark),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: brandRed.withValues(alpha: isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: brandRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: brandRed, size: 19),
                  const SizedBox(width: 10),
                  Text(
                    'Keluar',
                    style: GoogleFonts.plusJakartaSans(
                      color: brandRed,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar with change-photo affordance ──
  Widget _buildAvatar(String? photoUrl, bool isDark) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;
    return GestureDetector(
      onTap: _uploading ? null : _pickAndUploadPhoto,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: brandRed.withValues(alpha: 0.25), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl) : null,
              child: hasPhoto
                  ? null
                  : Icon(Icons.person_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8), size: 52),
            ),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                child: const Center(
                  child: SizedBox(
                    width: 26, height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: brandRed,
                shape: BoxShape.circle,
                border: Border.all(color: isDark ? const Color(0xFF15203A) : Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final provider = context.read<AppProvider>();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = context.read<AppProvider>().isDarkMode;
        final sheet = isDark ? const Color(0xFF15203A) : Colors.white;
        final txt = isDark ? Colors.white : const Color(0xFF0F172A);
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: sheet, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Text('Ubah Foto Profil',
                        style: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w800, fontSize: 16)),
                  ],
                ),
              ),
              _sheetOption(ctx, Icons.photo_library_rounded, 'Pilih dari Galeri', txt, ImageSource.gallery),
              _sheetOption(ctx, Icons.photo_camera_rounded, 'Ambil Foto', txt, ImageSource.camera),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _uploading = true);
      await provider.updateProfilePhoto(File(picked.path));
      if (!mounted) return;
      _toast('Foto profil berhasil diperbarui', accentGreen);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceAll('Exception: ', ''), brandRed);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _sheetOption(BuildContext ctx, IconData icon, String label, Color txt, ImageSource src) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pop(ctx, src),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: brandRed.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: brandRed, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label, style: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w700, fontSize: 14.5)),
          ],
        ),
      ),
    );
  }

  SnackBar _snack(String msg, Color color) => SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      );

  void _toast(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(_snack(msg, color));
  }

  // ── Small builders ──
  Widget _miniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _sectionLabel(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 12.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
      ),
    );
  }

  Widget _card(Color card, Color border, bool isDark, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(Color border) => Divider(height: 1, thickness: 1, color: border, indent: 64);

  Widget _infoRow(IconData icon, String label, String value, Color textPrimary, Color textSub) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: textSub.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: textSub, size: 19),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.plusJakartaSans(color: textSub, fontSize: 11.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(value, style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, Color iconColor, String title, String subtitle,
      Color textPrimary, Color textSub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(color: textPrimary, fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(color: textSub, fontSize: 11.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textSub.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider, bool isDark) {
    final card = isDark ? const Color(0xFF15203A) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: card,
        surfaceTintColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Keluar dari akun?',
            style: GoogleFonts.plusJakartaSans(color: txt, fontWeight: FontWeight.w800, fontSize: 18)),
        content: Text(
          'Anda perlu masuk kembali untuk mengakses absensi dan data Anda.',
          style: GoogleFonts.plusJakartaSans(color: sub, fontSize: 13.5, height: 1.5),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: sub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (r) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider provider, bool isDark) {
    final controller = TextEditingController();
    final card = isDark ? const Color(0xFF15203A) : Colors.white;
    final txt = isDark ? Colors.white : const Color(0xFF0F172A);
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: card,
        surfaceTintColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Ganti Kata Sandi',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18, color: txt)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Masukkan kata sandi baru minimal 6 karakter.',
                style: GoogleFonts.plusJakartaSans(color: sub, fontSize: 13.5, height: 1.5)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: txt),
              decoration: InputDecoration(
                hintText: 'Kata sandi baru',
                hintStyle: GoogleFonts.plusJakartaSans(color: sub.withValues(alpha: 0.6), fontSize: 13.5),
                prefixIcon: Icon(Icons.lock_outline_rounded, size: 19, color: sub),
                filled: true,
                fillColor: sub.withValues(alpha: 0.08),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: sub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              if (controller.text.length < 6) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('Kata sandi minimal 6 karakter.')),
                );
                return;
              }
              try {
                await provider.changePassword(controller.text);
                navigator.pop();
                messenger.showSnackBar(_snack('Kata sandi berhasil diubah', accentGreen));
              } catch (e) {
                messenger.showSnackBar(
                  _snack(e.toString().replaceAll('Exception: ', ''), brandRed),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Simpan', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
