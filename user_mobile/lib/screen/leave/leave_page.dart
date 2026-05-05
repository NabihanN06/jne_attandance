import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  static const Color jneBlue = Color(0xFF005596);
  static const Color jneRed = Color(0xFFE31E24);
  static const Color bgLight = Color(0xFFF8FAFC);

  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

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

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: jneBlue, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) { _fromDate = picked; if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked; }
        else { _toDate = picked; }
      });
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    if (_fromDate == null || _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal izin terlebih dahulu'), backgroundColor: jneRed));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan izin tidak boleh kosong'), backgroundColor: jneRed));
      return;
    }
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final req = LeaveRequest(
      id: 'leave_${DateTime.now().millisecondsSinceEpoch}',
      userId: provider.currentUser!.uid,
      userName: provider.currentUser!.name,
      fromDate: _fromDate!,
      toDate: _toDate!,
      reason: _reasonCtrl.text.trim(),
      submittedAt: DateTime.now(),
    );
    provider.submitLeave(req);
    
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan izin berhasil dikirim!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: jneBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AJUKAN IZIN',
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Pilih Tanggal'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _dateField('Mulai Tanggal', _fmt(_fromDate), () => _pickDate(true)),
                  const SizedBox(height: 20),
                  _dateField('Sampai Tanggal', _fmt(_toDate), () => _pickDate(false)),
                  if (_workDays > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text('Total: $_workDays Hari Kerja', style: GoogleFonts.outfit(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            _buildSectionTitle('Alasan Izin'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _reasonCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan lengkap Anda di sini...',
                  hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 14),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.outfit(color: const Color(0xFF1E293B), fontSize: 14),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: jneBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('KIRIM PENGAJUAN', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String t) {
    return Text(t.toUpperCase(), style: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1));
  }

  Widget _dateField(String label, String val, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(val.isEmpty ? 'Pilih Tanggal' : val, style: GoogleFonts.outfit(color: val.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w700)),
                const Icon(Icons.calendar_today_rounded, color: jneBlue, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}