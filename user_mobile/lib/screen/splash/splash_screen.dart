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
  static const Color _jneRed  = Color(0xFFE31E24);
  static const Color _jneBlue = Color(0xFF005596);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic)),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();
    _checkInit();
  }

  Future<void> _checkInit() async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 2200));

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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Subtle red accent bar at very top
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(height: 4, color: _jneRed),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container — clean white card with subtle shadow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: _jneRed.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/jne_logo.png',
                          width: 80,
                          errorBuilder: (_, _, _) => _buildFallbackLogo(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App name
                    AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: child,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'JNE Martapura',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF1E293B),
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Sistem Absensi Karyawan',
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF64748B),
                              fontSize: 13,
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
          ),

          // Bottom loading indicator
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: SizedBox(
                        height: 3,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (_, _) => LinearProgressIndicator(
                            value: _controller.value,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(_jneRed),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat aplikasi...',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Blue accent bar at bottom
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(height: 3, color: _jneBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'JNE',
          style: GoogleFonts.outfit(
            color: _jneRed,
            fontSize: 40,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Container(
          width: 40, height: 3,
          decoration: BoxDecoration(
            color: _jneBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
