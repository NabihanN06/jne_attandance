import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

/// Modern static digital ID card (no flip animation).
class IDCardPage extends StatelessWidget {
  const IDCardPage({super.key});

  static const Color navy = Color(0xFF0B1120);
  static const Color navyCard = Color(0xFF15203A);
  static const Color jneOrange = Color(0xFFFF6B00);
  static const Color cyan = Color(0xFF22D3EE);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    final isDark = provider.isDarkMode;
    final bg = isDark ? navy : const Color(0xFFF1F5F9);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kartu Identitas Digital',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? Center(
              child: Text('Data karyawan tidak tersedia',
                  style: GoogleFonts.plusJakartaSans(color: textPrimary)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              child: Column(
                children: [
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: _card(user),
                  ),
                  const SizedBox(height: 28),
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: _footerNote(isDark, textPrimary),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF15203A),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: jneOrange.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.local_shipping_rounded,
                              color: jneOrange, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'JNE MARTAPURA',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.contactless_rounded,
                        color: Colors.white.withValues(alpha: 0.3), size: 22),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Avatar + identity ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: jneOrange, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white10,
                        backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? const Icon(Icons.person_rounded, color: Colors.white70, size: 42)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: jneOrange.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              user.position.isNotEmpty ? user.position : 'Karyawan',
                              style: GoogleFonts.plusJakartaSans(
                                color: jneOrange,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // ── Info row ──
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      _info('UNIT', user.department.isNotEmpty ? user.department : '-'),
                      Container(width: 1, height: 34, color: Colors.white12),
                      _info('ID KARYAWAN', user.employeeId.isNotEmpty ? user.employeeId : '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Verification strip ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.qr_code_2_rounded, color: navy, size: 44),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: cyan, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'KARTU TERVERIFIKASI',
                                style: GoogleFonts.plusJakartaSans(
                                  color: cyan,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tunjukkan QR ini ke admin untuk verifikasi identitas di lapangan.',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white54,
                              fontSize: 11,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footerNote(bool isDark, Color textPrimary) {
    return Column(
      children: [
        Icon(Icons.shield_moon_rounded, color: jneOrange.withValues(alpha: 0.8), size: 26),
        const SizedBox(height: 12),
        Text(
          'Kartu identitas resmi karyawan',
          style: GoogleFonts.plusJakartaSans(
            color: textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Berlaku selama Anda berstatus karyawan aktif JNE Martapura.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
