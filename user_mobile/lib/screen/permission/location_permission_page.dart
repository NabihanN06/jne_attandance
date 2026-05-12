import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'camera_permission_page.dart';

class LocationPermissionPage extends StatelessWidget {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);

  const LocationPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        title: Text(
          'IZIN LOKASI',
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
                  decoration: BoxDecoration(color: jneBlue.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded, color: jneBlue, size: 80),
                ),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                child: Text(
                  'Akses Lokasi Aktif',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Aplikasi membutuhkan akses lokasi untuk memverifikasi bahwa Anda berada di area kantor saat melakukan absensi.',
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
                    onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CameraPermissionPage()));
                    },
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