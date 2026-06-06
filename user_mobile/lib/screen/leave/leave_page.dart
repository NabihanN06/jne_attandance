import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
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

  // Tipe izin — value harus match dengan label di admin panel.
  static const List<({String value, String label, IconData icon, Color color})> _leaveTypes = [
    (value: 'annual', label: 'Cuti Tahunan', icon: Icons.beach_access_rounded, color: Color(0xFF0EA5E9)),
    (value: 'sick', label: 'Sakit', icon: Icons.medical_services_rounded, color: Color(0xFFEF4444)),
    (value: 'permission', label: 'Izin Mendadak', icon: Icons.flash_on_rounded, color: Color(0xFFF59E0B)),
    (value: 'personal', label: 'Keperluan Pribadi', icon: Icons.person_rounded, color: Color(0xFF8B5CF6)),
    (value: 'urgent', label: 'Keperluan Keluarga', icon: Icons.family_restroom_rounded, color: Color(0xFFEC4899)),
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
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) count++;
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
                  primary: _accent, onPrimary: Colors.white, surface: AppColors.darkCard, onSurface: Colors.white)
              : const ColorScheme.light(
                  primary: _accent, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E293B)),
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

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    if (_fromDate == null || _toDate == null) {
      showAppSnack(context, 'Pilih tanggal izin terlebih dahulu', color: AppColors.brandRed);
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      showAppSnack(context, 'Alasan izin tidak boleh kosong', color: AppColors.brandRed);
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
      );
      if (!mounted) return;
      showAppSnack(context, 'Pengajuan izin berhasil dikirim!', color: AppColors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showAppSnack(context, 'Gagal mengirim: ${e.toString().replaceAll('Exception: ', '')}',
          color: AppColors.brandRed);
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
        title: Text('Pengajuan Izin',
            style: GoogleFonts.plusJakartaSans(
                color: pal.textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _balanceSummary(balance),
          const SizedBox(height: 22),
          _buildSectionCard(
            title: 'JENIS IZIN',
            icon: Icons.category_rounded,
            pal: pal,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _leaveTypes.map((t) {
                final selected = _type == t.value;
                return GestureDetector(
                  onTap: () => setState(() => _type = t.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? t.color : pal.cardAlt,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? t.color : pal.border,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(t.icon, color: selected ? Colors.white : t.color, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          t.label,
                          style: GoogleFonts.plusJakartaSans(
                            color: selected ? Colors.white : pal.textSub,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'DURASI IZIN',
            icon: Icons.calendar_month_rounded,
            pal: pal,
            child: Column(
              children: [
                _dateField('Mulai Tanggal', _fmt(_fromDate), () => _pickDate(true), pal),
                const SizedBox(height: 18),
                _dateField('Sampai Tanggal', _fmt(_toDate), () => _pickDate(false), pal),
                if (_workDays > 0) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _accent.withValues(alpha: 0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: _accent, size: 18),
                      const SizedBox(width: 12),
                      Text('Total: $_workDays Hari Kerja Terhitung',
                          style: GoogleFonts.plusJakartaSans(
                              color: _accent, fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'ALASAN & KETERANGAN',
            icon: Icons.edit_note_rounded,
            pal: pal,
            child: TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.plusJakartaSans(
                  color: pal.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan lengkap Anda di sini...',
                hintStyle: GoogleFonts.plusJakartaSans(color: pal.textFaint, fontSize: 14),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
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
                  BoxShadow(color: _accent.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Center(
                child: _loading
                    ? const PackageLoading(isLight: true, size: 30)
                    : Text('KIRIM PENGAJUAN SEKARANG',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
                    Text('Sisa Cuti Tahunan',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${b.remainingAnnual}',
                            style: GoogleFonts.plusJakartaSans(
                                color: _accent, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5, left: 6),
                          child: Text('/ ${b.annualQuota} hari',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.event_available_rounded, color: _accent, size: 22),
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
              _miniStat('Terpakai', '${b.usedAnnual}'),
              _miniStat('Sakit', '${b.usedSick}'),
              _miniStat('Izin', '${b.usedPermission}'),
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
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text('$value hari',
            style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child, required AppPalette pal}) {
    return AppCard(
      radius: 24,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accent, size: 20),
              const SizedBox(width: 12),
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      color: pal.textSub, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _dateField(String label, String val, VoidCallback onTap, AppPalette pal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                color: pal.textSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
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
                Text(val.isEmpty ? 'Pilih Tanggal' : val,
                    style: GoogleFonts.plusJakartaSans(
                        color: val.isEmpty ? pal.textFaint : pal.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                const Icon(Icons.calendar_today_rounded, color: _accent, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
