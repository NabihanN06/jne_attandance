import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../home/home_screen.dart';

/// Layar wajib di first-login: user yang masih punya `passwordChanged == false`
/// (akun baru dibuat admin pakai temp password) harus set password permanen
/// dulu sebelum bisa pakai app.
///
/// Tidak ada back button — flow di-paksa. User cuma bisa keluar via logout
/// atau ganti password sukses.
class ChangePasswordRequiredScreen extends StatefulWidget {
  const ChangePasswordRequiredScreen({super.key});

  @override
  State<ChangePasswordRequiredScreen> createState() =>
      _ChangePasswordRequiredScreenState();
}

class _ChangePasswordRequiredScreenState
    extends State<ChangePasswordRequiredScreen> {
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenSlate = Color(0xFF94A3B8);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);

  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    final n = _newCtrl.text;
    final c = _confirmCtrl.text;
    if (n.isEmpty || c.isEmpty) return 'Kedua field wajib diisi.';
    if (n.length < 8) return 'Password minimal 8 karakter.';
    if (n != c) return 'Konfirmasi password tidak cocok.';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      _showSnack(err, isError: true);
      return;
    }
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      final app = context.read<AppProvider>();
      await app.changePassword(_newCtrl.text);
      await app.markPasswordChanged();
      if (!mounted) return;
      _showSnack('Password berhasil diatur. Selamat datang!', isError: false);
      await Future.delayed(const Duration(milliseconds: 600));
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

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        backgroundColor: isError ? zenRose : zenEmerald,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // tidak bisa back — flow wajib
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),

                // ── HEADER ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: zenIndigo.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: zenIndigo,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Atur Password\nPermanen',
                  style: GoogleFonts.outfit(
                    color: zenNavy,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Password yang kamu pilih sekarang akan dipakai setiap kali kamu login ke app JNE Absensi. Pilih password yang gampang diingat tapi tetap aman.',
                  style: GoogleFonts.plusJakartaSans(
                    color: zenSlate,
                    fontSize: 13,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // ── TOAST INFO (selalu visible, bukan snackbar) ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFB45309),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'INGAT: Password ini akan jadi satu-satunya password kamu untuk app ini. Catat di tempat aman. Kalau lupa, hubungi admin.',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF92400E),
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── FIELD: Password Baru ──
                _label('PASSWORD BARU (MIN. 8 KARAKTER)'),
                _field(
                  ctrl: _newCtrl,
                  hint: 'Masukkan password baru',
                  obscure: _obscureNew,
                  toggleObscure: () =>
                      setState(() => _obscureNew = !_obscureNew),
                  icon: Icons.lock_outline_rounded,
                ),

                const SizedBox(height: 20),

                // ── FIELD: Konfirmasi ──
                _label('KONFIRMASI PASSWORD'),
                _field(
                  ctrl: _confirmCtrl,
                  hint: 'Ketik ulang password yang sama',
                  obscure: _obscureConfirm,
                  toggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  icon: Icons.check_circle_outline_rounded,
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: zenNavy,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Text(
                            'SIMPAN & LANJUTKAN',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // logout() di app_provider declared as `void` (fire-and-forget),
                            // auth state change listener akan handle navigation reset.
                            context.read<AppProvider>().logout();
                            Navigator.popUntil(context, (r) => r.isFirst);
                          },
                    child: Text(
                      'Logout',
                      style: GoogleFonts.outfit(
                        color: zenSlate,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
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
        color: zenSlate,
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
    required VoidCallback toggleObscure,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: zenOffWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.outfit(
          color: zenNavy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: zenSlate.withValues(alpha: 0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: zenIndigo, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: zenSlate.withValues(alpha: 0.5),
              size: 18,
            ),
            onPressed: toggleObscure,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
      ),
    );
  }
}
