import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';
import '../help/faq_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox();
    final pal = context.palette;
    final balance = provider.leaveBalance;
    final now = DateTime.now();
    final stats = provider.getStatsForMonth(now.month, now.year);

    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          'Profil Saya',
          style: GoogleFonts.plusJakartaSans(
              color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(Icons.settings_outlined, color: pal.textPrimary, size: 22),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ── Premium hero header ──
          FadeInDown(
            duration: const Duration(milliseconds: 450),
            child: _heroHeader(user, stats),
          ),
          const SizedBox(height: 20),

          // ── Leave balance ──
          FadeInUp(
            duration: const Duration(milliseconds: 450),
            child: _leaveBalanceCard(balance, pal),
          ),
          const SizedBox(height: 24),

          // ── Account info ──
          const SectionLabel('Informasi Akun'),
          AppCard(
            child: Column(children: [
              AppInfoRow(icon: Icons.alternate_email_rounded, label: 'Email', value: user.email),
              const AppRowDivider(),
              AppInfoRow(
                  icon: Icons.phone_iphone_rounded,
                  label: 'Nomor HP',
                  value: user.phone.isEmpty ? 'Belum diatur' : user.phone),
              const AppRowDivider(),
              AppInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'ID Karyawan',
                  value: user.employeeId.isEmpty ? '-' : user.employeeId),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Services ──
          const SectionLabel('Layanan'),
          AppCard(
            child: Column(children: [
              AppActionRow(
                icon: Icons.assignment_outlined,
                iconColor: AppColors.blue,
                title: 'Pusat Pengajuan',
                subtitle: 'Pantau cuti, lembur & komplain',
                onTap: () => Navigator.pushNamed(context, '/my_requests'),
              ),
              const AppRowDivider(),
              AppActionRow(
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.green,
                title: 'Chat HR',
                subtitle: 'Hubungi admin secara langsung',
                onTap: () => Navigator.pushNamed(context, '/chat'),
              ),
              const AppRowDivider(),
              AppActionRow(
                icon: Icons.help_outline_rounded,
                iconColor: AppColors.amber,
                title: 'Bantuan & FAQ',
                subtitle: 'Pertanyaan yang sering diajukan',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const FaqScreen())),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Card & biometric ──
          const SectionLabel('Kartu & Biometrik'),
          AppCard(
            child: Column(children: [
              AppActionRow(
                icon: Icons.contact_mail_outlined,
                iconColor: AppColors.brandRed,
                title: 'Kartu Identitas',
                subtitle: 'Kartu pegawai resmi JNE',
                onTap: () => Navigator.pushNamed(context, '/profile/id_card'),
              ),
              const AppRowDivider(),
              AppActionRow(
                icon: Icons.face_retouching_natural_rounded,
                iconColor: AppColors.violet,
                title: 'Daftar Ulang Wajah',
                subtitle: 'Perbarui data pengenalan wajah',
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const EnrollPage())),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Security ──
          const SectionLabel('Keamanan'),
          AppCard(
            child: AppActionRow(
              icon: Icons.lock_outline_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: 'Ganti Kata Sandi',
              subtitle: 'Perbarui kata sandi akun Anda',
              onTap: () => _showChangePasswordDialog(context, provider, pal.isDark),
            ),
          ),
          const SizedBox(height: 28),

          // ── Logout ──
          GestureDetector(
            onTap: () => _confirmLogout(context, provider, pal.isDark),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: pal.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.brandRed, size: 19),
                  const SizedBox(width: 10),
                  Text('Keluar',
                      style: GoogleFonts.plusJakartaSans(
                          color: AppColors.brandRed, fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'JNE Attendance • Martapura Hub',
              style: GoogleFonts.plusJakartaSans(
                  color: pal.textFaint, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero header (navy gradient + avatar + stat chips) ──
  Widget _heroHeader(UserModel user, Map<String, dynamic> stats) {
    final pal = context.palette;
    final roleText = [
      if (user.position.isNotEmpty) user.position,
      if (user.department.isNotEmpty) user.department,
    ].join(' • ');
    final punctuality = ((stats['punctuality'] as num?) ?? 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: pal.heroDecoration(),
      child: Column(
        children: [
          _buildAvatar(user.photoUrl, pal.isDark),
          const SizedBox(height: 16),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          if (roleText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.jneOrange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppColors.jneOrange.withValues(alpha: 0.35)),
              ),
              child: Text(
                roleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    color: AppColors.jneOrange, fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _heroStat('${stats['present']}', 'Hadir', Icons.check_circle_rounded, AppColors.green),
                _heroDivider(),
                _heroStat('${stats['late']}', 'Telat', Icons.alarm_rounded, AppColors.amber),
                _heroDivider(),
                _heroStat('${(punctuality * 100).toInt()}%', 'Tepat Waktu',
                    Icons.verified_rounded, AppColors.sky),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _heroDivider() =>
      Container(width: 1, height: 38, color: Colors.white.withValues(alpha: 0.08));

  // ── Leave balance (theme-aware) ──
  Widget _leaveBalanceCard(LeaveBalance balance, AppPalette pal) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sisa Cuti Tahunan',
                      style: GoogleFonts.plusJakartaSans(
                          color: pal.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${balance.remainingAnnual}',
                          style: GoogleFonts.plusJakartaSans(
                              color: pal.textPrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              height: 1)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 5),
                        child: Text('dari ${balance.annualQuota} hari',
                            style: GoogleFonts.plusJakartaSans(
                                color: pal.textFaint, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: const Icon(Icons.event_available_rounded, color: AppColors.green, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: balance.usagePercent,
              backgroundColor: pal.isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              color: AppColors.green,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat('Terpakai', '${balance.usedAnnual} hari', pal, pal.textPrimary),
              _miniStat('Sakit', '${balance.usedSick} hari', pal, pal.textPrimary),
              _miniStat('Izin', '${balance.usedPermission} hari', pal, pal.textPrimary),
              _miniStat('Diajukan', '${balance.pendingDays} hari', pal, AppColors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, AppPalette pal, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: pal.textFaint, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.plusJakartaSans(
                color: valueColor, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
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
              border: Border.all(color: AppColors.jneOrange.withValues(alpha: 0.4), width: 2),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: hasPhoto ? CachedNetworkImageProvider(photoUrl) : null,
              child: hasPhoto
                  ? null
                  : const Icon(Icons.person_rounded, color: Colors.white54, size: 52),
            ),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
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
                color: AppColors.brandRed,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF15203A), width: 3),
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
                        style: GoogleFonts.plusJakartaSans(
                            color: txt, fontWeight: FontWeight.w800, fontSize: 16)),
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
      showAppSnack(context, 'Foto profil berhasil diperbarui', color: AppColors.green);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, e.toString().replaceAll('Exception: ', ''), color: AppColors.brandRed);
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
              decoration: BoxDecoration(
                  color: AppColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.brandRed, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    color: txt, fontWeight: FontWeight.w700, fontSize: 14.5)),
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
            child: Text('Batal',
                style: GoogleFonts.plusJakartaSans(color: sub, fontWeight: FontWeight.w700)),
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
              backgroundColor: AppColors.brandRed,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Keluar',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(18),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal',
                style: GoogleFonts.plusJakartaSans(color: sub, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(ctx);
              if (controller.text.length < 6) {
                messenger.showSnackBar(appSnack('Kata sandi minimal 6 karakter.', AppColors.brandRed));
                return;
              }
              try {
                await provider.changePassword(controller.text);
                navigator.pop();
                messenger.showSnackBar(appSnack('Kata sandi berhasil diubah', AppColors.green));
              } catch (e) {
                messenger.showSnackBar(
                    appSnack(e.toString().replaceAll('Exception: ', ''), AppColors.brandRed));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text('Simpan',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
