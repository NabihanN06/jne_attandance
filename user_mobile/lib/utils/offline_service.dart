import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';

class OfflineService {
  static const String _pendingKey = 'pending_attendance';

  static Future<void> savePendingAttendance(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingKey) ?? [];
    pending.add(jsonEncode(data));
    await prefs.setStringList(_pendingKey, pending);
  }

  static Future<List<Map<String, dynamic>>> getPendingAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> pending = prefs.getStringList(_pendingKey) ?? [];
    return pending.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
  }

  static Future<void> clearPendingAttendance() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
  }

  static Future<void> saveLocalHistory(List<AttendanceRecord> records) async {
    // Simulating local cache for fast loading
    // In real app, might use sqflite for complex queries
  }
}
