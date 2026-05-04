import 'package:flutter/material.dart';
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
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
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
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('BERHASIL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), 
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(children: [
              FadeTransition(opacity: _fade,
                child: ScaleTransition(scale: _scale,
                  child: Container(width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1), 
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 2),
                    ),
                    child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 52)))),
              const SizedBox(height: 24),
              Text(widget.isEnroll ? 'Wajah Terdaftar!' : 'Absensi Berhasil!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(widget.isEnroll
                  ? 'Data biometrik Anda telah diverifikasi.'
                  : 'Sistem telah mencatat kehadiran Anda.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
            ]),
          ),
          if (!widget.isEnroll) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A), 
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(children: [
                _row('Tipe Log', widget.jenis), _div(),
                _row('Jam Operasional', _waktu), _div(),
                _row('Status', widget.status, vc: const Color(0xFF10B981)), _div(),
                _row('Titik Lokasi', widget.lokasi), _div(),
                _row('Regu Kerja', widget.shift),
              ]),
            ),
          ],
          const Spacer(),
          _Btn(label: 'KE BERANDA', color: const Color(0xFFE31E24),
              onTap: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
          const SizedBox(height: 12),
          _Btn(label: 'LIHAT RIWAYAT', color: Colors.transparent, border: Colors.white24,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }

  Widget _row(String l, String v, {Color? vc}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l.toUpperCase(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      Text(v, style: TextStyle(color: vc ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
    ]),
  );
  Widget _div() => Divider(color: Colors.white.withValues(alpha: 0.05), height: 1, indent: 20, endIndent: 20);
}

class FailedPage extends StatefulWidget {
  final String reason;
  const FailedPage({super.key, this.reason = 'Wajah tidak terverifikasi atau di luar radius.'});
  @override
  State<FailedPage> createState() => _FailedPageState();
}

class _FailedPageState extends State<FailedPage> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text('GAGAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(children: [
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), 
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
            ),
            child: Column(children: [
              ScaleTransition(scale: _scale,
                child: Container(width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1), 
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5), width: 2),
                  ),
                  child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 52))),
              const SizedBox(height: 24),
              const Text('Absensi Gagal!', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(widget.reason, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.6, fontWeight: FontWeight.w500)),
            ]),
          ),
          const Spacer(),
          _Btn(label: 'COBA LAGI', color: const Color(0xFFE31E24),
              onTap: () => Navigator.pop(context)),
          const SizedBox(height: 12),
          _Btn(label: 'KE BERANDA', color: Colors.transparent, border: Colors.white24,
              onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
          const SizedBox(height: 48),
        ]),
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  final String label; final Color color; final Color? border; final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap, this.border});
  @override
  State<_Btn> createState() => _BtnState();
}
class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) async { await _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(animation: _s, builder: (_, _) => Transform.scale(
        scale: _s.value,
        child: Container(
          width: double.infinity, height: 56,
          decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(16),
            border: widget.border != null ? Border.all(color: widget.border!) : null,
            boxShadow: widget.color != Colors.transparent
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6))] : null,
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
      )),
    );
  }
}