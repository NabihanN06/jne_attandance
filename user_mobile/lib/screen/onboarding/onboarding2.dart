import 'package:flutter/material.dart';
import '../../widgets/onboarding_widget.dart';
import 'onboarding3.dart';
import '../auth/login_page.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingWidget(
      icon: _buildChartIcon(),
      title: 'Lacak Kehadiran',
      subtitle: 'dan Lembur Anda',
      description:
          'Pantau statistik absensi, jam kerja efektif, dan\nlembur dalam satu dashboard.',
      onNext: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Onboarding3()),
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

  Widget _buildChartIcon() {
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(
        painter: _BarChartPainter(),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bars = [
      {'color': const Color(0xFF2196F3), 'height': 0.5},
      {'color': const Color(0xFF4CAF50), 'height': 1.0},
      {'color': const Color(0xFFE31E24), 'height': 0.7},
    ];

    final barWidth = size.width / (bars.length * 2 - 1);
    final gap = barWidth;

    for (int i = 0; i < bars.length; i++) {
      final paint = Paint()
        ..color = bars[i]['color'] as Color
        ..style = PaintingStyle.fill;

      final barHeight = size.height * (bars[i]['height'] as double);
      final left = i * (barWidth + gap);
      final top = size.height - barHeight;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}