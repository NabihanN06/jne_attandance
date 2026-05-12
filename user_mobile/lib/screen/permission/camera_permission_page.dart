import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:permission_handler/permission_handler.dart';
import '../welcome/welcome_page.dart';

class CameraPermissionPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);

  const CameraPermissionPage({super.key});

  Future<void> _requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();
    if (!context.mounted) return;

    if (status.isGranted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const WelcomePage()));
    } else if (status.isPermanentlyDenied) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Izin Diperlukan', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
          content: Text('Izin kamera ditolak secara permanen. Buka pengaturan untuk mengaktifkannya.', style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w700))),
            TextButton(onPressed: () { openAppSettings(); Navigator.pop(context); }, child: Text('Pengaturan', style: GoogleFonts.outfit(color: jneRed, fontWeight: FontWeight.w800))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        title: Text(
          'IZIN KAMERA',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 60),
              FadeInDown(
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(color: jneRed.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: jneRed, size: 80),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                child: Text(
                  'Verifikasi Wajah',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Aplikasi membutuhkan akses kamera untuk verifikasi wajah saat melakukan absensi demi keamanan data Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => _requestCameraPermission(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jneBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('BERIKAN IZIN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
}