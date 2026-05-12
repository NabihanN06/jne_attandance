import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';

class OvertimePage extends StatefulWidget {
  const OvertimePage({super.key});

  @override
  State<OvertimePage> createState() => _OvertimePageState();
}

class _OvertimePageState extends State<OvertimePage> {
  // Premium Color Palette
  static const Color zenCream   = Color(0xFFF9F7F2);
  static const Color zenNavy    = Color(0xFF0F172A);
  static const Color zenIndigo  = Color(0xFF4F46E5);
  static const Color zenAmber   = Color(0xFFF59E0B);
  static const Color zenSlate   = Color(0xFF64748B);
  static const Color zenRose    = Color(0xFFF43F5E);
  static const Color zenGreen   = Color(0xFF10B981);

  DateTime _selectedDate = DateTime.now();
  int _selectedHours = 1;
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      _showFeedback('Mohon isi alasan lembur', zenRose);
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await context.read<AppProvider>().submitOvertime(
        date: _selectedDate,
        durationMinutes: _selectedHours * 60,
        reason: _reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      _showFeedback('Pengajuan lembur berhasil dikirim!', zenGreen);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showFeedback('Gagal: $e', zenRose);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFeedback(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zenCream,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _buildWelcomeHeader(),
            ),
            const SizedBox(height: 32),

            // Bento Grid for Inputs
            FadeInUp(
              duration: const Duration(milliseconds: 500),
              child: _buildBentoInputSection(),
            ),
            const SizedBox(height: 24),

            // Duration Selector
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildDurationSection(),
            ),
            const SizedBox(height: 24),

            // Reason Field
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              child: _buildReasonSection(),
            ),
            const SizedBox(height: 48),

            // Submit Button
            FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: _buildSubmitButton(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: zenCream,
      elevation: 0,
      centerTitle: true,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
            ),
            child: const Icon(Icons.chevron_left_rounded, color: zenNavy, size: 28),
          ),
        ),
      ),
      title: Text(
        'LEMBUR',
        style: GoogleFonts.outfit(
          color: zenNavy,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extra Efforts,',
          style: GoogleFonts.outfit(
            color: zenSlate,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Pengajuan Lembur',
          style: GoogleFonts.outfit(
            color: zenNavy,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: zenAmber,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildBentoInputSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('TANGGAL PENGAJUAN', Icons.calendar_today_rounded),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 3)),
                lastDate: DateTime.now().add(const Duration(days: 14)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: zenIndigo),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: zenCream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: zenIndigo, size: 22),
                  const SizedBox(width: 16),
                  Text(
                    '${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                    style: GoogleFonts.outfit(
                      color: zenNavy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: zenSlate, size: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('DURASI KERJA', Icons.timer_outlined),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              final hour = index + 1;
              final isSelected = _selectedHours == hour;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedHours = hour);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? zenIndigo : zenCream,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? zenIndigo : zenNavy.withValues(alpha: 0.05),
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: zenIndigo.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '$hour',
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : zenNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Total: $_selectedHours Jam',
              style: GoogleFonts.outfit(
                color: zenSlate,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel('ALASAN LEMBUR', Icons.edit_note_rounded),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: zenCream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: zenNavy.withValues(alpha: 0.05)),
            ),
            child: TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              style: GoogleFonts.outfit(
                color: zenNavy,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'Tuliskan detail pekerjaan lembur...',
                hintStyle: GoogleFonts.outfit(
                  color: zenSlate.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: zenSlate),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: zenSlate,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: zenNavy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 8,
          shadowColor: zenNavy.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              )
            : Text(
                'KIRIM PENGAJUAN',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[m - 1];
  }
}
