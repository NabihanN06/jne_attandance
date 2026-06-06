import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_kit.dart';

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
  int _selectedHours = 1;
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
    return p.myOvertimeRequests.any((o) => o.date == target && o.status != 'rejected');
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();

    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Mohon isi alasan lembur', color: AppColors.brandRed);
      return;
    }

    if (_hasRequestForSelectedDate(provider)) {
      showAppSnack(context, 'Sudah ada pengajuan lembur untuk tanggal ini.', color: AppColors.brandRed);
      return;
    }

    final projected = _approvedHoursThisMonth(provider) + _selectedHours;
    if (projected > _monthlyHourCap) {
      final sisa = (_monthlyHourCap - _approvedHoursThisMonth(provider)).clamp(0, _monthlyHourCap);
      showAppSnack(context, 'Melebihi batas $_monthlyHourCap jam/bulan. Sisa: $sisa jam.',
          color: AppColors.brandRed);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await provider.submitOvertime(
        date: _selectedDate,
        durationMinutes: _selectedHours * 60,
        reason: _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      showAppSnack(context, 'Pengajuan lembur terkirim', color: AppColors.green);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Gagal: ${e.toString().replaceAll('Exception: ', '')}',
          color: AppColors.brandRed);
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
        title: Text('Pengajuan Lembur',
            style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyUsageCard(pal),
            const SizedBox(height: 24),
            const SectionLabel('Tanggal Lembur'),
            _buildDateSelector(pal),
            const SizedBox(height: 22),
            const SectionLabel('Durasi (Jam)'),
            _buildHourSelector(pal),
            const SizedBox(height: 22),
            const SectionLabel('Alasan Lembur'),
            _buildReasonField(pal),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'KIRIM PENGAJUAN',
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
                'LEMBUR ${DateFormat('MMMM yyyy', 'id').format(_selectedDate).toUpperCase()}',
                style: GoogleFonts.plusJakartaSans(
                    color: _accent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$used',
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textPrimary, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
              Text(' / $_monthlyHourCap jam',
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textSub, fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(
                overLimit ? 'BATAS TERCAPAI' : 'sisa $remaining jam',
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
                      primary: _accent, onPrimary: Colors.white, surface: AppColors.darkCard, onSurface: Colors.white)
                  : const ColorScheme.light(
                      primary: _accent, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E293B)),
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
            Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: GoogleFonts.plusJakartaSans(
                    color: pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const Icon(Icons.calendar_today_rounded, color: _accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHourSelector(AppPalette pal) {
    return Row(
      children: List.generate(5, (index) {
        int hour = index + 1;
        bool isSelected = _selectedHours == hour;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHours = hour),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? _accent : pal.cardAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? _accent : pal.border),
              ),
              child: Center(
                child: Text('$hour',
                    style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.white : pal.textSub, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        );
      }),
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
            color: pal.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Contoh: Menyelesaikan pengiriman paket overload di area Martapura Kota.',
          hintStyle: GoogleFonts.plusJakartaSans(color: pal.textFaint, fontSize: 13, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
