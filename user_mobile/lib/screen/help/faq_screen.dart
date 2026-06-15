// ─────────────────────────────────────────────
// faq_screen.dart - Self-service help center
// Mencegah masalah umum jadi tiket → user solve sendiri kalau bisa.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_provider.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const Color zenNavy = Color(0xFF121826);
  static const Color zenIndigo = Color(0xFF4F46E5);
  static const Color zenRose = Color(0xFFF43F5E);
  static const Color zenEmerald = Color(0xFF10B981);
  static const Color zenAmber = Color(0xFFF59E0B);
  static const Color zenOffWhite = Color(0xFFF8FAFC);
  static const Color zenSlate = Color(0xFF94A3B8);

  final TextEditingController _search = TextEditingController();
  String _query = '';
  String _activeCategory = 'all';

  static const _categories = <_FaqCategory>[
    _FaqCategory('all', 'Semua', Icons.apps_rounded, zenIndigo),
    _FaqCategory(
      'attendance',
      'Absensi',
      Icons.fingerprint_rounded,
      zenEmerald,
    ),
    _FaqCategory(
      'leave',
      'Izin & Cuti',
      Icons.event_available_rounded,
      zenAmber,
    ),
    _FaqCategory('overtime', 'Lembur', Icons.timer_rounded, zenIndigo),
    _FaqCategory('account', 'Akun', Icons.person_rounded, zenRose),
  ];

  static final List<_FaqItem> _items = [
    _FaqItem(
      category: 'attendance',
      q: 'Saya lupa absen masuk, apa yang harus saya lakukan?',
      a: 'Buka tab History → cari tanggal yang dilewatkan → tap tombol "REPORT" untuk buat komplain. Lampirkan bukti (screenshot chat WA atau foto saat di kantor). Admin akan koreksi status absensi Anda dalam 1×24 jam kerja.',
    ),
    _FaqItem(
      category: 'attendance',
      q: 'Kenapa absen masuk saya tercatat "TERLAMBAT" padahal datang tepat waktu?',
      a: 'Cek apakah waktu di HP Anda otomatis (Settings → Date & Time → Set Automatically). Sistem pakai waktu server, bukan waktu HP. Jika tetap salah, buat komplain di History dengan kategori "attendance_error" dan tulis kronologi.',
    ),
    _FaqItem(
      category: 'attendance',
      q: 'Saya di luar radius kantor padahal sedang dinas luar.',
      a: 'Saat ini absensi remote butuh izin admin (flag allowRemoteAttendance). Hubungi admin via menu Chat untuk minta diaktifkan, atau ajukan lembur/dinas luar lewat menu yang sesuai.',
    ),
    _FaqItem(
      category: 'attendance',
      q: 'Foto absen saya tidak terupload (status "uploading...").',
      a: 'Foto upload di background — biasanya rampung dalam 1-2 menit setelah online. Jika lebih dari 10 menit masih "uploading...", buka History → tap SYNC. Kalau tetap stuck, restart app.',
    ),
    _FaqItem(
      category: 'leave',
      q: 'Berapa jatah cuti tahunan saya?',
      a: 'Buka tab Profile → bagian Leave Balance. Default 12 hari/tahun, tapi admin bisa menyesuaikan per karyawan. Sisa kuota terlihat real-time setelah pengajuan disetujui.',
    ),
    _FaqItem(
      category: 'leave',
      q: 'Apa beda "Cuti Tahunan", "Sakit", dan "Izin Mendadak"?',
      a: '• Cuti Tahunan (annual): dipotong dari kuota 12 hari.\n• Sakit (sick): tidak potong kuota tahunan, butuh surat dokter untuk >2 hari.\n• Izin Mendadak (permission): keperluan singkat <1 hari, biasanya tidak dipotong kuota.',
    ),
    _FaqItem(
      category: 'leave',
      q: 'Pengajuan cuti saya ditolak. Bisa diapakan?',
      a: 'Cek alasan di tab Notifikasi. Anda bisa ajukan ulang dengan tanggal/alasan yang disesuaikan, atau hubungi admin via Chat untuk klarifikasi. Tidak ada limit pengajuan.',
    ),
    _FaqItem(
      category: 'leave',
      q: 'Bagaimana cara membatalkan pengajuan cuti yang masih pending?',
      a: 'Buka daftar pengajuan Anda → swipe ke kiri pada item yang ingin dibatalkan → tap "Batalkan". Hanya bisa dibatalkan selama status masih "pending".',
    ),
    _FaqItem(
      category: 'overtime',
      q: 'Kapan lembur saya dihitung & dibayar?',
      a: 'Lembur dihitung otomatis setelah jam kerja standar (default 8 jam/hari) dengan tarif yang diset admin. Pembayaran mengikuti siklus payroll. Cek estimasi di tab Statistic.',
    ),
    _FaqItem(
      category: 'overtime',
      q: 'Saya kerja Sabtu, apakah otomatis dihitung lembur?',
      a: 'Tergantung jadwal kerja yang diset admin untuk Anda. Kalau Sabtu adalah hari libur menurut jamKerja Anda, sistem otomatis mark sebagai lembur. Konfirmasi ke admin kalau ada keraguan.',
    ),
    _FaqItem(
      category: 'account',
      q: 'Saya lupa password.',
      a: 'Di layar login, tap "Lupa Password" → masukkan email → cek inbox untuk link reset. Kalau email tidak ada, periksa folder Spam atau hubungi admin untuk reset manual.',
    ),
    _FaqItem(
      category: 'account',
      q: 'Wajah saya tidak terdeteksi saat absen.',
      a: 'Pastikan: (1) pencahayaan cukup, (2) tidak pakai masker/kacamata hitam, (3) wajah penuh di frame. Kalau gagal terus, daftar ulang wajah lewat Profile → Re-register Face.',
    ),
    _FaqItem(
      category: 'account',
      q: 'Bagaimana cara ganti foto profil?',
      a: 'Buka Profile → tap foto profil → pilih dari galeri atau kamera. Perubahan langsung terlihat di sistem admin.',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filtered {
    final lower = _query.toLowerCase();
    return _items.where((it) {
      if (_activeCategory != 'all' && it.category != _activeCategory) {
        return false;
      }
      if (lower.isEmpty) return true;
      return it.q.toLowerCase().contains(lower) ||
          it.a.toLowerCase().contains(lower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final isDark = context.watch<AppProvider>().isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : zenOffWhite,
      appBar: AppBar(
        backgroundColor: zenNavy,
        elevation: 0,
        title: Text(
          'PUSAT BANTUAN',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            color: zenNavy,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari pertanyaan...',
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Colors.white54,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      final active = c.key == _activeCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _activeCategory = c.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? c.color
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                c.icon,
                                size: 14,
                                color: active ? Colors.white : Colors.white54,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                c.label,
                                style: GoogleFonts.outfit(
                                  color: active ? Colors.white : Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: zenSlate.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada hasil. Coba kata kunci lain.',
                          style: GoogleFonts.outfit(
                            color: zenSlate,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.support_agent_rounded,
                            color: zenIndigo,
                          ),
                          label: Text(
                            'Tanya admin langsung',
                            style: GoogleFonts.outfit(
                              color: zenIndigo,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _faqCard(list[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _faqCard(_FaqItem item) {
    final cat = _categories.firstWhere(
      (c) => c.key == item.category,
      orElse: () => _categories.first,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zenNavy.withValues(alpha: 0.03)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          leading: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(cat.icon, color: cat.color, size: 18),
          ),
          title: Text(
            item.q,
            style: GoogleFonts.outfit(
              color: zenNavy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          children: [
            Text(
              item.a,
              style: GoogleFonts.plusJakartaSans(
                color: zenNavy.withValues(alpha: 0.75),
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCategory {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  const _FaqCategory(this.key, this.label, this.icon, this.color);
}

class _FaqItem {
  final String category;
  final String q;
  final String a;
  const _FaqItem({required this.category, required this.q, required this.a});
}
