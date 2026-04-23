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
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(title: const Text('Attendance Succed'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              FadeTransition(opacity: _fade,
                child: ScaleTransition(scale: _scale,
                  child: Container(width: 90, height: 90,
                    decoration: const BoxDecoration(color: Color(0xFF1B5E20), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: Colors.white, size: 52)))),
              const SizedBox(height: 24),
              Text(widget.isEnroll ? 'Wajah Berhasil\nDidaftarkan!' : 'Absensi Berhasil !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
              const SizedBox(height: 10),
              Text(widget.isEnroll
                  ? 'Sekarang Anda bisa menggunakan fitur absensi dengan scan wajah.'
                  : 'Kamu datang tepat waktu hari ini.\nSemangat kerja! 💪',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13, height: 1.6)),
            ]),
          ),
          if (!widget.isEnroll) ...[
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
              child: Column(children: [
                _row('Jenis', widget.jenis), _div(),
                _row('Waktu', _waktu), _div(),
                _row('Status', widget.status, vc: const Color(0xFF4CAF50)), _div(),
                _row('Lokasi', widget.lokasi), _div(),
                _row('Shift', widget.shift),
              ]),
            ),
          ],
          const Spacer(),
          _Btn(label: 'Kembali Ke Beranda', color: const Color(0xFFE31E24),
              onTap: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
          if (!widget.isEnroll) ...[
            const SizedBox(height: 10),
            _Btn(label: 'Lihat Riwayat Absensi', color: Colors.transparent, border: Colors.white54,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _row(String l, String v, {Color? vc}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
      Text(v, style: TextStyle(color: vc ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
  Widget _div() => const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16, endIndent: 16);
}

class FailedPage extends StatefulWidget {
  final String reason;
  const FailedPage({super.key, this.reason = 'Wajah tidak sesuai dengan yang didaftarkan / jarak kamu dari kantor diluar radius'});
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
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(title: const Text('Attendance Failed'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ScaleTransition(scale: _scale,
                child: Container(width: 90, height: 90,
                  decoration: const BoxDecoration(color: Color(0xFFB71C1C), shape: BoxShape.circle),
                  child: const Icon(Icons.close, color: Colors.white, size: 52))),
              const SizedBox(height: 24),
              const Text('Absensi Gagal !', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(widget.reason, textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13, height: 1.6)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _r('Jenis','-'), _d(), _r('Waktu','-'), _d(), _r('Status','-'), _d(), _r('Lokasi','-'), _d(), _r('Shift','-'),
            ]),
          ),
          const Spacer(),
          _Btn(label: 'Kembali Ke Beranda', color: const Color(0xFFE31E24),
              onTap: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false)),
          const SizedBox(height: 10),
          _Btn(label: 'Lihat Riwayat Absensi', color: Colors.transparent, border: Colors.white54,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()))),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }
  Widget _r(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 13)),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]),
  );
  Widget _d() => const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16, endIndent: 16);
}

// ── Shared Pressable Button ───────────────────
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
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(10),
            border: widget.border != null ? Border.all(color: widget.border!) : null,
            boxShadow: widget.color != Colors.transparent
                ? [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      )),
    );
  }
}