import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../home/home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);

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
      _showSnack('Mohon isi email dan password', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<AppProvider>().login(email, password);
      if (!mounted) return;
      
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
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: isError ? jneRed : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              FadeInDown(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: jneRed.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset('assets/images/logo_jne.png', width: 80, height: 80, errorBuilder: (_, _, _) => const Icon(Icons.local_shipping_rounded, color: jneRed, size: 60)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                child: Text(
                  'Selamat Datang!',
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 8),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Silakan masuk untuk mengakses sistem absensi JNE Martapura.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 48),
              
              _label('ALAMAT EMAIL / NIK'),
              _field(
                _emailCtrl,
                'Contoh: budi.santoso / JNE-OPS-001',
                keyboard: TextInputType.emailAddress,
                icon: Icons.person_outline_rounded,
              ),
              
              const SizedBox(height: 24),
              
              _label('KATA SANDI'),
              _field(
                _passCtrl,
                '••••••••',
                obscure: _obscurePass,
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF94A3B8), size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              
              const SizedBox(height: 40),
              
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _doLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jneBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('MASUK SEKARANG', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Lupa kata sandi? Hubungi HR Admin',
                  style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      text,
      style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, {bool obscure = false, Widget? suffix, TextInputType keyboard = TextInputType.text, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: icon != null ? Icon(icon, color: jneBlue, size: 20) : null,
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
