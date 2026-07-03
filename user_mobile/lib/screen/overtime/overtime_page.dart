import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';
import '../../utils/app_strings.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  static const Color _accent = AppColors.blue;
  // Batas wajar lembur per bulan (40 jam ≈ standar industri).
  static const int _monthlyHourCap = 40;

  DateTime _selectedDate = DateTime.now();
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  /// Total jam lembur yang sudah diajukan/approve untuk bulan tanggal yang dipilih.
  int _approvedHoursThisMonth(AppProvider p) {
    return p.myOvertimeRequests
        .where((o) {
          final d = DateTime.tryParse(o.date);
          return d != null &&
              d.year == _selectedDate.year &&
              d.month == _selectedDate.month &&
              o.status != 'rejected';
        })
        .fold(0, (sum, o) => sum + o.overtimeHours);
  }

  bool _hasRequestForSelectedDate(AppProvider p) {
    final target = DateFormat('yyyy-MM-dd').format(_selectedDate);
    return p.myOvertimeRequests.any(
      (o) => o.date == target && o.status != 'rejected',
    );
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();

    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnack(
        context,
        context.tr('fill_overtime_reason'),
        color: AppColors.brandRed,
      );
      return;
    }

    if (_hasRequestForSelectedDate(provider)) {
      showAppSnack(
        context,
        context.tr('ot_exists_for_date'),
        color: AppColors.brandRed,
      );
      return;
    }

    final submittedMsg = context.tr('overtime_submitted');
    final failPre = context.tr('fail_prefix');
    setState(() => _isLoading = true);
    try {
      await provider.submitOvertime(
        date: _selectedDate,
        durationMinutes: 0, // jam lembur DITENTUKAN admin saat menyetujui
        reason: _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, submittedMsg, color: AppColors.green);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(
        context,
        '$failPre: ${e.toString().replaceAll('Exception: ', '')}',
        color: AppColors.brandRed,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    return Scaffold(
      backgroundColor: pal.bg,
      appBar: AppBar(
        backgroundColor: pal.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: const AppBackButton(),
        title: Text(
          context.tr('overtime_request_title'),
          style: GoogleFonts.plusJakartaSans(
            color: pal.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyUsageCard(pal),
            const SizedBox(height: 24),
            SectionLabel(context.tr('ot_date')),
            _buildDateSelector(pal),
            const SizedBox(height: 22),
            _buildAdminHoursNote(pal),
            const SizedBox(height: 22),
            SectionLabel(context.tr('ot_reason')),
            _buildReasonField(pal),
            const SizedBox(height: 32),
            PrimaryButton(
              label: context.tr('submit_request').toUpperCase(),
              icon: Icons.send_rounded,
              color: _accent,
              height: 56,
              loading: _isLoading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyUsageCard(AppPalette pal) {
    final provider = context.watch<AppProvider>();
    final used = _approvedHoursThisMonth(provider);
    final remaining = (_monthlyHourCap - used).clamp(0, _monthlyHourCap);
    final ratio = (used / _monthlyHourCap).clamp(0.0, 1.0);
    final overLimit = used >= _monthlyHourCap;
    return AppCard(
      radius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overLimit ? Icons.warning_amber_rounded : Icons.timer_rounded,
                color: overLimit ? AppColors.brandRed : _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${context.tr('overtime_word').toUpperCase()} ${DateFormat('MMMM yyyy', context.read<AppProvider>().language).format(_selectedDate).toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                  color: _accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$used',
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                ' / $_monthlyHourCap ${context.tr('hours_word')}',
                style: GoogleFonts.plusJakartaSans(
                  color: pal.textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                overLimit
                    ? context.tr('limit_reached').toUpperCase()
                    : '${context.tr('remaining')} $remaining ${context.tr('hours_word')}',
                style: GoogleFonts.plusJakartaSans(
                  color: overLimit ? AppColors.brandRed : AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: pal.cardAlt,
              color: overLimit ? AppColors.brandRed : _accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector(AppPalette pal) {
    return GestureDetector(
      onTap: () async {
        final isDark = pal.isDark;
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 7)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
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
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: pal.cardAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: pal.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.calendar_today_rounded, color: _accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminHoursNote(AppPalette pal) {
    return AppCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ini pengajuan SPL (Surat Perintah Lembur). Ajukan SEBELUM absen '
              'pulang. Setelah disetujui atasan, durasi lembur dihitung OTOMATIS '
              'dari jam absen pulang kamu (maksimal 4 jam/hari). Pulang telat '
              'tanpa SPL tidak dihitung lembur. Khusus hari Minggu/libur, semua '
              'jam kerja otomatis dihitung lembur tanpa perlu SPL.',
              style: GoogleFonts.plusJakartaSans(
                color: pal.textSub,
                fontSize: 12.5,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonField(AppPalette pal) {
    return Container(
      decoration: BoxDecoration(
        color: pal.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pal.border),
      ),
      child: TextField(
        controller: _reasonCtrl,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        style: GoogleFonts.plusJakartaSans(
          color: pal.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: context.tr('ot_reason_hint'),
          hintStyle: GoogleFonts.plusJakartaSans(
            color: pal.textFaint,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
