import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Ringkasan presence untuk header chat: online sekarang + kapan terakhir
/// terlihat (dari heartbeat terbaru di antara akun admin).
class PresenceInfo {
  final bool online;
  final DateTime? lastSeen;
  const PresenceInfo({required this.online, required this.lastSeen});
}

/// Firestore-based Presence System
/// - Sends heartbeat every 30 seconds
/// - Updates user_presence collection in real-time
/// - Admin dashboard listens to this collection for online status
class PresenceService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Timer? _heartbeatTimer;
  static String? _deviceId;
  static bool _isOnline = false;

  static bool get isOnline => _isOnline;

  static void start({required String deviceId}) {
    _deviceId = deviceId;
    _heartbeatTimer?.cancel();

    // Send immediate heartbeat
    _sendHeartbeat();

    // Schedule periodic heartbeat every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });
  }

  static void stop() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _isOnline = false;
    _setOffline();
  }

  static Future<void> _sendHeartbeat() async {
    final user = _auth.currentUser;
    if (user == null) {
      _isOnline = false;
      return;
    }

    try {
      await _db.collection('user_presence').doc(user.uid).set({
        'userId': user.uid,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'deviceId': _deviceId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isOnline = true;
    } catch (e) {
      debugPrint('Presence heartbeat error: $e');
      _isOnline = false;
    }
  }

  static Future<void> _setOffline() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('user_presence').doc(user.uid).set({
        'userId': user.uid,
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Presence offline error: $e');
    }
  }

  /// Dianggap offline jika heartbeat terakhir lebih lama dari ini.
  /// Sinyal utama = flag isOnline (ditulis false eksplisit saat tab/app
  /// ditutup); staleness hanya fallback untuk tab yang crash. Jendela dibuat
  /// longgar (5 mnt) karena jam HP karyawan sering meleset 1-3 menit dari
  /// server — dengan 75 dtk, admin yang online pun terbaca "Offline" terus.
  static const Duration staleAfter = Duration(minutes: 5);

  /// Listen to a specific user's presence status (online + lastSeen masih segar).
  static Stream<bool> subscribeToUser(String userId) {
    return _db.collection('user_presence').doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null || data['isOnline'] != true) return false;
      final ls = data['lastSeen'];
      if (ls is Timestamp) {
        return DateTime.now().difference(ls.toDate()) < staleAfter;
      }
      // Belum ada lastSeen valid → anggap online apa adanya.
      return true;
    });
  }

  /// Online bila SALAH SATU dari [userIds] online (heartbeat masih segar).
  /// Dipakai chat karyawan: admin bisa lebih dari satu akun.
  static Stream<bool> subscribeAnyOnline(Set<String> userIds) {
    return _db
        .collection('user_presence')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snap) {
          for (final d in snap.docs) {
            if (!userIds.contains(d.id)) continue;
            final ls = d.data()['lastSeen'];
            if (ls is! Timestamp ||
                DateTime.now().difference(ls.toDate()) < staleAfter) {
              return true;
            }
          }
          return false;
        });
  }

  /// Status presence (online + kapan terakhir terlihat) untuk sekumpulan
  /// admin. Dipakai header chat gaya WhatsApp: "Online" / "Terakhir dilihat …".
  static Stream<PresenceInfo> subscribePresenceInfo(Set<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value(const PresenceInfo(online: false, lastSeen: null));
    }
    return _db.collection('user_presence').snapshots().map((snap) {
      bool online = false;
      DateTime? lastSeen;
      for (final d in snap.docs) {
        if (!userIds.contains(d.id)) continue;
        final data = d.data();
        final ls = data['lastSeen'];
        final ts = ls is Timestamp ? ls.toDate() : null;
        if (ts != null && (lastSeen == null || ts.isAfter(lastSeen))) {
          lastSeen = ts;
        }
        if (data['isOnline'] == true &&
            (ts == null || DateTime.now().difference(ts) < staleAfter)) {
          online = true;
        }
      }
      return PresenceInfo(online: online, lastSeen: lastSeen);
    });
  }

  /// Listen to all online users
  static Stream<Set<String>> subscribeToOnlineUsers() {
    return _db
        .collection('user_presence')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => d.id).toSet();
        });
  }
}
