import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  static const Color _primary = Color(0xFFE31E24); // JNE Red
  static const Color _bg = Color(0xFFF8FAFC); // Clean Slate White
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  static const List<Map<String, dynamic>> _leaveTypes = [
    {
      'value': 'sick',
      'label': 'Sakit',
      'icon': Icons.medical_services_outlined,
      'desc': 'Izin Pemulihan Medis',
      'color': Color(0xFFF43F5E)
    },
    {
      'value': 'annual',
      'label': 'Cuti',
      'icon': Icons.beach_access_outlined,
      'desc': 'Rehat Tahunan',
      'color': Color(0xFF3B82F6)
    },
    {
      'value': 'personal',
      'label': 'Izin Pribadi',
      'icon': Icons.person_outline_rounded,
      'desc': 'Urusan Mendesak',
      'color': Color(0xFFF59E0B)
    },
    {
      'value': 'urgent',
      'label': 'Keluarga',
      'icon': Icons.family_restroom_rounded,
      'desc': 'Keperluan Keluarga',
      'color': Color(0xFF8B5CF6)
    },
  ];

  String _selectedType = 'sick';
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

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
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  String _fmt(DateTime? d) => d == null ? 'Pilih' : DateFormat('dd MMM yyyy').format(d);

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? (DateTime.now()) : (_fromDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primary,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _textPrimary,
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
          if (_fromDate != null && picked.isBefore(_fromDate!)) return;
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_fromDate == null || _toDate == null) {
      _snack('Pilih rentang tanggal permohonan', isError: true);
      return;
    }
    if (_reasonCtrl.text.trim().length < 5) {
      _snack('Berikan alasan yang jelas', isError: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().submitLeave(
            type: _selectedType,
            startDate: _fromDate!,
            endDate: _toDate!,
            totalDays: _workDays,
            reason: _reasonCtrl.text.trim(),
          );
      if (mounted) {
        _snack('Permohonan berhasil dikirim', isSuccess: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      backgroundColor: isSuccess ? const Color(0xFF10B981) : (isError ? _primary : _textPrimary),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10)],
                ),
                child: const Icon(Icons.chevron_left_rounded, color: _textPrimary, size: 24),
              ),
            ),
          ),
        ),
        title: Text(
          'Pengajuan Izin',
          style: GoogleFonts.plusJakartaSans(
            color: _textPrimary, 
            fontWeight: FontWeight.w900, 
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: _sectionHeader('Pilih Jenis Izin', 'Pilih kategori yang sesuai dengan alasan Anda'),
            ),
            const SizedBox(height: 20),
            
            // Bento Grid for Leave Types
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: _leaveTypes.length,
              itemBuilder: (context, index) {
                final type = _leaveTypes[index];
                final isSelected = _selectedType == type['value'];
                return FadeInUp(
                  delay: Duration(milliseconds: index * 100),
                  child: _bentoItem(type, isSelected),
                );
              },
            ),

            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _sectionHeader('Periode Izin', 'Tentukan kapan Anda akan mulai dan berakhir'),
            ),
            const SizedBox(height: 16),
            
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _datePickerField('Mulai', _fromDate, () => _pickDate(true))),
                        const SizedBox(width: 20),
                        Expanded(child: _datePickerField('Selesai', _toDate, () => _pickDate(false))),
                      ],
                    ),
                    if (_fromDate != null && _toDate != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Durasi Izin', style: GoogleFonts.outfit(color: _textSecondary, fontSize: 10, fontWeight: FontWeight.w700, uppercase: true, letterSpacing: 1)),
                                const SizedBox(height: 2),
                                Text(
                                  '$_workDays Hari Kerja',
                                  style: GoogleFonts.plusJakartaSans(color: _textPrimary, fontWeight: FontWeight.w900, fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: _sectionHeader('Alasan', 'Berikan penjelasan singkat dan jelas'),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              delay: const Duration(milliseconds: 700),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: TextField(
                  controller: _reasonCtrl,
                  maxLines: 4,
                  style: GoogleFonts.plusJakartaSans(color: _textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Tuliskan alasan pengajuan Anda secara detail...',
                    hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                    contentPadding: const EdgeInsets.all(28),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: _primary.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded, size: 18),
                            const SizedBox(width: 12),
                            Text('Submit Pengajuan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.2)),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.plusJakartaSans(color: _textPrimary, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)),
        const SizedBox(height: 6),
        Text(sub, style: GoogleFonts.outfit(color: _textSecondary, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1)),
      ],
    );
  }

  Widget _bentoItem(Map<String, dynamic> type, bool isSelected) {
    final Color color = type['color'];
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type['value']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 10))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(type['icon'], color: isSelected ? Colors.white : color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type['label'],
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? Colors.white : _textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type['desc'],
                  style: GoogleFonts.outfit(
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _datePickerField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.outfit(color: _textSecondary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, uppercase: true)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: date != null ? _primary : _textSecondary, size: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _fmt(date),
                    style: GoogleFonts.plusJakartaSans(
                      color: date != null ? _textPrimary : _textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
