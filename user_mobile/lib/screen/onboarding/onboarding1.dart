import 'package:flutter/material.dart';
import 'onboarding2.dart';
import '../auth/login_page.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF081F3F),
      body: _buildContent(
        context,
        '😎',
        'Absensi Lebih Mudah',
        'dengan Face Recognition',
        'Verifikasi wajah Anda secara otomatis. Tidak perlu kartu atau sidik jari.',
        const Onboarding2(),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String emoji,
    String title,
    String subtitle,
    String description,
    Widget nextScreen,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            Text(emoji, style: const TextStyle(fontSize: 80)),
            const Spacer(flex: 2),
            Text(title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE31E24)),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Text(description,
                style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.6),
                textAlign: TextAlign.center),
            const Spacer(flex: 3),

            // Lanjut button
            _PressableButton(
              label: 'Lanjut →',
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => nextScreen),
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Lewati → langsung ke LoginPage
            GestureDetector(
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              ),
              child: const Text(
                'Lewati',
                style: TextStyle(
                  color: Color(0xFF90A4AE),
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF90A4AE),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Reusable pressable button dengan scale effect ──
class _PressableButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _PressableButton({required this.label, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) async {
        await _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFE31E24),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE31E24).withOpacity(_scale.value == 1.0 ? 0.4 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}