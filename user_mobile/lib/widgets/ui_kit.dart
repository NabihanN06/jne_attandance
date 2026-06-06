import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// UI Kit — komponen reusable yang dipakai lintas layar.
/// Semua sadar tema lewat `context.palette`. Font default: Plus Jakarta Sans.
/// ─────────────────────────────────────────────────────────────────────────

TextStyle _jk({
  required double size,
  FontWeight weight = FontWeight.w600,
  Color? color,
  double? height,
  double? spacing,
}) =>
    GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: spacing,
    );

/// Tombol kembali bundar untuk app bar.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AppBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return IconButton(
      onPressed: onTap ?? () => Navigator.maybePop(context),
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: pal.textPrimary, size: 20),
    );
  }
}

/// Label section kecil ("INFORMASI AKUN").
class SectionLabel extends StatelessWidget {
  final String title;
  final EdgeInsets padding;
  const SectionLabel(this.title,
      {super.key, this.padding = const EdgeInsets.fromLTRB(6, 0, 6, 12)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title.toUpperCase(),
        style: _jk(
          size: 11.5,
          weight: FontWeight.w800,
          color: context.palette.textSub,
          spacing: 0.6,
        ),
      ),
    );
  }
}

/// Kartu standar dengan dekorasi palet.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final Color? color;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 22,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final content = Container(
      padding: padding,
      decoration: pal.cardDecoration(radius: radius, color: color),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Baris menu: ikon berwarna + judul + subjudul + chevron.
class AppActionRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  const AppActionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _jk(size: 14.5, weight: FontWeight.w700, color: pal.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: _jk(size: 11.5, weight: FontWeight.w500, color: pal.textSub)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: pal.textSub.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

/// Baris info read-only: ikon + label + value.
class AppInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const AppInfoRow({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: pal.textSub.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: pal.textSub, size: 19),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _jk(size: 11.5, weight: FontWeight.w600, color: pal.textSub)),
                const SizedBox(height: 3),
                Text(value, style: _jk(size: 14.5, weight: FontWeight.w700, color: pal.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pemisah tipis dalam kartu (indent supaya sejajar konten).
class AppRowDivider extends StatelessWidget {
  final double indent;
  const AppRowDivider({super.key, this.indent = 64});

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: context.palette.border, indent: indent);
}

/// Pill status kecil dengan ikon.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const StatusPill({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 5),
          ],
          Text(label, style: _jk(size: 11, weight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// Tombol utama lebar penuh dengan ikon + state loading.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color foreground;
  final VoidCallback? onTap;
  final bool loading;
  final double height;
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.brandRed,
    this.foreground = Colors.white,
    required this.onTap,
    this.loading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return GestureDetector(
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              onTap!();
            }
          : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.6,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, valueColor: AlwaysStoppedAnimation(foreground)),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: foreground, size: 19),
                        const SizedBox(width: 10),
                      ],
                      Text(label, style: _jk(size: 15.5, weight: FontWeight.w800, color: foreground)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Tampilan kosong yang rapi (untuk list tanpa data).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: pal.textSub.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: pal.textSub),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: _jk(size: 16, weight: FontWeight.w800, color: pal.textPrimary)),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: _jk(size: 13, weight: FontWeight.w500, color: pal.textSub, height: 1.5)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                color: AppColors.brandRed,
                height: 48,
                onTap: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Background polos & bersih (solid). Sengaja tanpa gradient/glow.
class AuroraBackground extends StatelessWidget {
  final Widget child;
  const AuroraBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.palette.auroraBase, child: child);
  }
}

/// Kartu solid bersih (tanpa gradient/blur) — dipakai lintas layar.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur; // disimpan demi kompatibilitas; tidak dipakai (look solid)
  final VoidCallback? onTap;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.blur = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: pal.border),
        boxShadow: pal.cardShadow,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        borderRadius: BorderRadius.circular(radius),
        child: card,
      ),
    );
  }
}

/// Helper snackbar konsisten.
SnackBar appSnack(String message, Color color) => SnackBar(
      content: Text(message, style: _jk(size: 13, weight: FontWeight.w700, color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

void showAppSnack(BuildContext context, String message, {Color color = AppColors.green}) {
  ScaffoldMessenger.of(context).showSnackBar(appSnack(message, color));
}
