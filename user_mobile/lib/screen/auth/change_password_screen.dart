import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';

/// Ganti Kata Sandi — alur 2 langkah:
///   1. Verifikasi: isi kata sandi SEKARANG + konfirmasi (ketik ulang) kata
///      sandi sekarang. Kalau cocok & benar (reauthenticate sukses) → lanjut.
///   2. Sandi baru: isi kata sandi baru + konfirmasi → simpan.
///
/// Dipakai dari Pengaturan & Profil (menggantikan dialog satu-kolom lama).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const Color navy = Color(0xFF121826);
  static const Color indigo = Color(0xFF4F46E5);
  static const Color slate = Color(0xFF94A3B8);
  static const Color offWhite = Color(0xFFF8FAFC);
  static const Color rose = Color(0xFFF43F5E);
  static const Color emerald = Color(0xFF10B981);

  // Step 1 = verifikasi sandi lama, Step 2 = sandi baru.
  int _step = 1;
  bool _loading = false;

  final _curCtrl = TextEditingController();
  final _curConfirmCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _newConfirmCtrl = TextEditingController();

  bool _obCur = true, _obCurConfirm = true, _obNew = true, _obNewConfirm = true;

  @override
  void dispose() {
    _curCtrl.dispose();
    _curConfirmCtrl.dispose();
    _newCtrl.dispose();
    _newConfirmCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {required bool error}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        backgroundColor: error ? rose : emerald,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Langkah 1: verifikasi sandi sekarang ──
  Future<void> _verifyCurrent() async {
    final cur = _curCtrl.text;
    final confirm = _curConfirmCtrl.text;
    if (cur.isEmpty || confirm.isEmpty) {
      _snack('Kedua kolom wajib diisi.', error: true);
      return;
    }
    if (cur != confirm) {
      _snack('Konfirmasi kata sandi sekarang tidak cocok.', error: true);
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<AppProvider>().reauthenticate(cur);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 2;
      });
      _snack('Identitas terverifikasi. Silakan buat sandi baru.', error: false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  // ── Langkah 2: simpan sandi baru ──
  Future<void> _saveNew() async {
    final n = _newCtrl.text;
    final c = _newConfirmCtrl.text;
    if (n.isEmpty || c.isEmpty) {
      _snack('Kedua kolom wajib diisi.', error: true);
      return;
    }
    if (n.length < 8) {
      _snack('Kata sandi baru minimal 8 karakter.', error: true);
      return;
    }
    if (n != c) {
      _snack('Konfirmasi kata sandi baru tidak cocok.', error: true);
      return;
    }
    if (n == _curCtrl.text) {
      _snack('Kata sandi baru tidak boleh sama dengan yang lama.', error: true);
      return;
    }
    setState(() => _loading = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<AppProvider>().changePassword(n);
      if (!mounted) return;
      _snack('Kata sandi berhasil diganti.', error: false);
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: navy),
          onPressed: _loading ? null : () => Navigator.pop(context),
        ),
        title: Text(
          'Ganti Kata Sandi',
          style: GoogleFonts.outfit(
            color: navy,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _stepIndicator(),
              const SizedBox(height: 28),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.06, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: _step == 1 ? _buildStep1() : _buildStep2(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepIndicator() {
    Widget dot(int n, String label) {
      final active = _step >= n;
      return Expanded(
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: active ? indigo : offWhite,
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? indigo : slate.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                n == 1 ? Icons.verified_user_outlined : Icons.lock_reset_rounded,
                color: active ? Colors.white : slate,
                size: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: active ? indigo : slate,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        dot(1, 'Verifikasi'),
        Expanded(
          child: Container(
            height: 2,
            margin: const EdgeInsets.only(bottom: 18),
            color: _step >= 2 ? indigo : slate.withValues(alpha: 0.2),
          ),
        ),
        dot(2, 'Sandi Baru'),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verifikasi Identitas',
          style: GoogleFonts.outfit(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Masukkan kata sandi kamu yang sekarang, lalu ketik ulang untuk memastikan benar. Setelah cocok, kamu bisa membuat sandi baru.',
          style: GoogleFonts.plusJakartaSans(
            color: slate,
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        _label('KATA SANDI SEKARANG'),
        _field(
          ctrl: _curCtrl,
          hint: 'Masukkan kata sandi sekarang',
          obscure: _obCur,
          toggle: () => setState(() => _obCur = !_obCur),
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 18),
        _label('KONFIRMASI KATA SANDI SEKARANG'),
        _field(
          ctrl: _curConfirmCtrl,
          hint: 'Ketik ulang kata sandi sekarang',
          obscure: _obCurConfirm,
          toggle: () => setState(() => _obCurConfirm = !_obCurConfirm),
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 30),
        _primaryButton('VERIFIKASI', _verifyCurrent),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buat Kata Sandi Baru',
          style: GoogleFonts.outfit(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Pilih kata sandi baru minimal 8 karakter. Catat di tempat aman agar tidak lupa.',
          style: GoogleFonts.plusJakartaSans(
            color: slate,
            fontSize: 13,
            height: 1.55,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 28),
        _label('KATA SANDI BARU (MIN. 8 KARAKTER)'),
        _field(
          ctrl: _newCtrl,
          hint: 'Masukkan kata sandi baru',
          obscure: _obNew,
          toggle: () => setState(() => _obNew = !_obNew),
          icon: Icons.lock_outline_rounded,
        ),
        const SizedBox(height: 18),
        _label('KONFIRMASI KATA SANDI BARU'),
        _field(
          ctrl: _newConfirmCtrl,
          hint: 'Ketik ulang kata sandi baru',
          obscure: _obNewConfirm,
          toggle: () => setState(() => _obNewConfirm = !_obNewConfirm),
          icon: Icons.check_circle_outline_rounded,
        ),
        const SizedBox(height: 30),
        _primaryButton('SIMPAN KATA SANDI', _saveNew),
      ],
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(
      text,
      style: GoogleFonts.outfit(
        color: slate,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required bool obscure,
    required VoidCallback toggle,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: offWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: navy.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.outfit(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: slate.withValues(alpha: 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: indigo, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: slate.withValues(alpha: 0.5),
              size: 18,
            ),
            onPressed: toggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
