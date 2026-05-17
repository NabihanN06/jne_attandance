import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';
import '../../widgets/package_loading.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});
  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  static const Color jneCyan = Color(0xFF0891B2);
  static const Color jneRed = Color(0xFFF43F5E);

  DateTime? _fromDate;
  DateTime? _toDate;
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  String _type = 'annual';

  // Tipe izin — value harus match dengan label di admin panel.
  static const List<({String value, String label, IconData icon, Color color})> _leaveTypes = [
    (value: 'annual',     label: 'Cuti Tahunan',  icon: Icons.beach_access_rounded,   color: Color(0xFF0EA5E9)),
    (value: 'sick',       label: 'Sakit',         icon: Icons.medical_services_rounded, color: Color(0xFFEF4444)),
    (value: 'permission', label: 'Izin Mendadak', icon: Icons.flash_on_rounded,       color: Color(0xFFF59E0B)),
    (value: 'personal',   label: 'Keperluan Pribadi', icon: Icons.person_rounded,    color: Color(0xFF8B5CF6)),
    (value: 'urgent',     label: 'Keperluan Keluarga', icon: Icons.family_restroom_rounded, color: Color(0xFFEC4899)),
  ];

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
          colorScheme: const ColorScheme.light(primary: jneCyan, onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E293B)),
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

    await provider.submitLeave(
      type: _type,
      startDate: _fromDate!,
      endDate: _toDate!,
      totalDays: _workDays,
      reason: _reasonCtrl.text.trim(),
    );
    
    if (mounted) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan izin berhasil dikirim!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFF0F172A),
      body: Stack(
        children: [
          // ── Background Gradient ──
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: jneCyan.withValues(alpha: 0.15),
              ),
              child: Center(child: Container(width: 150, height: 150, color: jneCyan.withValues(alpha: 0.1),)),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.8),
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    'PENGAJUAN IZIN',
                    style: GoogleFonts.outfit(
                      color: Colors.white, 
                      fontSize: 14, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 2
                    ),
                  ),
                  centerTitle: true,
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGlassCard(
                        title: 'JENIS IZIN',
                        icon: Icons.category_rounded,
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
                                  color: selected ? t.color : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected ? t.color : Colors.white.withValues(alpha: 0.15),
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
                                      style: GoogleFonts.outfit(
                                        color: selected ? Colors.white : Colors.white70,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildGlassCard(
                        title: 'DURASI IZIN',
                        icon: Icons.calendar_month_rounded,
                        child: Column(
                          children: [
                            _dateField('Mulai Tanggal', _fmt(_fromDate), () => _pickDate(true)),
                            const SizedBox(height: 20),
                            _dateField('Sampai Tanggal', _fmt(_toDate), () => _pickDate(false)),
                            if (_workDays > 0) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: jneCyan.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: jneCyan.withValues(alpha: 0.2)),
                                ),
                                child: Row(children: [
                                  const Icon(Icons.info_outline, color: jneCyan, size: 18),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Total: $_workDays Hari Kerja Terhitung', 
                                    style: GoogleFonts.outfit(color: jneCyan, fontSize: 13, fontWeight: FontWeight.w800)
                                  ),
                                ]),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildGlassCard(
                        title: 'ALASAN & KETERANGAN',
                        icon: Icons.edit_note_rounded,
                        child: TextField(
                          controller: _reasonCtrl,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Tuliskan alasan lengkap Anda di sini...',
                            hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 15),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: _loading ? null : _submit,
                        child: Container(
                          height: 70,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [jneCyan, Color(0xFF06B6D4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: jneCyan.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Center(
                            child: _loading 
                              ? const PackageLoading(isLight: true, size: 30)
                              : Text(
                                  'KIRIM PENGAJUAN SEKARANG', 
                                  style: GoogleFonts.outfit(
                                    color: Colors.white, 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 1.5
                                  )
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: jneCyan, size: 20),
              const SizedBox(width: 12),
              Text(
                title, 
                style: GoogleFonts.outfit(
                  color: Colors.white60, 
                  fontSize: 11, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 2
                )
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _dateField(String label, String val, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  val.isEmpty ? 'Pilih Tanggal' : val, 
                  style: GoogleFonts.outfit(
                    color: val.isEmpty ? Colors.white24 : Colors.white, 
                    fontSize: 15, 
                    fontWeight: FontWeight.w800
                  )
                ),
                const Icon(Icons.calendar_today_rounded, color: jneCyan, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}