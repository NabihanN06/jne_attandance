import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../utils/app_strings.dart';
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
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenIndigo = Color(0xFFFF6B00); // primary = JNE orange (minimalis)

  late AnimationController _ctrl;
  late Animation<double> _scale;

  // ── Theme-aware colors ──
  bool get _isDark => context.read<AppProvider>().isDarkMode;
  Color get _bg => _isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC);
  Color get _card => _isDark ? const Color(0xFF15203A) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1E293B);
  Color get _textSub => _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  Color get _border => _isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9);

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
      backgroundColor: _bg,
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
                    color: zenEmerald.withValues(alpha: _isDark ? 0.16 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: zenEmerald, size: 64),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                widget.isEnroll ? context.tr('enroll_success_title') : context.tr('attendance_success_title'),
                style: GoogleFonts.outfit(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isEnroll ? context.tr('enroll_success_sub') : context.tr('attendance_success_sub'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: _textSub, fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 60),
              if (!widget.isEnroll)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: _isDark
                        ? null
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 40, offset: const Offset(0, 10))],
                    border: Border.all(color: _border, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      _row(context.tr('attendance_type'), widget.jenis),
                      _div(),
                      _row(context.tr('time_label'), _waktu),
                      _div(),
                      _row(context.tr('status_label'), widget.status, vc: zenEmerald),
                      _div(),
                      _row(context.tr('location'), widget.lokasi),
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
                    backgroundColor: zenIndigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text(context.tr('back_to_home'), style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())),
                child: Text(context.tr('view_full_history'), style: GoogleFonts.plusJakartaSans(color: _textSub, fontSize: 13, fontWeight: FontWeight.w700)),
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
        Text(l, style: GoogleFonts.outfit(color: _textSub, fontSize: 12, fontWeight: FontWeight.w700)),
        Text(v, style: GoogleFonts.outfit(color: vc ?? _textPrimary, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    ),
  );
  Widget _div() => Divider(color: _border, height: 1);
}
