import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';

/// Layar lapor masalah login. Dipanggil dari login_page saat user gak bisa
/// masuk (akun belum dibuat, lupa password, dll).
///
/// Tidak butuh auth — submit langsung ke Firestore collection `login_issues`.
/// Admin baca dari inbox di admin web, lalu bantu user (reset password,
/// create account, dll) via channel eksternal (WhatsApp/email).
class ReportLoginIssueScreen extends StatefulWidget {
  const ReportLoginIssueScreen({super.key});

  @override
  State<ReportLoginIssueScreen> createState() => _ReportLoginIssueScreenState();
}

class _ReportLoginIssueScreenState extends State<ReportLoginIssueScreen> {
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenSlate = Color(0xFF94A3B8);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || desc.isEmpty) {
      _showSnack('Nama, email/ID, dan masalah wajib diisi.', isError: true);
      return;
    }
    if (desc.length < 10) {
      _showSnack('Jelaskan masalahnya minimal 10 karakter.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    try {
      await context.read<AppProvider>().submitLoginIssue(
        name: name,
        emailOrEmployeeId: email,
        description: desc,
        phone: phone.isEmpty ? null : phone,
      );
      if (!mounted) return;
      _showSnack(
        'Laporan diterima. Admin akan kontak kamu segera.',
        isError: false,
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(
        'Gagal kirim laporan: ${e.toString().replaceAll('Exception: ', '')}',
        isError: true,
      );
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: zenNavy,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'LAPOR MASALAH LOGIN',
          style: GoogleFonts.outfit(
            color: zenNavy,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ── INFO CARD ──
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: zenIndigo.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: zenIndigo.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.support_agent_rounded,
                      color: zenIndigo,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Isi form di bawah. Admin akan kontak kamu lewat WhatsApp/email dalam 1-2 jam kerja untuk bantu masalah login kamu.',
                        style: GoogleFonts.plusJakartaSans(
                          color: zenNavy.withValues(alpha: 0.8),
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              _label('NAMA LENGKAP *'),
              _field(
                ctrl: _nameCtrl,
                hint: 'Mis. Budi Santoso',
                icon: Icons.person_outline_rounded,
                keyboard: TextInputType.name,
              ),
              const SizedBox(height: 18),

              _label('EMAIL ATAU EMPLOYEE ID *'),
              _field(
                ctrl: _emailCtrl,
                hint: 'budi@jne.co.id atau JNE-MTP-04',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),

              _label('NOMOR WHATSAPP (opsional)'),
              _field(
                ctrl: _phoneCtrl,
                hint: '0812xxxxxxx',
                icon: Icons.phone_iphone_rounded,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 18),

              _label('APA MASALAHNYA? *'),
              _field(
                ctrl: _descCtrl,
                hint:
                    'Contoh: saya udah dapat APK tapi pas login muncul "email/password salah". Saya belum pernah dikasih password sama admin.',
                icon: Icons.description_outlined,
                keyboard: TextInputType.multiline,
                maxLines: 5,
              ),

              const SizedBox(height: 28),

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
                          'KIRIM LAPORAN',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
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
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: zenOffWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: maxLines,
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
            height: 1.4,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
            child: Icon(icon, color: zenIndigo, size: 20),
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
