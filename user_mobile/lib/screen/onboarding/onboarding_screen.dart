import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../auth/login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // ── Light onboarding palette (ilustrasi gambarHp berlatar putih/opaque) ──
  static const Color indigo = Color(0xFF4F46E5);
  static const Color jneOrange = Color(0xFFFF6B00);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Geofencing Pintar',
      description:
          'Absensi terverifikasi otomatis saat Anda berada di dalam radius kantor JNE Martapura.',
      image: 'assets/images/gambarHp/icon2.png',
      color: const Color(0xFF0891B2),
    ),
    OnboardingData(
      title: 'Verifikasi Wajah',
      description:
          'Keamanan ekstra dengan pemindaian wajah untuk memastikan kehadiran benar-benar Anda.',
      image: 'assets/images/gambarHp/icon3.png',
      color: indigo,
    ),
    OnboardingData(
      title: 'Peta & Laporan Real-time',
      description:
          'Lihat lokasi Anda di peta dan pantau riwayat absensi, cuti, serta lembur dalam genggaman.',
      image: 'assets/images/gambarHp/icon4.png',
      color: jneOrange,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _pages[_currentPage].color;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip ──
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Lewati',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
              child: Column(
                children: [
                  // Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: _currentPage == index ? 26 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? accent
                              : Colors.black.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  // CTA
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      if (isLast) {
                        _goToLogin();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOutCubic,
                        );
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [jneOrange, Color(0xFFFF8C3B)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: jneOrange.withValues(alpha: 0.4),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Mulai Sekarang' : 'Lanjutkan',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              isLast
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi besar — full-width, fit contain (aman untuk semua rasio).
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Image.asset(
                data.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported_rounded,
                  color: data.color,
                  size: 64,
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
