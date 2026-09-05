import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';

/// Heartbeat Service - Tracks real-time online status
class HeartbeatService {
  static Timer? _heartbeatTimer;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static void startHeartbeat({
    required String userId,
    required String deviceId,
  }) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await _firestore.collection('user_heartbeats').doc(userId).set({
          'userId': userId,
          'timestamp': FieldValue.serverTimestamp(),
          'deviceId': deviceId,
          'appVersion': '1.0.0',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Heartbeat error: $e');
      }
    });
  }

  static void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
}

/// Enhanced Offline Service with auto-sync
class OfflineService {
  static const String _pendingKey = 'pending_attendance';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static StreamSubscription<List<ConnectivityResult>>?
  _connectivitySubscription;

  static Future<void> initAutoSync(Function onSyncComplete) async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) async {
      if (!result.contains(ConnectivityResult.none)) {
        await _syncPendingData(onSyncComplete);
      }
    });
  }

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

  /// Ganti seluruh isi antrean dengan [records] dalam SATU tulisan.
  ///
  /// Dipakai setelah sinkronisasi untuk menyisakan record yang masih gagal.
  /// Pola `clear()` lalu `save()` berulang punya jendela di mana antrean
  /// kosong — kalau aplikasi mati di situ (atau ada absensi offline baru yang
  /// masuk bersamaan), absensi karyawan hilang tanpa jejak.
  static Future<void> replacePendingAttendance(
    List<Map<String, dynamic>> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (records.isEmpty) {
      await prefs.remove(_pendingKey);
      return;
    }
    await prefs.setStringList(
      _pendingKey,
      records.map(jsonEncode).toList(growable: false),
    );
  }

  /// NEW: Save to pending_sync collection for reliable offline-first
  static Future<void> savePendingSync(
    AttendanceRecord record,
    String type,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('pending_sync').add({
      'userId': user.uid,
      'employeeName': record.employeeName,
      'employeeId': record.employeeId,
      'department': record.department,
      'date': record.date,
      'type': type,
      'time': FieldValue.serverTimestamp(),
      'latitude': record.checkIn?.latitude ?? 0,
      'longitude': record.checkIn?.longitude ?? 0,
      'photoUrl': record.checkIn?.photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'synced': false,
      'syncAttempts': 0,
    });
  }

  /// NEW: Auto-sync when connectivity is restored
  static Future<void> _syncPendingData(Function onSyncComplete) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Get pending records
      final pendingSnap = await _firestore
          .collection('pending_sync')
          .where('userId', isEqualTo: user.uid)
          .where('synced', isEqualTo: false)
          .get();

      for (final doc in pendingSnap.docs) {
        try {
          final data = doc.data();
          final date = data['date'] as String;
          final type = data['type'] as String;
          final time = data['time'] as Timestamp?;

          // Create attendance record
          final attendanceRef = _firestore.collection('attendance').doc();

          if (type == 'checkIn') {
            await attendanceRef.set({
              'userId': user.uid,
              'employeeName': data['employeeName'],
              'employeeId': data['employeeId'],
              'department': data['department'],
              'date': date,
              'status': 'present',
              'checkIn': {
                'time': time ?? FieldValue.serverTimestamp(),
                'latitude': data['latitude'],
                'longitude': data['longitude'],
                'distance': 0,
                'faceScore': 95,
                'photoUrl': data['photoUrl'],
              },
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            // Find existing record and add checkOut
            final existing = await _firestore
                .collection('attendance')
                .where('userId', isEqualTo: user.uid)
                .where('date', isEqualTo: date)
                .limit(1)
                .get();

            if (existing.docs.isNotEmpty) {
              await existing.docs.first.reference.update({
                'checkOut': {
                  'time': time ?? FieldValue.serverTimestamp(),
                  'latitude': data['latitude'],
                  'longitude': data['longitude'],
                  'distance': 0,
                  'faceScore': 95,
                  'photoUrl': data['photoUrl'],
                },
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }

          // Mark as synced
          await doc.reference.update({'synced': true});
        } catch (e) {
          // Increment retry counter
          await doc.reference.update({'syncAttempts': FieldValue.increment(1)});
        }
      }

      onSyncComplete();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  static void dispose() {
    _connectivitySubscription?.cancel();
  }

  static Future<void> saveLocalHistory(List<AttendanceRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final data = records.map((r) => r.toJson()).toList();
    await prefs.setString('local_history', jsonEncode(data));
  }

  static Future<List<AttendanceRecord>> getLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('local_history');
    if (data == null) return [];
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => AttendanceRecord.fromJson(e)).toList();
  }
}
