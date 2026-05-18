import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../providers/app_provider.dart';
import '../home/home_screen.dart';
import 'change_password_required_screen.dart';
import 'report_login_issue_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ── ZEN PREMIUM PALETTE ──
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenSlate = Color(0xFF94A3B8);
  static const Color zenOffWhite = Color(0xFFF8FAFC);

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
      _showSnack('IDENTIFICATION REQUIRED: ENTER CREDENTIALS', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final app = context.read<AppProvider>();
      await app.login(email, password);
      // Tunggu authStateChanges + _fetchCurrentUser selesai mengisi currentUser
      // dengan field passwordChanged. Loop sederhana max 3 detik.
      for (var i = 0; i < 30; i++) {
        if (app.currentUser != null) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (!mounted) return;

      // First-login → paksa ganti password permanen sebelum lanjut.
      if (app.requiresPasswordChange) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const ChangePasswordRequiredScreen()),
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
      _showSnack(e.toString().replaceAll('Exception: ', '').toUpperCase(), isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        backgroundColor: isError ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              
              // ── BRANDING SECTOR ──
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: zenNavy.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(color: zenNavy.withValues(alpha: 0.02)),
                  ),
                  child: Image.asset(
                    'assets/images/jne_logo.png', 
                    width: 140, 
                    errorBuilder: (_, _, _) => const Icon(Icons.hub_rounded, color: zenNavy, size: 60)
                  ),
                ),
              ),
              
              const SizedBox(height: 64),
              
              Text(
                'Operational\nAccess',
                style: GoogleFonts.outfit(
                  color: zenNavy, 
                  fontSize: 40, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Authorize your biometric connection to the JNE Martapura operational registry.',
                style: GoogleFonts.plusJakartaSans(
                  color: zenSlate, 
                  fontSize: 14, 
                  fontWeight: FontWeight.w600, 
                  height: 1.6,
                ),
              ),
              
              const SizedBox(height: 56),
              
              _label('REGISTRY EMAIL / SERIAL'),
              _field(
                _emailCtrl,
                'Ex: budi.ops / JNE-MTP-01',
                keyboard: TextInputType.emailAddress,
                icon: Icons.alternate_email_rounded,
              ),
              
              const SizedBox(height: 28),
              
              _label('SECURITY PASSPHRASE'),
              _field(
                _passCtrl,
                '••••••••',
                obscure: _obscurePass,
                icon: Icons.shield_outlined,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: zenSlate.withValues(alpha: 0.4), size: 18),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              
              const SizedBox(height: 48),
              
              SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zenNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text('AUTHORIZE SESSION', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3)),
                ),
              ),
              
              const SizedBox(height: 32),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ReportLoginIssueScreen()),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded,
                      color: zenSlate, size: 16),
                  label: Text(
                    'TIDAK BISA LOGIN? LAPOR KE ADMIN',
                    style: GoogleFonts.outfit(
                        color: zenSlate,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      text,
      style: GoogleFonts.outfit(color: zenSlate, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 2),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, {bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: zenOffWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zenNavy.withValues(alpha: 0.04)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: GoogleFonts.outfit(color: zenNavy, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: zenSlate.withValues(alpha: 0.3), fontSize: 14, fontWeight: FontWeight.w600),
          prefixIcon: icon != null ? Icon(icon, color: zenIndigo, size: 20) : null,
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
      ),
    );
  }
}
