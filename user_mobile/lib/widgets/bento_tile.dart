import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class BentoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final Color? color;
  final VoidCallback onTap;
  final bool isLarge;

  const BentoTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.color,
    required this.onTap,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    // ── ZEN PREMIUM CONSTANTS ──
    const zenNavy = Color(0xFF121826);
    const zenGrey = Color(0xFF94A3B8);
    const zenIndigo = Color(0xFF4F46E5);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.all(isLarge ? 24 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: zenNavy.withValues(alpha: 0.03),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: isLarge 
            ? _buildLargeLayout(zenNavy, zenGrey, zenIndigo) 
            : _buildSmallLayout(zenNavy, zenGrey, zenIndigo),
      ),
    );
  }

  Widget _buildLargeLayout(Color navy, Color grey, Color indigo) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: (color ?? indigo).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.chevron_right_rounded, color: grey.withValues(alpha: 0.4), size: 22),
      ],
    );
  }

  Widget _buildSmallLayout(Color navy, Color grey, Color indigo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: (color ?? indigo).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: navy,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            color: grey,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
