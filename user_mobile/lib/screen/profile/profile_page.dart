import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../auth/login_page.dart';
import '../enroll/enroll_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('Profile Karyawan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Profile header ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person, color: Color(0xFF90A4AE), size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('${user.position} · ${user.department}',
                    style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12, height: 1.4)),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Informasi Pribadi'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _infoItem(Icons.email_outlined, user.email, 'Email'),
              _divider(),
              _infoItem(Icons.phone_outlined, user.phone.isEmpty ? '+62 000-0000-0000' : user.phone, 'Nomor Telepon'),
              _divider(),
              _infoItem(Icons.badge_outlined, 'NIK: ${user.nik}', 'ID Karyawan'),
            ]),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Jadwal Kerja'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _infoItem(Icons.alarm, '08:00–16:00', 'Jam Masuk - Pulang', iconBg: const Color(0xFFB71C1C)),
              _divider(),
              _infoItem(Icons.calendar_month, 'Senin – Jum\'at', 'Hari Kerja', iconBg: const Color(0xFF1565C0)),
              _divider(),
              _infoItem(Icons.warning_amber_rounded, '15 Menit', 'Toleransi', iconBg: const Color(0xFFE65100)),
            ]),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Keamanan'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _actionItem(
                icon: Icons.face_retouching_natural,
                title: 'Wajah Terdaftar ✓',
                subtitle: 'Didaftarkan ${user.faceRegisteredDate.isEmpty ? "1 Jan 2026" : user.faceRegisteredDate} · ${user.deviceName.isEmpty ? "Perangkat ini" : user.deviceName}',
                iconBg: const Color(0xFF1565C0),
                onTap: () {},
              ),
              _divider(),
              _actionItem(
                icon: Icons.phonelink_setup,
                title: 'Daftar Ulang Wajah',
                subtitle: 'Ganti data wajah untuk verifikasi',
                iconBg: const Color(0xFF4A235A),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EnrollPage())),
              ),
              _divider(),
              _actionItem(
                icon: Icons.key,
                title: 'Ganti Password',
                subtitle: 'Verifikasi via WhatsApp OTP',
                iconBg: const Color(0xFF1B5E20),
                onTap: () => _showChangePasswordDialog(context),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Pengaturan Notifikasi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _notifToggle(context, 'Reminder Absen Masuk', provider.notifSettings.reminderAbsenMasuk,
                  (v) => provider.updateNotifSettings(provider.notifSettings.copyWith(reminderAbsenMasuk: v))),
              _divider(),
              _notifToggle(context, 'Reminder Absen Pulang', provider.notifSettings.reminderAbsenPulang,
                  (v) => provider.updateNotifSettings(provider.notifSettings.copyWith(reminderAbsenPulang: v))),
              _divider(),
              _notifToggle(context, 'Notifikasi Status Izin', provider.notifSettings.notifikasiStatusIzin,
                  (v) => provider.updateNotifSettings(provider.notifSettings.copyWith(notifikasiStatusIzin: v))),
              _divider(),
              _notifToggle(context, 'Notifikasi Meeting', provider.notifSettings.notifikasiMeeting,
                  (v) => provider.updateNotifSettings(provider.notifSettings.copyWith(notifikasiMeeting: v))),
            ]),
          ),

          const SizedBox(height: 20),

          _sectionLabel('Tentang Aplikasi'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.info_outline, color: Color(0xFF90A4AE), size: 22)),
              const SizedBox(width: 12),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('v0.3.0', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Versi Aplikasi', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Log Out button
          _PressBtn(
            label: 'Log Out',
            color: const Color(0xFFE31E24),
            onTap: () => _confirmLogout(context, provider),
          ),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700));

  Widget _divider() => const Divider(color: Color(0xFF1E3A5F), height: 1, indent: 16, endIndent: 16);

  Widget _infoItem(IconData icon, String value, String label, {Color iconBg = const Color(0xFF162440)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white70, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(label, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _actionItem({required IconData icon, required String title, required String subtitle,
      required Color iconBg, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white70, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
          ])),
          const Icon(Icons.chevron_right, color: Color(0xFF90A4AE), size: 18),
        ]),
      ),
    );
  }

  Widget _notifToggle(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFFE31E24),
          activeTrackColor: const Color(0xFFE31E24).withValues(alpha: 0.4),
          inactiveThumbColor: Colors.grey,
          inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
        ),
      ]),
    );
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F38),
        title: const Text('Log Out', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin keluar? Akun kamu tetap tersimpan.',
            style: TextStyle(color: Color(0xFF90A4AE))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Color(0xFF90A4AE)))),
          TextButton(
            onPressed: () {
              provider.logout();
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()), (r) => false);
            },
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFE31E24), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D1F38),
        title: const Text('Ganti Password', style: TextStyle(color: Colors.white)),
        content: const Text('Fitur ganti password via WhatsApp OTP akan segera tersedia.',
            style: TextStyle(color: Color(0xFF90A4AE))),
        actions: [TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFE31E24))))],
      ),
    );
  }
}

class _PressBtn extends StatefulWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _PressBtn({required this.label, required this.color, required this.onTap});
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
      child: AnimatedBuilder(animation: _s, builder: (_, _) => Transform.scale(
        scale: _s.value,
        child: Container(
          width: double.infinity, height: 48,
          decoration: BoxDecoration(
            color: widget.color, borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          alignment: Alignment.center,
          child: Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      )),
    );
  }
}