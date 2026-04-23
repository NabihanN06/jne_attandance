import 'package:flutter/material.dart';
import 'package:jneattendance_mobile/screen/auth/login_page.dart';
import '../../widgets/onboarding_widget.dart';
import 'onboarding4.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingWidget(
      icon: _buildClipboardIcon(),
      title: 'Ajukan Izin',
      subtitle: 'Kapan Saja',
      description:
          'Izin sakit, cuti, atau izin pribadi bisa diajukan\nlangsung dari aplikasi.',
      onNext: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Onboarding4()),
        );
      },
      onSkip: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
    );
  }

  Widget _buildClipboardIcon() {
    return SizedBox(
      width: 80,
      height: 90,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Clipboard body
          Positioned(
            top: 10,
            child: Container(
              width: 70,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Column(
                  children: List.generate(
                    4,
                    (i) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBDBDBD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Clip
          Positioned(
            top: 0,
            child: Container(
              width: 30,
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF78909C),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}