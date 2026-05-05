import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home_screen.dart';
import '../history/history_page.dart';

class SucceedPage extends StatefulWidget {
  final bool isEnroll;
  final String jenis;
  final String waktu;
  final String status;
  final String lokasi;
  final String shift;

  const SucceedPage({
    super.key,
    this.isEnroll = false,
    this.jenis = 'Absen Masuk',
    this.waktu = '',
    this.status = 'Tepat Waktu ✓',
    this.lokasi = 'JNE Martapura | 25m',
    this.shift = 'Shift Pagi (08.00 - 16.00)',
  });

  @override
  State<SucceedPage> createState() => _SucceedPageState();
}

class _SucceedPageState extends State<SucceedPage> with SingleTickerProviderStateMixin {
  static const Color jneBlue = Color(0xFF005596);

  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String get _waktu {
    if (widget.waktu.isNotEmpty) return widget.waktu;
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')} WITA';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                widget.isEnroll ? 'Berhasil Terdaftar!' : 'Absensi Berhasil!',
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 24, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEnroll ? 'Wajah Anda kini aktif untuk absensi.' : 'Data kehadiran Anda telah tercatat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 48),
              if (!widget.isEnroll)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      _row('Tipe Log', widget.jenis),
                      _div(),
                      _row('Waktu', _waktu),
                      _div(),
                      _row('Status', widget.status, vc: Colors.green),
                      _div(),
                      _row('Lokasi', widget.lokasi),
                    ],
                  ),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: jneBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('KEMBALI KE BERANDA', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                child: Text('LIHAT RIWAYAT', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String l, String v, {Color? vc}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w700)),
        Text(v, style: GoogleFonts.outfit(color: vc ?? const Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    ),
  );
  Widget _div() => const Divider(color: Color(0xFFF1F5F9), height: 1);
}