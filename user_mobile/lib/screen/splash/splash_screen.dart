import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── JNE Brand palette ──
  static const Color navy = Color(0xFF0B1120);
  static const Color jneOrange = Color(0xFFFF6B00);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack),
      ),
    );
    _controller.forward();
    _checkInit();
  }

  /// Lama minimum splash tampil (biar animasi logo tidak berkedip).
  static const Duration _minSplash = Duration(milliseconds: 1500);

  /// Batas maksimum menunggu AppProvider siap. Kalau lewat ini, tetap
  /// lanjut jalan — JANGAN menunggu selamanya. Dulu loop di bawah tidak
  /// punya batas, jadi kalau init provider tersendat (sinyal jelek), aplikasi
  /// mentok di layar "Menyiapkan aplikasi..." dan terlihat hang.
  static const Duration _maxWait = Duration(seconds: 12);

  Future<void> _checkInit() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await Future.delayed(_minSplash);

    final deadline = DateTime.now().add(_maxWait);
    while (!provider.isInitialized && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    // Kalau waktu habis sebelum provider siap, pakai sesi Firebase Auth yang
    // tersimpan lokal sebagai penentu — layar Home sudah tahan render dengan
    // data cache/kosong, jadi lebih baik masuk daripada tertahan di splash.
    if (provider.isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // JNE logo — flat, clean
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Image.asset(
                        'assets/images/gambarHp/icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.local_shipping_rounded,
                          color: jneOrange,
                          size: 50,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'JNE MARTAPURA',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistem Absensi Karyawan',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF8A93A6),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  SizedBox(
                    width: 44,
                    height: 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Align(
                              alignment: Alignment(
                                -1.0 + (2.0 * (_controller.value % 1.0)),
                                0,
                              ),
                              child: Container(
                                width: 16,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: jneOrange,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: jneOrange.withValues(alpha: 0.6),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Menyiapkan aplikasi...',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
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
}
