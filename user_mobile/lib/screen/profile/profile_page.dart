import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';
import '../help/faq_screen.dart';

class ProfilePage extends StatelessWidget {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);
  static const Color zenRose = Color(0xFFF43F5E);
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
                  child: const Icon(Icons.chevron_left_rounded, color: zenNavy, size: 28),
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
                      border: Border.all(color: zenNavy.withValues(alpha: 0.04)),
                      boxShadow: [
                        BoxShadow(
                          color: zenNavy.withValues(alpha: 0.03),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: zenIndigo.withValues(alpha: 0.1), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: zenNavy.withValues(alpha: 0.03),
                            child: const Icon(Icons.person_rounded, color: zenNavy, size: 56),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: zenIndigo.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: zenIndigo.withValues(alpha: 0.1)),
                          ),
                          child: Text(
                            '${user.position} • ${user.department}'.toUpperCase(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: zenNavy,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(color: zenNavy.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 15))
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
                                  style: GoogleFonts.outfit(color: zenCyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${provider.leaveBalance.remainingAnnual}',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                                      child: Text(
                                        '/ ${provider.leaveBalance.annualQuota} DAYS',
                                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
                              child: const Icon(Icons.event_available_rounded, color: Colors.white, size: 28),
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
                            _buildMiniStat('USED', '${provider.leaveBalance.usedAnnual}d'),
                            _buildMiniStat('SICK', '${provider.leaveBalance.usedSick}d'),
                            _buildMiniStat('PERM', '${provider.leaveBalance.usedPermission}d'),
                            _buildMiniStat('PENDING', '${provider.leaveBalance.pendingDays}d', color: Colors.amber),
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
                  _buildInfoItem(Icons.alternate_email_rounded, 'Registry Email', user.email),
                  _buildDivider(),
                  _buildInfoItem(Icons.phone_iphone_rounded, 'Signal Frequency', user.phone.isEmpty ? '+62 000-000-0000' : user.phone),
                  _buildDivider(),
                  _buildInfoItem(Icons.fingerprint_rounded, 'Registry Serial', user.employeeId),
                ]),

                // ── OPERATIONAL SUPPORT ──
                _buildSectionHeader('Operational Support'),
                _buildCardWrapper([
                  _buildActionItem(context, Icons.analytics_outlined, 'Request Center', 'Track leaves & complaints', () => Navigator.pushNamed(context, '/my_requests')),
                  _buildDivider(),
                  _buildActionItem(context, Icons.support_agent_rounded, 'Command Center Chat', 'Direct sync with admin', () => Navigator.pushNamed(context, '/chat')),
                  _buildDivider(),
                  _buildActionItem(context, Icons.help_outline_rounded, 'Help & FAQ', 'Cek pertanyaan umum dulu sebelum komplain', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
                ]),

                const SizedBox(height: 32),

                // ── ACCESS PROTOCOLS ──
                _buildSectionHeader('Access Protocols'),
                _buildCardWrapper([
                  _buildActionItem(context, Icons.badge_outlined, 'Identity Badge', 'Official HUB-MTP Registry', () => Navigator.pushNamed(context, '/id_card')),
                  _buildDivider(),
                  _buildActionItem(context, Icons.face_retouching_natural_rounded, 'Biometric Recalibration', 'Sync Facial Signatures', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollPage()))),
                ]),

                const SizedBox(height: 32),

                // ── SECURITY ARCHITECTURE ──
                _buildSectionHeader('Security Architecture'),
                _buildCardWrapper([
                  _buildActionItem(context, Icons.shield_outlined, 'Access Override', 'Rotate Hub Credentials', () => _showChangePasswordDialog(context, provider)),
                ]),

                const SizedBox(height: 48),

                // ── TERMINATION SECTOR ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GestureDetector(
                    onTap: () => _confirmLogout(context, provider),
                    child: Container(
                      height: 72,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: zenRose.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: zenRose.withValues(alpha: 0.12)),
                      ),
                      child: Center(
                        child: Text(
                          'TERMINATE ACTIVE SESSION',
                          style: GoogleFonts.outfit(
                            color: zenRose,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
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
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: color ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
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
            )
          ],
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, thickness: 1, color: zenNavy.withValues(alpha: 0.02));
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

  Widget _buildActionItem(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
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
            Icon(Icons.arrow_forward_ios_rounded, color: zenSlate.withValues(alpha: 0.3), size: 14),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text('TERMINATE SESSION?', style: GoogleFonts.outfit(color: zenNavy, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5)),
        content: Text('Operational connection to Hub Martapura will be severed. Manual re-sync is mandatory for future telemetry access.', style: GoogleFonts.plusJakartaSans(color: zenSlate, fontSize: 13, height: 1.6)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ABORT', style: GoogleFonts.outfit(color: zenSlate, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              provider.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zenRose,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('TERMINATE', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: Text('ACCESS OVERRIDE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: zenNavy)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Specify a high-entropy passphrase to secure your active personnel registry node.',
              style: GoogleFonts.plusJakartaSans(color: zenSlate, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: controller,
              obscureText: true,
              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: zenNavy),
              decoration: InputDecoration(
                hintText: 'New Access Token',
                hintStyle: GoogleFonts.outfit(color: zenSlate.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600),
                prefixIcon: const Icon(Icons.shield_rounded, size: 18, color: zenSlate),
                filled: true,
                fillColor: zenNavy.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(22),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.outfit(color: zenSlate, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Token must be ≥ 6 chars.')));
                return;
              }
              try {
                await provider.changePassword(controller.text);
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Access Token Synced Successfully.'),
                    backgroundColor: zenIndigo,
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  )
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: zenNavy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text('SYNC TOKEN', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }
}