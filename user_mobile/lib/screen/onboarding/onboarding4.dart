import 'package:flutter/material.dart';
import '../../widgets/onboarding_widget.dart';
import '../auth/login_page.dart';

class Onboarding4 extends StatelessWidget {
  const Onboarding4({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingWidget(
      icon: const Text('🚀', style: TextStyle(fontSize: 80)),
      title: 'Semuanya Siap!',
      subtitle: 'Mari Mulai',
      description:
          'Daftar wajah Anda dan mulai gunakan aplikasi\nabsensi JNE MTP.',
      nextLabel: 'Lanjut →',
      onNext: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
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
}