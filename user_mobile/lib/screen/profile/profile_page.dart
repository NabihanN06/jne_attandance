import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../utils/connectivity_service.dart';
import '../notifications/notification_screen.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';
import 'id_card_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingPhoto = false;

  Future<void> _editPhone() async {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.phone);
    final newValue = await showDialog<String>(
      context: context,
      builder: (ctx) {
        bool saving = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Ubah Nomor Telepon',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            content: TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              autofocus: true,
              enabled: !saving,
              decoration: InputDecoration(
                hintText: '0812xxxxxxxx',
                prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text('BATAL',
                    style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        setLocal(() => saving = true);
                        Navigator.pop(ctx, ctrl.text.trim());
                      },
                child: Text('SIMPAN',
                    style: GoogleFonts.outfit(color: const Color(0xFF005596), fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      },
    );

    if (newValue == null || !mounted) return;
    try {
      await context.read<AppProvider>().updateMyProfile(phone: newValue);
      if (mounted) {
        _showToast(context, 'Nomor diperbarui', 'Nomor telepon Anda telah disimpan.',
            Icons.check_circle_rounded, const Color(0xFF10B981));
      }
    } catch (e) {
      if (mounted) {
        _showToast(context, 'Gagal Simpan', e.toString().replaceAll('Exception: ', ''),
            Icons.error_outline_rounded, const Color(0xFFEF4444));
      }
    }
  }

  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    try {
      await context.read<AppProvider>().uploadProfilePhoto(picked.path);
      if (mounted) {
        _showToast(
          context,
          'Berhasil!',
          'Foto profil Anda telah diperbarui.',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );
      }
    } catch (e) {
      if (mounted) {
        _showToast(
          context,
          'Gagal Upload',
          e.toString().replaceAll('Exception: ', ''),
          Icons.error_outline_rounded,
          const Color(0xFFEF4444),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showToast(BuildContext context, String title, String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      msg,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final isDark = provider.isDarkMode;
    if (user == null) return const SizedBox();

    // Palette
    final bg = isDark ? const Color(0xFF0B1120) : const Color(0xFFEFF6FF);
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final divider = isDark ? const Color(0xFF1E3050) : const Color(0xFFF1F5F9);
    final primary = isDark ? const Color(0xFF3B9EE8) : const Color(0xFF081F3F);
    final headerTop = isDark ? const Color(0xFF0D1829) : const Color(0xFF081F3F);
    final headerBot = isDark ? const Color(0xFF162240) : const Color(0xFF06152A);
    final shadowColor = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.05);
    
    final conn = context.watch<ConnectivityService>();

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── HEADER ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            elevation: 0,
            backgroundColor: headerTop,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [headerTop, headerBot],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // ── AVATAR with edit button ──
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar circle
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 3),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 16)
                              ],
                            ),
                            child: ClipOval(
                              child: _isUploadingPhoto
                                  ? Container(
                                      color: Colors.black54,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                    )
                                  : user.photoUrl != null &&
                                          user.photoUrl!.isNotEmpty
                                      ? Image.network(
                                          user.photoUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              _avatarFallback(user.name),
                                        )
                                      : _avatarFallback(user.name),
                            ),
                          ),

                          // Edit icon — bottom right of avatar
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _isUploadingPhoto
                                  ? null
                                  : _changeProfilePhoto,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt_rounded,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ),

                          // Face registered badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: user.faceRegistered
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                user.faceRegistered
                                    ? Icons.verified_rounded
                                    : Icons.warning_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      Text(
                        user.name,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${user.position} · ${user.department}',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _statusBadge(conn.isOnline),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── EMPLOYEE ID CARD ──
                  _employeeCard(user.employeeId, user.department, primary, isDark),
                  const SizedBox(height: 32),
                  _sectionTitle('Statistik Kerja (Bulan Ini)', mutedColor),
                  const SizedBox(height: 14),
                  _workStatsGrid(provider, titleColor, mutedColor, isDark),
                  const SizedBox(height: 32),

                  // ── INFO ──
                  _sectionTitle('Informasi Akun', mutedColor),
                  const SizedBox(height: 10),
                  _card(cardBg, shadowColor, [
                    _infoRow(Icons.alternate_email_rounded, 'Email', user.email,
                        primary, titleColor, mutedColor),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    InkWell(
                      onTap: _editPhone,
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          _infoRow(Icons.phone_outlined, 'Telepon',
                              user.phone.isEmpty ? 'Tap untuk isi' : user.phone,
                              primary, titleColor, mutedColor),
                          Positioned(
                            right: 16,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Icon(Icons.edit_outlined, size: 14, color: mutedColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _infoRow(Icons.badge_outlined, 'ID Karyawan',
                        user.employeeId, primary, titleColor, mutedColor),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _infoRow(Icons.business_rounded, 'Departemen',
                        user.department, primary, titleColor, mutedColor),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _infoRow(Icons.work_outline_rounded, 'Jabatan',
                        user.position, primary, titleColor, mutedColor),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _infoRow(
                      Icons.wifi_tethering_rounded,
                      'Remote Absensi',
                      user.allowRemoteAttendance ? 'Diizinkan' : 'Tidak Diizinkan',
                      user.allowRemoteAttendance
                          ? const Color(0xFF10B981)
                          : mutedColor,
                      titleColor,
                      mutedColor,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── ACTIONS ──
                  _sectionTitle('Menu Akun', mutedColor),
                  const SizedBox(height: 10),
                  _card(cardBg, shadowColor, [
                    _actionRow(
                      context,
                      icon: Icons.credit_card_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: isDark
                          ? const Color(0xFF1A2E5C)
                          : const Color(0xFFDBEAFE),
                      title: 'ID Card Digital',
                      subtitle: 'Lihat & scan kartu identitas karyawan',
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IDCardPage()),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _actionRow(
                      context,
                      icon: Icons.face_retouching_natural_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: isDark
                          ? const Color(0xFF0D2E22)
                          : const Color(0xFFD1FAE5),
                      title: 'Daftarkan Wajah',
                      subtitle: 'Update data biometrik wajah',
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EnrollPage()),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _actionRow(
                      context,
                      icon: Icons.notifications_none_rounded,
                      iconColor: const Color(0xFF6366F1),
                      iconBg: isDark
                          ? const Color(0xFF1E1E4D)
                          : const Color(0xFFEEF2FF),
                      title: 'Notifikasi',
                      subtitle: 'Pusat pemberitahuan dan info',
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: divider, indent: 16, endIndent: 16),
                    _actionRow(
                      context,
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: isDark
                          ? const Color(0xFF2A1E08)
                          : const Color(0xFFFEF3C7),
                      title: 'Ganti Password',
                      subtitle: 'Ubah kata sandi akun',
                      titleColor: titleColor,
                      mutedColor: mutedColor,
                      onTap: () =>
                          _showChangePasswordDialog(context, provider, isDark),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── LOGOUT ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmLogout(context, provider, isDark),
                      icon: const Icon(Icons.logout_rounded,
                          color: Color(0xFFEF4444), size: 20),
                      label: Text(
                        'Keluar',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFFEF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.3)),
                        backgroundColor: const Color(0xFFEF4444)
                            .withValues(alpha: isDark ? 0.08 : 0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
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

  Widget _avatarFallback(String name) => Container(
        color: const Color(0xFF1D4ED8),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'U',
            style: GoogleFonts.outfit(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
          ),
        ),
      );

  Widget _statusBadge(bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOnline 
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444))
              .withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE MODE',
            style: GoogleFonts.outfit(
                color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _employeeCard(
      String empId, String dept, Color primary, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3050) : const Color(0xFFF1F5F9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 40,
            offset: const Offset(0, 20),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/thumb/0/03/JNE_Express_logo.svg/1200px-JNE_Express_logo.svg.png',
                height: 24,
                errorBuilder: (_, _, _) => Text('JNE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: const Color(0xFFE31E24))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'AKTIF',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: Color(0xFF2563EB), size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID KARYAWAN',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      empId.isEmpty ? 'JNE-XXXX' : empId,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      dept.toUpperCase(),
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _workStatsGrid(AppProvider provider, Color titleColor, Color mutedColor, bool isDark) {
    final now = DateTime.now();
    final stats = provider.getStatsForMonth(now.month, now.year);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = 12;
        final double itemWidth = (constraints.maxWidth - spacing) / 2;
        
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _statItem('Hadir', '${stats['present']}', 'Hari', const Color(0xFF10B981), Icons.check_circle_rounded, itemWidth, isDark),
            _statItem('Izin', '${stats['leaves']}', 'Hari', const Color(0xFF3B82F6), Icons.assignment_rounded, itemWidth, isDark),
            _statItem('Telat', '${stats['late']}', 'Menit', const Color(0xFFEF4444), Icons.alarm_rounded, itemWidth, isDark),
            _statItem('Performa', '${(stats['punctuality'] * 100).toInt()}', '%', const Color(0xFFF59E0B), Icons.auto_awesome_rounded, itemWidth, isDark),
          ],
        );
      },
    );
  }

  Widget _statItem(String label, String value, String unit, Color color, IconData icon, double width, bool isDark) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2E) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3050) : const Color(0xFFF1F5F9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (label == 'Performa')
                Container(
                  width: 32, height: 4,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: double.tryParse(value) != null ? double.parse(value) / 100 : 0.8,
                    child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }


  Widget _sectionTitle(String t, Color c) => Text(
        t,
        style: GoogleFonts.outfit(
            color: c.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3),
      );

  Widget _card(Color bg, Color shadow, List<Widget> items) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 4))
          ],
        ),
        child: Column(children: items),
      );

  Widget _infoRow(IconData icon, String label, String value, Color iconColor,
          Color titleColor, Color mutedColor) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                        color: mutedColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _actionRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required Color titleColor,
    required Color mutedColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: iconBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                          color: titleColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                          color: mutedColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: mutedColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
            ],
          ),
        ),
      );

  void _confirmLogout(
      BuildContext context, AppProvider provider, bool isDark) {
    final cardBg = isDark ? const Color(0xFF131D2E) : Colors.white;
    final titleColor =
        isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final mutedColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.logout_rounded,
                    color: Color(0xFFEF4444), size: 28),
              ),
              const SizedBox(height: 16),
              Text('Keluar?',
                  style: GoogleFonts.outfit(
                      color: titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Anda akan keluar dari akun ini.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    color: mutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: mutedColor,
                        side: BorderSide(
                            color: isDark
                                ? const Color(0xFF1E3050)
                                : const Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Batal',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await provider.logout();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginPage()),
                          (r) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text('Keluar',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
      BuildContext context, AppProvider provider, bool isDark) async {
    final oldCtrl  = TextEditingController();
    final newCtrl  = TextEditingController();
    final confCtrl = TextEditingController();

    final cardBg     = isDark ? const Color(0xFF131D2E) : Colors.white;
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final mutedColor = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    final fieldBg    = isDark ? const Color(0xFF1A2640) : const Color(0xFFF8FAFC);
    final fieldBorder= isDark ? const Color(0xFF1E3050) : const Color(0xFFE2E8F0);
    final primary    = isDark ? const Color(0xFF3B9EE8) : const Color(0xFF2563EB);

    Widget buildField({
      required TextEditingController ctrl,
      required String hint,
      required bool obscure,
      required VoidCallback onToggle,
    }) =>
        Container(
          decoration: BoxDecoration(
            color: fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fieldBorder),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: GoogleFonts.outfit(color: titleColor, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: mutedColor, fontSize: 13),
              prefixIcon: Icon(Icons.lock_outline_rounded, color: primary, size: 20),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: mutedColor, size: 18),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        );

    await showDialog(
      context: context,
      builder: (ctx) {
        bool obscureOld  = true;
        bool obscureNew  = true;
        bool obscureConf = true;
        bool isSaving    = false;
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.lock_reset_rounded, color: primary, size: 22),
                  ),
                  const SizedBox(height: 14),
                  Text('Ganti Password',
                      style: GoogleFonts.outfit(color: titleColor, fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Masukkan password lama lalu buat password baru.',
                      style: GoogleFonts.outfit(color: mutedColor, fontSize: 12, height: 1.5)),

                  const SizedBox(height: 20),

                  // Old password
                  Text('Password Lama',
                      style: GoogleFonts.outfit(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  buildField(
                    ctrl: oldCtrl,
                    hint: 'Masukkan password saat ini',
                    obscure: obscureOld,
                    onToggle: () => setDialogState(() => obscureOld = !obscureOld),
                  ),

                  const SizedBox(height: 14),

                  // New password
                  Text('Password Baru',
                      style: GoogleFonts.outfit(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  buildField(
                    ctrl: newCtrl,
                    hint: 'Min. 6 karakter',
                    obscure: obscureNew,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                  ),

                  const SizedBox(height: 14),

                  // Confirm password
                  Text('Konfirmasi Password Baru',
                      style: GoogleFonts.outfit(color: titleColor, fontSize: 12, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  buildField(
                    ctrl: confCtrl,
                    hint: 'Ulangi password baru',
                    obscure: obscureConf,
                    onToggle: () => setDialogState(() => obscureConf = !obscureConf),
                  ),

                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!,
                        style: GoogleFonts.outfit(
                            color: const Color(0xFFEF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: mutedColor,
                            side: BorderSide(color: fieldBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: Text('Batal', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (oldCtrl.text.isEmpty) {
                                    setDialogState(() => errorText = 'Masukkan password lama terlebih dahulu');
                                    return;
                                  }
                                  if (newCtrl.text.length < 6) {
                                    setDialogState(() => errorText = 'Password baru minimal 6 karakter');
                                    return;
                                  }
                                  if (newCtrl.text != confCtrl.text) {
                                    setDialogState(() => errorText = 'Konfirmasi password tidak cocok');
                                    return;
                                  }
                                  if (oldCtrl.text == newCtrl.text) {
                                    setDialogState(() => errorText = 'Password baru harus berbeda dari password lama');
                                    return;
                                  }
                                  setDialogState(() { isSaving = true; errorText = null; });
                                  try {
                                    // Re-authenticate with old password first
                                    await provider.reauthAndChangePassword(
                                      oldCtrl.text, newCtrl.text);
                                    if (!context.mounted) return;
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Password berhasil diubah',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                        backgroundColor: const Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                        margin: const EdgeInsets.all(16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  } catch (e) {
                                    setDialogState(() {
                                      isSaving = false;
                                      errorText = e.toString().replaceAll('Exception: ', '');
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: fieldBg,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: isSaving
                              ? SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(color: primary, strokeWidth: 2.5))
                              : Text('Simpan', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    oldCtrl.dispose();
    newCtrl.dispose();
    confCtrl.dispose();
  }
}
