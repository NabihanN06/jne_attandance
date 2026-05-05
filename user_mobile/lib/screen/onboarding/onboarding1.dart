import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'onboarding2.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  @override
  Widget build(BuildContext context) {
    const Color jneBlue = Color(0xFF005596);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const SizedBox(height: 80),
              FadeInDown(
                child: Container(
                  width: 280, height: 280,
                  decoration: BoxDecoration(color: jneBlue.withValues(alpha: 0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.location_on_rounded, color: jneBlue, size: 100),
                ),
              ),
              const SizedBox(height: 60),
              FadeInUp(
                child: Text(
                  'Geofencing Pintar',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Absensi otomatis terdeteksi saat Anda berada di dalam radius kantor JNE.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 16, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Onboarding2())),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: jneBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('LANJUTKAN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
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
}