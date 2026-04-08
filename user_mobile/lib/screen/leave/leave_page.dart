import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  String? _docName;
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
          colorScheme: const ColorScheme.dark(primary: Color(0xFFE31E24), surface: Color(0xFF0D1F38)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) { _fromDate = picked; if (_toDate != null && _toDate!.isBefore(picked)) _toDate = picked; }
        else _toDate = picked;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih tanggal izin terlebih dahulu'), backgroundColor: Color(0xFFB71C1C)));
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan izin tidak boleh kosong'), backgroundColor: Color(0xFFB71C1C)));
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
    provider.addNotification(
      '📋 Pengajuan Izin Baru',
      '${provider.currentUser!.name} mengajukan izin ${_fmt(_fromDate)} - ${_fmt(_toDate)}',
      targetUserId: 'admin_001',
    );
    provider.addNotification(
      '✅ Izin Terkirim',
      'Pengajuan izinmu sudah dikirim dan sedang diproses Admin HR',
      targetUserId: provider.currentUser!.uid,
    );

    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('Pengajuan izin berhasil dikirim!'),
        ]),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Ajukan Izin'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 8),

          // Tanggal Izin
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tanggal Izin', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text('Dari Tanggal', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
            const SizedBox(height: 6),
            _datePicker(_fmt(_fromDate), () => _pickDate(true)),
            const SizedBox(height: 12),
            const Text('Sampai Tanggal', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
            const SizedBox(height: 6),
            _datePicker(_fmt(_toDate), () => _pickDate(false)),
            if (_workDays > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFFF57C00), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.circle, size: 8, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('$_workDays hari kerja dipilih', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
          ])),

          const SizedBox(height: 12),

          // Alasan Izin
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Alasan Izin', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLength: 500,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan izin kamu...',
                hintStyle: const TextStyle(color: Color(0xFF4A6080)),
                filled: true, fillColor: const Color(0xFF162440),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                counterStyle: const TextStyle(color: Color(0xFF90A4AE)),
              ),
            ),
          ])),

          const SizedBox(height: 12),

          // Dokumen Pendukung
          _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Dokumen Pendukung (Opsional)', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _docName = 'dokumen_izin.pdf'),
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF263E5E), style: BorderStyle.solid)),
                child: Row(children: [
                  const Icon(Icons.attach_file, color: Color(0xFF90A4AE), size: 18),
                  const SizedBox(width: 8),
                  Text(_docName ?? 'Upload JPG, PNG, atau PDF | Maks 5MB',
                      style: TextStyle(color: _docName != null ? Colors.white : const Color(0xFF90A4AE), fontSize: 12)),
                ]),
              ),
            ),
          ])),

          const SizedBox(height: 12),

          // Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF1565C0))),
            child: Row(children: const [
              Icon(Icons.info_outline, color: Color(0xFF64B5F6), size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('📋 Pengajuan akan diproses oleh Admin HR',
                  style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12))),
            ]),
          ),

          const SizedBox(height: 16),

          // Kirim
          _PressBtn(
            label: _loading ? '' : '📩 Kirim Pengajuan',
            color: const Color(0xFFE31E24),
            onTap: _loading ? () {} : _submit,
            child: _loading ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : null,
          ),

          const SizedBox(height: 10),
          _PressBtn(label: 'Batal', color: Colors.transparent, border: Colors.white54,
              onTap: () => Navigator.pop(context)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
    child: child,
  );

  Widget _datePicker(String value, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(value.isEmpty ? 'Pilih tanggal' : value,
            style: TextStyle(color: value.isEmpty ? const Color(0xFF4A6080) : Colors.white, fontSize: 14)),
        const Icon(Icons.calendar_today, color: Color(0xFF90A4AE), size: 16),
      ]),
    ),
  );
}

class _PressBtn extends StatefulWidget {
  final String label; final Color color; final Color? border;
  final VoidCallback onTap; final Widget? child;
  const _PressBtn({required this.label, required this.color, required this.onTap, this.border, this.child});
  @override
  State<_PressBtn> createState() => _PressBtnState();
}
class _PressBtnState extends State<_PressBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) async { await _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(animation: _s, builder: (_, __) => Transform.scale(
        scale: _s.value,
        child: Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(10),
            border: widget.border != null ? Border.all(color: widget.border!) : null,
            boxShadow: widget.color != Colors.transparent
                ? [BoxShadow(color: widget.color.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          alignment: Alignment.center,
          child: widget.child ?? Text(widget.label,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      )),
    );
  }
}