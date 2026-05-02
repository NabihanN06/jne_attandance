import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/app_provider.dart';
import '../../models/app_models.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final records = provider.myAttendance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        title: const Text('Riwayat Kehadiran'),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => _showHelp(context)),
        ],
      ),
      body: records.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final r = records[index];
                return FadeInUp(
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  child: _buildAttendanceCard(context, r),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_toggle_off, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text('Belum ada riwayat absensi', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceRecord r) {
    final statusColor = _getStatusColor(r.checkInStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: InkWell(
        onTap: () => _showRecordDetails(context, r),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, d MMMM yyyy', 'id').format(r.date), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(r.shift, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(r.checkInStatus, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              children: [
                _timeInfo('Masuk', r.checkIn ?? '--:--'),
                const SizedBox(width: 40),
                _timeInfo('Pulang', r.checkOut ?? '--:--'),
                const Spacer(),
                const Text('Detail →', style: TextStyle(color: Colors.blue, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Tepat')) return Colors.green;
    if (status.contains('Lambat')) return Colors.orange;
    if (status.contains('Lembur')) return Colors.blue;
    return Colors.red;
  }

  void _showRecordDetails(BuildContext context, AttendanceRecord r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1F38),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detail Kehadiran', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _detailRow('Tanggal', DateFormat('dd MMMM yyyy', 'id').format(r.date)),
            _detailRow('Lokasi', r.location),
            _detailRow('Status', r.checkInStatus),
            if (r.photoUrl != null) ...[
              const SizedBox(height: 16),
              const Text('Foto Absensi', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                height: 150, width: double.infinity,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.black26),
                child: const Center(child: Icon(Icons.image, color: Colors.white24)),
              ),
            ],
            const SizedBox(height: 32),
            const Text('❌ Data absensi TIDAK BISA diedit sendiri', 
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showEditRequestForm(context, r),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('AJUKAN KOREKSI DATA'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _showEditRequestForm(BuildContext context, AttendanceRecord r) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF162440),
        title: const Text('Ajukan Koreksi', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Jelaskan alasan koreksi data absensi ini:', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Contoh: Lupa absen pulang karena lembur mendadak',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () {
              Provider.of<AppProvider>(context, listen: false).submitEditRequest(r.id, controller.text, {});
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan terkirim')));
            },
            child: const Text('KIRIM PERMINTAAN'),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF162440),
        title: const Text('Bantuan', style: TextStyle(color: Colors.white)),
        content: const Text('Data absensi bersifat permanen. Jika terdapat kesalahan, silakan gunakan fitur "Ajukan Koreksi" untuk mendapatkan persetujuan dari HR Admin.',
          style: TextStyle(color: Colors.grey, fontSize: 13)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('MENGERTI'))],
      ),
    );
  }
}