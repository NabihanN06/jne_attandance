import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import '../enroll/enroll_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  static const String userName = 'Nabihan';

  @override
  Widget build(BuildContext context) {
    const Color jneRed = Color(0xFFE31E24);
    const Color bgDark = Color(0xFF020617);

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // ── Background Blobs ──
          Positioned(
            top: -100, right: -50,
            child: _BlurredBlob(color: jneRed.withValues(alpha: 0.15), size: 400),
          ),
          Positioned(
            bottom: -150, left: -100,
            child: _BlurredBlob(color: const Color(0xFF005596).withValues(alpha: 0.15), size: 400),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  
                  // Header section
                  FadeInDown(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: jneRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: jneRed.withValues(alpha: 0.2)),
                          ),
                          child: const Text(
                            'AUTHENTICATION HUB',
                            style: TextStyle(color: jneRed, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Selamat Datang,\n$userName',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.5,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'JNE Martapura Internal Resource',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Main Enroll Card (Glass)
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: _PremiumGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: jneRed.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.face_retouching_natural_rounded, color: jneRed, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  'Daftarkan Wajah Anda',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Untuk mengaktifkan fitur absensi biometrik, sistem memerlukan pemindaian wajah sebagai enkripsi identitas unik Anda.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Preparation Card
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: _PremiumGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROTOKOL PERSIAPAN',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2),
                          ),
                          const SizedBox(height: 20),
                          const _StepItem(icon: Icons.no_accounts_rounded, text: 'Lepas masker & aksesoris wajah'),
                          const _StepItem(icon: Icons.light_mode_rounded, text: 'Pastikan pencahayaan optimal'),
                          const _StepItem(icon: Icons.center_focus_strong_rounded, text: 'Posisikan wajah di tengah area scan'),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // CTA Button
                  FadeInUp(
                    delay: const Duration(milliseconds: 600),
                    child: _buildCtaButton(context, jneRed),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context, Color accent) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EnrollPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: const Text(
          'MULAI PENDAFTARAN',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
    );
  }
}

class _PremiumGlassCard extends StatelessWidget {
  final Widget child;
  const _PremiumGlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _StepItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFFE31E24)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurredBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurredBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size / 2, spreadRadius: size / 4)],
      ),
    );
  }
}
