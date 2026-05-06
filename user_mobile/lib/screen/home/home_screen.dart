import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../utils/geofence_service.dart';
import '../../utils/connectivity_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color jneRose = Color(0xFFE11D48);
  int _selectedIndex = 0;
  
  // Weather logic colors
  List<Color> _getHeaderGradient() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)]; // Morning Bright
    } else if (hour >= 11 && hour < 15) {
      return [const Color(0xFF0284C7), const Color(0xFF0EA5E9)]; // Noon
    } else if (hour >= 15 && hour < 18) {
      return [const Color(0xFFF97316), const Color(0xFFFB923C)]; // Evening Sunset
    } else {
      return [const Color(0xFF0F172A), const Color(0xFF334155)]; // Night / Nexus Slate
    }
  }

  IconData _getWeatherIcon() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 18) return Icons.wb_sunny_rounded;
    return Icons.nights_stay_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final geo = context.watch<GeofenceService>();
    final conn = context.watch<ConnectivityService>();

    const Color jneRose = Color(0xFFE11D48);
    const Color slate950 = Color(0xFF0F172A);
    const Color jneGrey = Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // ── DYNAMIC WEATHER HEADER ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340,
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getHeaderGradient(),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 40,
                    right: -20,
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(_getWeatherIcon(), size: 200, color: Colors.white),
                    ),
                  ),
                  CustomPaint(painter: WavePainter(), child: Container()),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── TOP BAR ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FadeInLeft(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SELAMAT ${DateTime.now().hour < 11 ? "PAGI" : DateTime.now().hour < 15 ? "SIANG" : DateTime.now().hour < 18 ? "SORE" : "MALAM"},',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.currentUser?.name.toUpperCase() ?? 'COURIER',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              Navigator.pushNamed(context, '/chat');
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildConnIndicator(conn),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // ── BENTO MAIN TILE: WORK HOURS ──
                        FadeInDown(
                          duration: const Duration(milliseconds: 800),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(40),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SISA JAM KERJA',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: jneGrey,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '04:20:15',
                                      style: GoogleFonts.outfit(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: jneRose.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        'Target: 08:00 Jam',
                                        style: GoogleFonts.outfit(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: jneRose,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                _buildProgressCircle(0.6, jneRose),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── BENTO GRID WITH STAGGERED ENTRANCE ──
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: FadeInLeft(
                                delay: const Duration(milliseconds: 200),
                                child: _buildBigBentoTile(
                                  context,
                                  'ABSEN\nMASUK',
                                  geo.isInRange ? 'Ditemukan: Hub Martapura' : 'Diluar area jangkauan',
                                  geo.isInRange ? Icons.fingerprint_rounded : Icons.location_disabled_rounded,
                                  geo.isInRange ? jneRose : jneGrey,
                                  () {
                                    HapticFeedback.heavyImpact();
                                    if (geo.isInRange) {
                                      Navigator.pushNamed(context, '/attendance');
                                    } else {
                                      _showError(context, 'Anda harus berada di area Hub Martapura!');
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  FadeInRight(
                                    delay: const Duration(milliseconds: 300),
                                    child: _buildSmallBentoTile(
                                      context,
                                      'IZIN',
                                      Icons.event_note_rounded,
                                      Colors.orange,
                                      () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.pushNamed(context, '/leave');
                                      },
                                      isSquare: true,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FadeInRight(
                                    delay: const Duration(milliseconds: 400),
                                    child: _buildSmallBentoTile(
                                      context,
                                      'LEMBUR',
                                      Icons.auto_awesome_rounded,
                                      const Color(0xFF10B981),
                                      () {
                                        HapticFeedback.mediumImpact();
                                        Navigator.pushNamed(context, '/overtime');
                                      },
                                      isSquare: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: FadeInUp(
                                delay: const Duration(milliseconds: 500),
                                child: _buildSmallBentoTile(
                                  context,
                                  'RIWAYAT',
                                  Icons.history_edu_rounded,
                                  slate950,
                                  () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, '/history');
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FadeInUp(
                                delay: const Duration(milliseconds: 600),
                                child: _buildSmallBentoTile(
                                  context,
                                  'STATS',
                                  Icons.analytics_rounded,
                                  const Color(0xFF8B5CF6),
                                  () {
                                    HapticFeedback.lightImpact();
                                    Navigator.pushNamed(context, '/statistic');
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── SALARY ESTIMATOR ──
                        FadeInUp(
                          delay: const Duration(milliseconds: 700),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.1),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.payments_rounded, color: Colors.white, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ESTIMASI GAJI BULAN INI',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white.withValues(alpha: 0.5),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      Text(
                                        'Rp 3.450.000',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 100), 
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // ── FLOATING SOS WITH LONG PRESS ──
          Positioned(
            bottom: 110,
            right: 24,
            child: FadeInRight(
              delay: const Duration(milliseconds: 1000),
              child: _buildSOSFloatingButton(p, geo),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(p),
      extendBody: true,
    );
  }

  Widget _buildProgressCircle(double value, Color color) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 85,
          height: 85,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 10,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '${(value * 100).toInt()}%',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSOSFloatingButton(AppProvider p, GeofenceService geo) {
    return GestureDetector(
      onLongPressStart: (_) {
        HapticFeedback.vibrate();
        // Start long press logic if needed
      },
      onLongPress: () {
        HapticFeedback.heavyImpact();
        _triggerSOS(context, p, geo);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: jneRose,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: jneRose.withValues(alpha: 0.4),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.sos_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildBigBentoTile(BuildContext context, String label, String sub, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 34),
            ),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                height: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              sub.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBentoTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap, {bool isSquare = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 102,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: isSquare ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            if (!isSquare) ...[
              const Spacer(),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E293B),
                  letterSpacing: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _triggerSOS(BuildContext context, AppProvider p, GeofenceService geo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: const Color(0xFFFFEBEB), shape: BoxShape.circle),
              child: const Icon(Icons.warning_rounded, color: Color(0xFFE31E24), size: 40),
            ),
            const SizedBox(height: 24),
            Text('KONFIRMASI SOS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 12),
            Text(
              'Sinyal darurat akan dikirimkan ke Admin beserta lokasi Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 14),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('BATAL', style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (geo.currentPosition != null) {
                        p.sendSOS(
                          geo.currentPosition!.latitude,
                          geo.currentPosition!.longitude,
                          'Martapura Hub Area',
                        );
                      }
                      Navigator.pop(ctx);
                      _showError(context, '🚨 Sinyal SOS Terkirim!');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('KIRIM', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppProvider p) {
    return Container(
      margin: const EdgeInsets.all(24),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_filled, 'Home', p),
          _buildNavItem(1, Icons.notifications_rounded, 'Alerts', p),
          _buildNavItem(2, Icons.person_rounded, 'Profile', p),
          _buildNavItem(3, Icons.widgets_rounded, 'More', p),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, AppProvider p) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (index == 2) { Navigator.pushNamed(context, '/profile'); return; }
        if (index == 1) { Navigator.pushNamed(context, '/notification'); return; }
        if (index == 3) { Navigator.pushNamed(context, '/option'); return; }
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.white38, size: 24),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnIndicator(ConnectivityService conn) {
    bool isOnline = conn.status != ConnectionStatus.none;
    return FadeInRight(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: isOnline ? Colors.greenAccent : Colors.redAccent),
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? 'ONLINE' : 'OFFLINE',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final y = 60.0 + (i * 35);
      path.moveTo(0, y);
      for (var x = 0.0; x <= size.width; x += 25) {
        path.lineTo(x, y + (x % 50 == 0 ? 12 : -12));
      }
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
