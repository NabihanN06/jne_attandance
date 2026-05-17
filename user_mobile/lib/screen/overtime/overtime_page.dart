import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
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
    final messenger = ScaffoldMessenger.of(context);

    if (_reasonCtrl.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(
        content: Text('Mohon isi alasan lembur', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: jneRed,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    if (_hasRequestForSelectedDate(provider)) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Sudah ada pengajuan lembur untuk tanggal ini.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: jneRed,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final projected = _approvedHoursThisMonth(provider) + _selectedHours;
    if (projected > _monthlyHourCap) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Melebihi batas $_monthlyHourCap jam/bulan. Sisa: ${(_monthlyHourCap - _approvedHoursThisMonth(provider)).clamp(0, _monthlyHourCap)} jam.',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: jneRed,
        behavior: SnackBarBehavior.floating,
      ));
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
      messenger.showSnackBar(SnackBar(
        content: Text('Pengajuan lembur terkirim', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal: $e', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        backgroundColor: jneRed,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : Colors.white,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        title: Text('PENGAJUAN LEMBUR', style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthlyUsageCard(),
            const SizedBox(height: 24),
            _buildLabel('TANGGAL LEMBUR'),
            const SizedBox(height: 12),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildLabel('DURASI (JAM)'),
            const SizedBox(height: 12),
            _buildHourSelector(),
            const SizedBox(height: 24),
            _buildLabel('ALASAN LEMBUR'),
            const SizedBox(height: 12),
            _buildReasonField(),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyUsageCard() {
    final provider = context.watch<AppProvider>();
    final used = _approvedHoursThisMonth(provider);
    final remaining = (_monthlyHourCap - used).clamp(0, _monthlyHourCap);
    final ratio = (used / _monthlyHourCap).clamp(0.0, 1.0);
    final overLimit = used >= _monthlyHourCap;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: jneBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: jneBlue.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overLimit ? Icons.warning_amber_rounded : Icons.timer_rounded,
                color: overLimit ? jneRed : jneBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'LEMBUR ${DateFormat('MMMM yyyy', 'id').format(_selectedDate).toUpperCase()}',
                style: GoogleFonts.outfit(color: jneBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
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
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
              Text(
                ' / $_monthlyHourCap jam',
                style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                overLimit ? 'BATAS TERCAPAI' : 'sisa $remaining jam',
                style: GoogleFonts.outfit(
                  color: overLimit ? jneRed : const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
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
              backgroundColor: Colors.white,
              color: overLimit ? jneRed : jneBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String t) => Text(t, style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5));

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 7)), lastDate: DateTime.now().add(const Duration(days: 30)));
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w700)),
            const Icon(Icons.calendar_today_rounded, color: jneBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHourSelector() {
    return Row(
      children: List.generate(5, (index) {
        int hour = index + 1;
        bool isSelected = _selectedHours == hour;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedHours = hour),
            child: Container(
              margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? jneBlue : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('$hour', style: GoogleFonts.outfit(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: _reasonCtrl,
        maxLines: 4,
        style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Contoh: Menyelesaikan pengiriman paket overload di area Martapura Kota.',
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: jneBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text('KIRIM PENGAJUAN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }
}
