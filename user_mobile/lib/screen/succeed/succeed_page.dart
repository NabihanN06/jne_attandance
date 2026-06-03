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
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenEmerald = Color(0xFF10B981);

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
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: zenEmerald.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: zenEmerald, size: 64),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                widget.isEnroll ? 'Wajah Terdaftar' : 'Absensi Berhasil',
                style: GoogleFonts.outfit(color: zenNavy, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEnroll ? 'Data wajah Anda sudah aktif.' : 'Data absensi berhasil tersimpan.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 60),
              if (!widget.isEnroll)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [BoxShadow(color: zenNavy.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
                    border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _row('Jenis Absen', widget.jenis),
                      _div(),
                      _row('Waktu', _waktu),
                      _div(),
                      _row('Status', widget.status, vc: zenEmerald),
                      _div(),
                      _row('Lokasi', widget.lokasi),
                    ],
                  ),
                ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: zenNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text('Kembali ke Beranda', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                child: Text('Lihat Riwayat Lengkap', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w700)),
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