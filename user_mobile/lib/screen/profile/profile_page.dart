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
import '../../utils/app_strings.dart';
import '../auth/login_page.dart';
import '../auth/change_password_screen.dart';
import '../enroll/enroll_page.dart';
import 'photo_crop_screen.dart';
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
    final contractDuration = _contractDuration(context, user);

    return Scaffold(
      backgroundColor: pal.auroraBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          context.tr('profile_title'),
          style: GoogleFonts.plusJakartaSans(
            color: pal.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            icon: Icon(
              Icons.settings_outlined,
              color: pal.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
      body: AuroraBackground(
        child: ListView(
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
            SectionLabel(context.tr('sec_account')),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppInfoRow(
                    icon: Icons.alternate_email_rounded,
                    label: context.tr('email'),
                    value: user.email,
                  ),
                  const AppRowDivider(),
                  AppInfoRow(
                    icon: Icons.phone_iphone_rounded,
                    label: context.tr('phone'),
                    value: user.phone.isEmpty
                        ? context.tr('not_set')
                        : user.phone,
                  ),
                  const AppRowDivider(),
                  AppInfoRow(
                    icon: Icons.badge_outlined,
                    label: context.tr('employee_id'),
                    value: user.employeeId.isEmpty ? '-' : user.employeeId,
                  ),
                  const AppRowDivider(),
                  AppInfoRow(
                    icon: Icons.work_outline_rounded,
                    label: context.tr('emp_status'),
                    value: _contractLabel(context, user),
                  ),
                  if (contractDuration != null) ...[
                    const AppRowDivider(),
                    AppInfoRow(
                      icon: Icons.event_busy_outlined,
                      label: context.tr('emp_duration'),
                      value: contractDuration,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Services ──
            SectionLabel(context.tr('sec_services')),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppActionRow(
                    icon: Icons.assignment_outlined,
                    iconColor: AppColors.blue,
                    title: context.tr('request_center'),
                    subtitle: context.tr('request_center_sub'),
                    onTap: () => Navigator.pushNamed(context, '/my_requests'),
                    imageAsset: 'assets/images/iconapk/iconpengajuan.png',
                  ),
                  const AppRowDivider(),
                  AppActionRow(
                    icon: Icons.support_agent_rounded,
                    iconColor: AppColors.green,
                    title: context.tr('menu_chat'),
                    subtitle: context.tr('chat_hr_sub'),
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                    imageAsset: 'assets/images/iconapk/chatHR.png',
                  ),
                  const AppRowDivider(),
                  AppActionRow(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.amber,
                    title: context.tr('help_faq'),
                    subtitle: context.tr('help_faq_sub'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FaqScreen()),
                    ),
                    imageAsset: 'assets/images/iconapk/helpandFAQ.png',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Card & biometric ──
            SectionLabel(context.tr('sec_card_bio')),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AppActionRow(
                    icon: Icons.contact_mail_outlined,
                    iconColor: AppColors.brandRed,
                    title: context.tr('id_card'),
                    subtitle: context.tr('id_card_sub'),
                    onTap: () =>
                        Navigator.pushNamed(context, '/profile/id_card'),
                    imageAsset: 'assets/images/iconapk/idcard.png',
                  ),
                  const AppRowDivider(),
                  AppActionRow(
                    icon: Icons.face_retouching_natural_rounded,
                    iconColor: AppColors.violet,
                    title: context.tr('reenroll_face'),
                    subtitle: context.tr('reenroll_face_sub'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EnrollPage()),
                    ),
                    imageAsset: 'assets/images/iconapk/enrollface.png',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Security ──
            SectionLabel(context.tr('sec_security')),
            GlassCard(
              padding: EdgeInsets.zero,
              child: AppActionRow(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF0EA5E9),
                title: context.tr('change_password'),
                subtitle: context.tr('change_password_sub'),
                onTap: () =>
                    _showChangePasswordDialog(context, provider, pal.isDark),
                imageAsset: 'assets/images/iconapk/password.png',
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
                  color: AppColors.brandRed.withValues(
                    alpha: pal.isDark ? 0.14 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.brandRed.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.brandRed,
                      size: 19,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      context.tr('logout'),
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.brandRed,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                context.tr('app_footer'),
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          if (roleText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.jneOrange.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.jneOrange.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                roleText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.jneOrange,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          if (user.contractType == 'contract' ||
              user.contractType == 'intern') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.violet,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _contractChipText(context, user),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
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
                _heroStat(
                  '${stats['present']}',
                  context.tr('stat_present'),
                  Icons.check_circle_rounded,
                  AppColors.green,
                ),
                _heroDivider(),
                _heroStat(
                  '${stats['late']}',
                  context.tr('stat_late'),
                  Icons.alarm_rounded,
                  AppColors.amber,
                ),
                _heroDivider(),
                _heroStat(
                  '${(punctuality * 100).toInt()}%',
                  context.tr('on_time'),
                  Icons.verified_rounded,
                  AppColors.sky,
                ),
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
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroDivider() => Container(
    width: 1,
    height: 38,
    color: Colors.white.withValues(alpha: 0.08),
  );

  // ── Leave balance (theme-aware) ──
  Widget _leaveBalanceCard(LeaveBalance balance, AppPalette pal) {
    return GlassCard(
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
                  Text(
                    context.tr('remaining_annual_leave'),
                    style: GoogleFonts.plusJakartaSans(
                      color: pal.textSub,
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
                          color: pal.textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, left: 5),
                        child: Text(
                          '${context.tr('of_days')} ${balance.annualQuota} ${context.tr('days')}',
                          style: GoogleFonts.plusJakartaSans(
                            color: pal.textFaint,
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
                  color: AppColors.green.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: AppColors.green,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: balance.usagePercent,
              backgroundColor: pal.isDark
                  ? Colors.white10
                  : const Color(0xFFE2E8F0),
              color: AppColors.green,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat(
                context.tr('used2'),
                '${balance.usedAnnual} ${context.tr('days')}',
                pal,
                pal.textPrimary,
              ),
              _miniStat(
                context.tr('sick2'),
                '${balance.usedSick} ${context.tr('days')}',
                pal,
                pal.textPrimary,
              ),
              _miniStat(
                context.tr('permit'),
                '${balance.usedPermission} ${context.tr('days')}',
                pal,
                pal.textPrimary,
              ),
              _miniStat(
                context.tr('submitted'),
                '${balance.pendingDays} ${context.tr('days')}',
                pal,
                AppColors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(
    String label,
    String value,
    AppPalette pal,
    Color valueColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: pal.textFaint,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
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
              border: Border.all(
                color: AppColors.jneOrange.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E293B),
              backgroundImage: hasPhoto
                  ? CachedNetworkImageProvider(photoUrl)
                  : null,
              child: hasPhoto
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white54,
                      size: 52,
                    ),
            ),
          ),
          if (_uploading)
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
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
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 15,
              ),
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
          decoration: BoxDecoration(
            color: sheet,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    Text(
                      context.tr('change_photo'),
                      style: GoogleFonts.plusJakartaSans(
                        color: txt,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              _sheetOption(
                ctx,
                Icons.photo_library_rounded,
                context.tr('from_gallery'),
                txt,
                ImageSource.gallery,
              ),
              _sheetOption(
                ctx,
                Icons.photo_camera_rounded,
                context.tr('take_photo'),
                txt,
                ImageSource.camera,
              ),
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
      if (!mounted) return;

      // Buka cropper bulat (atur posisi & zoom) sebelum upload.
      final cropped = await Navigator.push<File?>(
        context,
        MaterialPageRoute(
          builder: (_) => PhotoCropScreen(image: File(picked.path)),
        ),
      );
      if (cropped == null) return;

      setState(() => _uploading = true);
      await provider.updateProfilePhoto(cropped);
      if (!mounted) return;
      showAppSnack(
        context,
        context.tr('photo_updated'),
        color: AppColors.green,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        e.toString().replaceAll('Exception: ', ''),
        color: AppColors.brandRed,
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _sheetOption(
    BuildContext ctx,
    IconData icon,
    String label,
    Color txt,
    ImageSource src,
  ) {
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brandRed, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: txt,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
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
        title: Text(
          context.tr('logout_confirm'),
          style: GoogleFonts.plusJakartaSans(
            color: txt,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          context.tr('logout_confirm_desc'),
          style: GoogleFonts.plusJakartaSans(
            color: sub,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              context.tr('cancel'),
              style: GoogleFonts.plusJakartaSans(
                color: sub,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              context.tr('logout'),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AppProvider provider,
    bool isDark,
  ) {
    // Alur Ganti Kata Sandi 2 langkah: verifikasi sandi sekarang dulu, baru
    // boleh set sandi baru (lihat ChangePasswordScreen).
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
  }

  // ── Status kepegawaian ──
  String _contractLabel(BuildContext context, UserModel user) {
    switch (user.contractType) {
      case 'intern':
        return context.tr('emp_intern');
      case 'contract':
        return context.tr('emp_contract');
      default:
        return context.tr('emp_permanent');
    }
  }

  String _contractChipText(BuildContext context, UserModel user) {
    final label = _contractLabel(context, user).toUpperCase();
    if (user.contractMonths != null) {
      return '$label · ${user.contractMonths} ${context.tr('emp_months').toUpperCase()}';
    }
    return label;
  }

  // "6 bulan · berakhir 15 Des 2026 (120 hari lagi)" — null untuk karyawan tetap.
  String? _contractDuration(BuildContext context, UserModel user) {
    final isContract =
        user.contractType == 'contract' || user.contractType == 'intern';
    if (!isContract || user.contractMonths == null) return null;
    final months = user.contractMonths!;
    final buf = StringBuffer('$months ${context.tr('emp_months')}');
    final joinStr = user.joinDate;
    if (joinStr != null && joinStr.isNotEmpty) {
      final start = DateTime.tryParse(joinStr);
      if (start != null) {
        final end = DateTime(start.year, start.month + months, start.day);
        buf.write(' · ${context.tr('emp_ends')} ${_formatDateId(end)}');
        final today = DateTime.now();
        final daysLeft = end
            .difference(DateTime(today.year, today.month, today.day))
            .inDays;
        if (daysLeft < 0) {
          buf.write(' (${context.tr('emp_expired')})');
        } else {
          buf.write(' ($daysLeft ${context.tr('emp_days_left')})');
        }
      }
    }
    return buf.toString();
  }

  String _formatDateId(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}
