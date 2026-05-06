import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  
  DateTime _selectedDate = DateTime.now();
  int _selectedHours = 1;
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_reasonCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon isi alasan lembur')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AppProvider>().submitOvertime(_selectedDate, _selectedHours, _reasonCtrl.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan lembur berhasil dikirim!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: jneRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
