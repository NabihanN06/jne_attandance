import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_strings.dart';
import '../home/home_screen.dart';
import 'change_password_required_screen.dart';
import 'report_login_issue_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── Minimal palette ──
  static const Color navy = Color(0xFF0B1120);
  static const Color surface = Color(0xFF151C2C);
  static const Color line = Color(0xFF273043);
  static const Color jneOrange = Color(0xFFFF6B00);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color textHi = Color(0xFFF8FAFC);
  static const Color textLo = Color(0xFF8A93A6);

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    String email = _emailCtrl.text.trim();
    final password = _passCtrl.text;

    if (email.isNotEmpty && !email.contains('@')) {
      email = '$email@jne.mtp.com';
    }
    if (email.isEmpty || password.isEmpty) {
      _showSnack(context.tr('email_pass_required'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final app = context.read<AppProvider>();
      await app.login(email, password);
      for (var i = 0; i < 30; i++) {
        if (app.currentUser != null) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;

      if (app.requiresPasswordChange) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordRequiredScreen()),
          (r) => false,
        );
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (r) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(e.toString().replaceAll('Exception: ', ''), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: isError ? jneRed : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Logo — clean, no glow/gradient
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/images/jne.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Icon(Icons.local_shipping_rounded, color: jneOrange, size: 30),
                ),
              ),

              const SizedBox(height: 40),
              Text(context.tr('login_title'),
                  style: GoogleFonts.outfit(color: textHi, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(
                context.tr('login_subtitle'),
                style: GoogleFonts.plusJakartaSans(color: textLo, fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
              ),

              const SizedBox(height: 40),

              _label(context.tr('email_or_id')),
              const SizedBox(height: 8),
              _field(_emailCtrl, 'budi  ·  budi@jne.mtp.com', keyboard: TextInputType.emailAddress),

              const SizedBox(height: 22),

              _label(context.tr('password_label')),
              const SizedBox(height: 8),
              _field(
                _passCtrl,
                context.tr('enter_password'),
                obscure: _obscurePass,
                suffix: IconButton(
                  splashRadius: 20,
                  icon: Icon(_obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: textLo, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),

              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ReportLoginIssueScreen()),
                  ),
                  child: Text(
                    context.tr('forgot_login'),
                    style: GoogleFonts.plusJakartaSans(color: jneOrange, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Button — flat, precise, single accent
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: jneOrange,
                    disabledBackgroundColor: jneOrange.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(context.tr('login_title'), style: GoogleFonts.outfit(fontSize: 15.5, fontWeight: FontWeight.w700)),
                ),
              ),

              const SizedBox(height: 28),
              Center(
                child: Text(
                  context.tr('login_footer'),
                  style: GoogleFonts.plusJakartaSans(color: textLo.withValues(alpha: 0.6), fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(color: textLo, fontSize: 12.5, fontWeight: FontWeight.w600),
      );

  Widget _field(TextEditingController ctrl, String hint,
      {bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboard,
      style: GoogleFonts.plusJakartaSans(color: textHi, fontSize: 15, fontWeight: FontWeight.w600),
      cursorColor: jneOrange,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: textLo.withValues(alpha: 0.55), fontSize: 14, fontWeight: FontWeight.w400),
        suffixIcon: suffix,
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: jneOrange, width: 1.4),
        ),
      ),
    );
  }
}
