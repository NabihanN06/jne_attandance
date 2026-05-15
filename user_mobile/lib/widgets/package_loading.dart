import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

class PackageLoading extends StatelessWidget {
  final String? message;
  final bool isLight;
  final double size;

  const PackageLoading({
    super.key, 
    this.message,
    this.isLight = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final double iconSize = size * 0.5;
    final Color mainColor = isLight ? Colors.white : const Color(0xFFE31E24);
    final Color textColor = isLight ? Colors.white70 : const Color(0xFF64748B);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating outer ring
              Spin(
                infinite: true,
                duration: const Duration(seconds: 3),
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mainColor.withValues(alpha: 0.1),
                      width: size * 0.05,
                    ),
                  ),
                ),
              ),
              // Bouncing Package Icon
              Bounce(
                infinite: true,
                from: size * 0.18,
                duration: const Duration(milliseconds: 1500),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: iconSize,
                  color: mainColor,
                ),
              ),
              // Tiny pulse dots around
              Pulse(
                infinite: true,
                child: Container(
                  width: size * 1.12,
                  height: size * 1.12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: mainColor.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 24),
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: Text(
                message!.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
