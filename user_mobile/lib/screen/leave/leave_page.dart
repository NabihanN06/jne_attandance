import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_strings.dart';
import '../../widgets/ui_kit.dart';
import '../../widgets/package_loading.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  static const Color _accent = AppColors.jneOrange; // aksen utama = JNE orange

  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String _type = 'annual';
  // Foto surat dokter — WAJIB untuk tipe 'sick' (aturan operasional JNE).
  File? _attachment;

  // Tipe izin — value harus match dengan label di admin panel.
  static const List<({String value, String label, IconData icon, Color color})>
  _leaveTypes = [
    (
      value: 'annual',
      label: 'Cuti Tahunan',
      icon: Icons.event_available_rounded,
      color: Color(0xFF0EA5E9),
    ),
    (
      value: 'sick',
      label: 'Sakit',
      icon: Icons.healing_rounded,
      color: Color(0xFFEF4444),
    ),
    (
      value: 'permission',
      label: 'Izin Mendadak',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
    (
      value: 'personal',
      label: 'Keperluan Pribadi',
      icon: Icons.account_circle_rounded,
      color: Color(0xFF8B5CF6),
    ),
    (
      value: 'urgent',
      label: 'Keperluan Keluarga',
      icon: Icons.diversity_3_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  int get _workDays {
    if (_fromDate == null || _toDate == null) return 0;
    int count = 0;
    var d = _fromDate!;
    while (!d.isAfter(_toDate!)) {
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        count++;
      }
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  Future<void> _pickDate(bool isFrom) async {
    final isDark = context.read<AppProvider>().isDarkMode;
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
                  primary: _accent,
                  onPrimary: Colors.white,
                  surface: AppColors.darkCard,
                  onSurface: Colors.white,
                )
              : const ColorScheme.light(
                  primary: _accent,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF1E293B),
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> _pickAttachment() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 55,
    );
    if (picked == null || !mounted) return;
    setState(() => _attachment = File(picked.path));
  }

  // Label tipe izin terlokalisasi (value tetap dipakai untuk submit ke backend).
  String _leaveLabel(String value) {
    switch (value) {
      case 'annual':
        return context.tr('leave_annual');
      case 'sick':
        return context.tr('lt_sick');
      case 'permission':
        return context.tr('lt_permission');
      case 'personal':
        return context.tr('lt_personal');
      case 'urgent':
        return context.tr('lt_family');
      default:
        return value;
    }
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    if (_fromDate == null || _toDate == null) {
      showAppSnack(
        context,
        context.tr('pick_leave_date_first'),
        color: AppColors.brandRed,
      );
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnack(
        context,
        context.tr('reason_required'),
        color: AppColors.brandRed,
      );
      return;
    }
    if (_type == 'sick' && _attachment == null) {
      showAppSnack(
        context,
        context.tr('sick_letter_required'),
        color: AppColors.brandRed,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await provider.submitLeave(
        type: _type,
        startDate: _fromDate!,
        endDate: _toDate!,
        totalDays: _workDays,
        reason: _reasonCtrl.text.trim(),
        attachment: _attachment,
      );
      if (!mounted) return;
      showAppSnack(
        context,
        context.tr('leave_submitted'),
        color: AppColors.green,
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnack(
        context,
        '${context.tr('send_failed')}: ${e.toString().replaceAll('Exception: ', '')}',
        color: AppColors.brandRed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pal = context.palette;
    final balance = provider.leaveBalance;
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          context.tr('leave_request_title'),
          style: GoogleFonts.plusJakartaSans(
            color: pal.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _balanceSummary(balance),
          const SizedBox(height: 22),
          _buildSectionCard(
            title: context.tr('sec_leave_type').toUpperCase(),
            icon: Icons.category_rounded,
            pal: pal,
            child: LayoutBuilder(
              builder: (context, c) {
                // Lebar item = setengah, tinggi mengikuti konten (anti-overflow
                // di semua ukuran layar — beda dgn childAspectRatio yg kaku).
                final itemW = (c.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _leaveTypes.map((t) {
                    final selected = _type == t.value;
                    return SizedBox(
                      width: itemW,
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? t.color.withValues(
                                    alpha: pal.isDark ? 0.22 : 0.12,
                                  )
                                : pal.cardAlt,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected ? t.color : pal.border,
                              width: selected ? 1.6 : 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: t.color.withValues(
                                    alpha: selected ? 0.22 : 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(t.icon, color: t.color, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _leaveLabel(t.value),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: selected ? t.color : pal.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: t.color,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: context.tr('sec_leave_duration').toUpperCase(),
            icon: Icons.calendar_month_rounded,
            pal: pal,
            imageAsset: 'assets/images/iconapk/leaveduration.png',
            child: Column(
              children: [
                _dateField(
                  context.tr('from_date'),
                  _fmt(_fromDate),
                  () => _pickDate(true),
                  pal,
                ),
                const SizedBox(height: 18),
                _dateField(
                  context.tr('to_date'),
                  _fmt(_toDate),
                  () => _pickDate(false),
                  pal,
                ),
                if (_workDays > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: _accent,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${context.tr('total')}: $_workDays ${context.tr('workdays_counted')}',
                          style: GoogleFonts.plusJakartaSans(
                            color: _accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: context.tr('sec_leave_reason').toUpperCase(),
            icon: Icons.edit_note_rounded,
            pal: pal,
            child: TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: context.tr('reason_hint'),
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: pal.textFaint,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          // Surat dokter — hanya muncul & wajib untuk tipe Sakit.
          if (_type == 'sick') ...[
            const SizedBox(height: 20),
            _buildSectionCard(
              title: context.tr('sick_letter_title').toUpperCase(),
              icon: Icons.medical_information_rounded,
              pal: pal,
              child: GestureDetector(
                onTap: _pickAttachment,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: pal.cardAlt,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _attachment == null
                          ? AppColors.brandRed.withValues(alpha: 0.4)
                          : AppColors.green,
                      width: 1.4,
                    ),
                  ),
                  child: _attachment != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(_attachment!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo_rounded,
                              color: AppColors.brandRed,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('sick_letter_hint'),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: pal.textSub,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _loading ? null : _submit,
            child: Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const PackageLoading(isLight: true, size: 30)
                    : Text(
                        context.tr('submit_request_now').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Saldo cuti: hero navy (premium, readable di kedua tema) ──
  Widget _balanceSummary(LeaveBalance b) {
    final pal = context.palette;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: pal.heroDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('remaining_annual_leave'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${b.remainingAnnual}',
                          style: GoogleFonts.plusJakartaSans(
                            color: _accent,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 6),
                          child: Text(
                            '/ ${b.annualQuota} ${context.tr('days')}',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white60,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  color: _accent,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: b.usagePercent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: _accent,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat(context.tr('used2'), '${b.usedAnnual}'),
              _miniStat(context.tr('sick2'), '${b.usedSick}'),
              _miniStat(context.tr('permit'), '${b.usedPermission}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white60,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$value ${context.tr('days')}',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    required AppPalette pal,
    String? imageAsset,
  }) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              imageAsset != null
                  ? Image.asset(imageAsset, width: 22, height: 22)
                  : Icon(icon, color: _accent, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _dateField(
    String label,
    String val,
    VoidCallback onTap,
    AppPalette pal,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: pal.textSub,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: pal.cardAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: pal.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  val.isEmpty ? context.tr('pick_date') : val,
                  style: GoogleFonts.plusJakartaSans(
                    color: val.isEmpty ? pal.textFaint : pal.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.calendar_today_rounded,
                  color: _accent,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
