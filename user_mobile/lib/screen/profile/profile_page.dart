import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/app_provider.dart';
import '../enroll/enroll_page.dart';

class ProfilePage extends StatelessWidget {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color zenSlate = Color(0xFF94A3B8);
  static const Color zenOffWhite = Color(0xFFF8FAFC);

  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox();
    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : zenOffWhite,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── PREMIUM NAVIGATION BAR ──
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'PERSONNEL REGISTRY',
                style: GoogleFonts.outfit(
                  color: zenNavy,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: zenNavy.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: zenNavy,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── CORE IDENTITY HUB ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: zenNavy.withValues(alpha: 0.04),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: zenNavy.withValues(alpha: 0.03),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ProfileAvatar(
                          photoUrl: user.photoUrl,
                          isProcessing: provider.isProcessing,
                          onPickFromGallery: () => _pickAndUpload(
                            context,
                            provider,
                            ImageSource.gallery,
                          ),
                          onPickFromCamera: () => _pickAndUpload(
                            context,
                            provider,
                            ImageSource.camera,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          user.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            color: zenNavy,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: zenIndigo.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: zenIndigo.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            '${user.position} • ${user.department}'
                                .toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: zenIndigo,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── LEAVE BALANCE VISUALIZER ──
                _buildSectionHeader('Operational Quota'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: zenNavy,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: zenNavy.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
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
                                  'ANNUAL LEAVE BALANCE',
                                  style: GoogleFonts.outfit(
                                    color: zenCyan,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${provider.leaveBalance.remainingAnnual}',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 6,
                                        left: 4,
                                      ),
                                      child: Text(
                                        '/ ${provider.leaveBalance.annualQuota} DAYS',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white38,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
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
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.event_available_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: LinearProgressIndicator(
                            value: provider.leaveBalance.usagePercent,
                            backgroundColor: Colors.white10,
                            color: zenCyan,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMiniStat(
                              'USED',
                              '${provider.leaveBalance.usedAnnual}d',
                            ),
                            _buildMiniStat(
                              'SICK',
                              '${provider.leaveBalance.usedSick}d',
                            ),
                            _buildMiniStat(
                              'PERM',
                              '${provider.leaveBalance.usedPermission}d',
                            ),
                            _buildMiniStat(
                              'PENDING',
                              '${provider.leaveBalance.pendingDays}d',
                              color: Colors.amber,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── OPERATIONAL TELEMETRY ──
                _buildSectionHeader('Operational Telemetry'),
                _buildCardWrapper([
                  _buildInfoItem(
                    Icons.alternate_email_rounded,
                    'Registry Email',
                    user.email,
                  ),
                  _buildDivider(),
                  _buildInfoItem(
                    Icons.phone_iphone_rounded,
                    'Signal Frequency',
                    user.phone.isEmpty ? '+62 000-000-0000' : user.phone,
                  ),
                  _buildDivider(),
                  _buildInfoItem(
                    Icons.fingerprint_rounded,
                    'Registry Serial',
                    user.employeeId,
                  ),
                ]),

                // ── ACCESS PROTOCOLS (Profile-only actions) ──
                _buildSectionHeader('Access Protocols'),
                _buildCardWrapper([
                  _buildActionItem(
                    context,
                    Icons.analytics_outlined,
                    'Request Center',
                    'Pantau cuti, lembur, & komplain',
                    () => Navigator.pushNamed(context, '/my_requests'),
                  ),
                  _buildDivider(),
                  _buildActionItem(
                    context,
                    Icons.badge_outlined,
                    'Identity Badge',
                    'Tampilkan kartu identitas HUB-MTP',
                    () => Navigator.pushNamed(context, '/id_card'),
                  ),
                  _buildDivider(),
                  _buildActionItem(
                    context,
                    Icons.face_retouching_natural_rounded,
                    'Re-Enroll Wajah',
                    'Perbarui data biometrik',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EnrollPage()),
                    ),
                  ),
                ]),

                const SizedBox(height: 32),

                // ── SETTINGS ENTRY POINT ──
                // Password, FAQ, chat, logout, dll. dipusatkan di /settings
                // supaya tidak duplikat dengan halaman lain.
                _buildSectionHeader('Pengaturan Lainnya'),
                _buildCardWrapper([
                  _buildActionItem(
                    context,
                    Icons.settings_outlined,
                    'Pengaturan & Akun',
                    'Tema, notifikasi, password, bantuan, & logout',
                    () => Navigator.pushNamed(context, '/settings'),
                  ),
                ]),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 8,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: zenSlate,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildCardWrapper(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: zenNavy.withValues(alpha: 0.03)),
          boxShadow: [
            BoxShadow(
              color: zenNavy.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: zenNavy.withValues(alpha: 0.02),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: zenNavy.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: zenSlate, size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: zenSlate,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    color: zenNavy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: zenIndigo.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: zenIndigo, size: 20),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: zenNavy,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: zenSlate,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: zenSlate.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(
    BuildContext context,
    AppProvider provider,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final xFile = await picker.pickImage(
        source: source,
        imageQuality: 90, // raw quality tinggi; akan dikompres lagi di provider
        maxWidth: 2048,
      );
      if (xFile == null) return;
      await provider.updateProfilePhoto(xFile.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Foto profil berhasil diperbarui'),
          backgroundColor: zenIndigo,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  static const Color _zenNavy = Color(0xFF121826);
  static const Color _zenIndigo = Color(0xFF4F46E5);

  final String? photoUrl;
  final bool isProcessing;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;

  const _ProfileAvatar({
    required this.photoUrl,
    required this.isProcessing,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : () => _showPickerSheet(context),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _zenIndigo.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: SizedBox(
                width: 108,
                height: 108,
                child: photoUrl != null && photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, _) => Container(
                          color: _zenNavy.withValues(alpha: 0.05),
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _zenIndigo,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (ctx, _, e) => Container(
                          color: _zenNavy.withValues(alpha: 0.03),
                          child: const Icon(
                            Icons.person_rounded,
                            color: _zenNavy,
                            size: 56,
                          ),
                        ),
                      )
                    : Container(
                        color: _zenNavy.withValues(alpha: 0.03),
                        child: const Icon(
                          Icons.person_rounded,
                          color: _zenNavy,
                          size: 56,
                        ),
                      ),
              ),
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _zenIndigo,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _zenIndigo.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _zenNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ubah Foto Profil',
                style: GoogleFonts.outfit(
                  color: _zenNavy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 18),
              _sheetItem(
                icon: Icons.photo_library_rounded,
                title: 'Pilih dari Galeri',
                subtitle: 'Ambil foto yang sudah ada di HP',
                onTap: () {
                  Navigator.pop(ctx);
                  onPickFromGallery();
                },
              ),
              const SizedBox(height: 8),
              _sheetItem(
                icon: Icons.camera_alt_rounded,
                title: 'Ambil dari Kamera',
                subtitle: 'Buka kamera & foto langsung',
                onTap: () {
                  Navigator.pop(ctx);
                  onPickFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _zenNavy.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _zenIndigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _zenIndigo, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: _zenNavy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      color: _zenNavy.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: _zenNavy.withValues(alpha: 0.3),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
