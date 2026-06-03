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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenCyan = Color(0xFF22D3EE);

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
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _checkInit();
  }

  Future<void> _checkInit() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    // Minimal delay for brand establishment
    await Future.delayed(const Duration(milliseconds: 2500));
    
    while (!provider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    
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
      backgroundColor: zenNavy,
      body: Stack(
        children: [
          // Background Gradient Hub
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    zenIndigo.withValues(alpha: 0.08),
                    zenNavy,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Identity
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(48),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Image.asset(
                        'assets/images/jne_logo.png',
                        width: 180,
                        errorBuilder: (_, _, _) => _buildFallbackLogo(),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      'JNE MARTAPURA',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sistem Absensi Karyawan',
                      style: GoogleFonts.plusJakartaSans(
                        color: zenCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 80,
            left: 0, right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                   Container(
                     width: 40, height: 2,
                     decoration: BoxDecoration(
                       color: zenIndigo.withValues(alpha: 0.2),
                       borderRadius: BorderRadius.circular(10),
                     ),
                     child: OverflowBox(
                       maxWidth: 40,
                       child: AnimatedBuilder(
                         animation: _controller,
                         builder: (context, child) {
                           return Align(
                             alignment: Alignment(-1.0 + (2.0 * (_controller.value % 1.0)), 0.0),
                             child: Container(
                               width: 12, height: 2,
                               decoration: BoxDecoration(
                                 color: zenCyan,
                                 borderRadius: BorderRadius.circular(10),
                                 boxShadow: [BoxShadow(color: zenCyan.withValues(alpha: 0.5), blurRadius: 4)],
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                   ),
                   const SizedBox(height: 32),
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

  Widget _buildFallbackLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'JNE',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
          ),
        ),
        Container(width: 80, height: 4, color: zenCyan, margin: const EdgeInsets.only(top: 4)),
      ],
    );
  }
}