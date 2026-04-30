import 'package:flutter/material.dart';
import '../enroll/enroll_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Ganti dengan nama user dari__+ session/shared prefs
  static const String userName = 'Nabihan';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1F38),
        elevation: 0,
        title: const Text(
          'Welcome',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // Greeting
            Text(
              'Selamat Datang! $userName',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'JNE Martapura Attendance App',
              style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12),
            ),

            const SizedBox(height: 20),

            // Enroll card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Daftarkan Wajah Anda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('😎', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Untuk menggunakan fitur absensi, Anda perlu mendaftarkan wajah terlebih dahulu menggunakan kamera depan smartphone Anda.',
                    style: TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Persiapan card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'PERSIAPAN SEBELUM MULAI',
                    style: TextStyle(
                      color: Color(0xFF90A4AE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  SizedBox(height: 12),
                  _BulletItem(text: 'Lepas masker dan kacamata hitam'),
                  SizedBox(height: 6),
                  _BulletItem(text: 'Cari tempat dengan cahaya yang cukup'),
                  SizedBox(height: 6),
                  _BulletItem(
                    text: 'Posisikan wajah menghadap kamera dengan jelas',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const EnrollPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31E24),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lanjutkan ke Pendaftaran Wajah',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: Icon(Icons.circle, size: 6, color: Color(0xFF90A4AE)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF90A4AE),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
