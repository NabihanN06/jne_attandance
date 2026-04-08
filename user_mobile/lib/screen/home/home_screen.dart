import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../option/option_page.dart';
import '../statistic/statistic_page.dart';
import '../history/history_page.dart';
import '../profile/profile_page.dart';
import '../leave/leave_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  static const _months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agt','Sep','Okt','Nov','Des'];
  static const _days = ['Sen','Sel','Rab','Kam','Jum','Sab','Min'];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppProvider>();
    final user = p.currentUser;
    final now = DateTime.now();
    final dateStr = '${_days[now.weekday-1]}, ${now.day} ${_months[now.month-1]} ${now.year}';
    final unread = p.unreadCount;
    final bg = p.isDarkMode ? const Color(0xFF0A1628) : const Color(0xFFF0F4F8);
    final cardBg = p.isDarkMode ? const Color(0xFF0D1F38) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: p.isDarkMode ? const Color(0xFF0D1F38) : const Color(0xFF1A3A6B),
        title: const Text('JNE MTP Attendance App', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(p.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: Colors.white, size: 22),
            onPressed: () => p.toggleTheme(),
            tooltip: 'Toggle Dark Mode',
          ),
          Stack(alignment: Alignment.center, children: [
            IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                onPressed: () => _showNotif(context, p)),
            if (unread > 0) Positioned(right: 8, top: 8,
                child: Container(width: 14, height: 14,
                    decoration: const BoxDecoration(color: Color(0xFFE31E24), shape: BoxShape.circle),
                    child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))))),
          ]),
          IconButton(icon: const Icon(Icons.account_circle_outlined, color: Colors.white, size: 22),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()))),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Greeting
          _box(cardBg, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Hallo, ${user?.name ?? "Karyawan"} ', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const Text('👋', style: TextStyle(fontSize: 18)),
            ]),
            const SizedBox(height: 2),
            Text(dateStr, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
            const SizedBox(height: 14),
            const Divider(color: Color(0xFF1E3A5F), height: 1),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                Text('Jam Kerja', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12)),
                SizedBox(height: 2),
                Text('08.00 – 15.00', style: TextStyle(color: Colors.white, fontSize: 13)),
              ]),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1B5E20), borderRadius: BorderRadius.circular(8)),
                child: const Text('16.00 – 16.15', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 14),
            _absenRow(Icons.check_box, const Color(0xFF4CAF50), 'Absen Masuk', 'Hari ini, 08.05', badge: 'Tepat Waktu', bc: const Color(0xFF1B5E20)),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionPage())),
              borderRadius: BorderRadius.circular(8),
              child: _absenRow(Icons.watch_later_outlined, const Color(0xFF90A4AE), 'Absen Pulang', 'Belum absen pulang → Tap untuk absen'),
            ),
          ])),

          const SizedBox(height: 12),
          _PressableBanner(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OptionPage()))),
          const SizedBox(height: 12),

          // Statistik
          _box(cardBg, Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Row(children: [
                Text('📊 ', style: TextStyle(fontSize: 14)),
                Text('Statistik Absensi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ]),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticPage())),
                child: const Text('Lihat Detail →', style: TextStyle(color: Color(0xFF64B5F6), fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: _sb('17','Hari hadir',const Color(0xFF4CAF50))),const SizedBox(width:8),Expanded(child: _sb('3j 30m','Total Jam Telat',const Color(0xFFE65100)))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: _sb('5j 30m','Total Jam lembur',const Color(0xFF1565C0))),const SizedBox(width:8),Expanded(child: _sb('2','Hari Izin',const Color(0xFFF57C00)))]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: _sb('1','Alpha',const Color(0xFF212121))),const SizedBox(width:8),Expanded(child: _sb('141j','Total Jam Kerja',const Color(0xFF6A1B9A)))]),
          ])),

          const SizedBox(height: 12),

          // Meetings
          _box(cardBg, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Meeting Mendatang', style: TextStyle(color: Color(0xFFE31E24), fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (p.meetings.isEmpty)
              const Text('Tidak ada meeting', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 12))
            else
              ...p.meetings.take(3).toList().asMap().entries.map((e) {
                final m = e.value; final dt = m.dateTime;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (e.key > 0) const Divider(color: Color(0xFF1E3A5F)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('${dt.day} ${_months[dt.month-1]}, ${dt.hour.toString().padLeft(2,'0')}.${dt.minute.toString().padLeft(2,'0')} • ${m.room}',
                          style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
                    ]),
                  ),
                ]);
              }).toList(),
          ])),

          const SizedBox(height: 12),

          Row(children: [
            Expanded(child: _tapCard('📋','Riwayat Absensi', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage())))),
            const SizedBox(width: 12),
            Expanded(child: _tapCard('📝','Ajukan Izin', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeavePage())))),
          ]),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _box(Color bg, Widget child) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: child,
  );

  Widget _absenRow(IconData icon, Color ic, String title, String sub, {String? badge, Color? bc}) {
    return Row(children: [
      Container(width: 40, height: 40,
          decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: ic, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(sub, style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
      ])),
      if (badge != null)
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bc, borderRadius: BorderRadius.circular(6)),
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _sb(String v, String l, Color c) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 2),
      Text(l, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]),
  );

  Widget _tapCard(String emoji, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFF0D1F38), borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          const Text('Lihat Semua →', style: TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
        ]),
      ),
    );
  }

  void _showNotif(BuildContext context, AppProvider p) {
    p.markAllRead();
    final notifs = p.myNotifications;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(children: [
        const Padding(padding: EdgeInsets.all(16),
            child: Text('Notifikasi', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700))),
        const Divider(color: Color(0xFF1E3A5F)),
        Expanded(child: notifs.isEmpty
            ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: Color(0xFF90A4AE))))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifs.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xFF1E3A5F)),
                itemBuilder: (_, i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF162440), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.notifications, color: Color(0xFFE31E24), size: 18)),
                  title: Text(notifs[i]['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(notifs[i]['body'], style: const TextStyle(color: Color(0xFF90A4AE), fontSize: 11)),
                ))),
      ]),
    );
  }
}

class _PressableBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _PressableBanner({required this.onTap});
  @override
  State<_PressableBanner> createState() => _PBState();
}
class _PBState extends State<_PressableBanner> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s, _sh;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _sh = Tween<double>(begin: 12.0, end: 2.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) async { await _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(animation: _c, builder: (_, __) => Transform.scale(
        scale: _s.value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE31E24), borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFFE31E24).withOpacity(0.45), blurRadius: _sh.value, offset: const Offset(0, 4))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Sudah siap pulang?', style: TextStyle(color: Colors.white70, fontSize: 12)),
              SizedBox(height: 2),
              Text('Ayo Isi Absen', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ]),
            const Text('📸', style: TextStyle(fontSize: 32)),
          ]),
        ),
      )),
    );
  }
}