// ─────────────────────────────────────────────
// providers/app_provider.dart - CLOSED-LOOP SYNC VERSION
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../utils/offline_service.dart';
import '../utils/connectivity_service.dart';
import '../utils/fortress_utils.dart';
import '../utils/presence_service.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();
  late final ConnectivityService _connectivityService;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String _fortressStatus = '';
  String get fortressStatus => _fortressStatus;

  bool get isLoggedIn => _auth.currentUser != null;

  // Configuration
  double _officeLat = -3.4150;
  double _officeLng = 114.8465;
  double _officeRadius = 500.0;

  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  double get officeRadius => _officeRadius;
  TimeOfDay officeStartTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  bool _isNotificationsEnabled = true;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('setting_dark_mode') ?? false;
    _isNotificationsEnabled = prefs.getBool('setting_notifications') ?? true;
    notifyListeners();
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _savePref('setting_dark_mode', _isDarkMode);
  }

  Future<void> toggleNotifications() async {
    _isNotificationsEnabled = !_isNotificationsEnabled;
    notifyListeners();
    await _savePref('setting_notifications', _isNotificationsEnabled);
  }

  // Data Lists
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> get myAttendance => _attendanceRecords;

  List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> get myLeaveRequests => _leaveRequests;

  // Dipisah agar tidak ada race condition saat kedua snapshot tiba bersamaan
  final List<AdminNotification> _personalNotifs = [];
  final List<AdminNotification> _broadcastNotifs = [];

  List<AdminNotification> get notifications {
    final merged = [..._personalNotifs, ..._broadcastNotifs];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(merged);
  }

  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => _events;

  // History State
  List<AttendanceRecord> _monthlyRecords = [];
  List<AttendanceRecord> get monthlyAttendance => _monthlyRecords;
  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  bool _isLoadingFace = false;
  bool get isLoadingFace => _isLoadingFace;

  bool _hasPendingAttendance = false;
  bool get hasPendingAttendance => _hasPendingAttendance;

  // Stream Subscriptions
  StreamSubscription? _settingsSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _broadcastSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _attendanceSub;
  StreamSubscription? _leaveSub;
  StreamSubscription? _presenceSub;

  // Timers
  Timer? _heartbeatTimer;
  Timer? _syncRetryTimer;

  AppProvider(ConnectivityService connectivityService) {
    _connectivityService = connectivityService;
    _init();
    _loadThemePreference();
    WidgetsBinding.instance.addObserver(this);
    
    _connectivityService.addListener(() {
      if (_connectivityService.isOnline && isLoggedIn) {
        syncPendingRecords();
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    });
  }

  bool get isOnline => _connectivityService.isOnline;
  bool get isOffline => !isOnline;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isLoggedIn) {
      if (state == AppLifecycleState.resumed) {
        _updatePresence(true);
        _startHeartbeat();
      } else {
        _updatePresence(false);
        _stopHeartbeat();
      }
    }
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _fetchCurrentUser(user.uid);
        _listenToSettings();
        _startHeartbeat();
        _saveFCMToken();
        _schedulePeriodicSync();
        syncPendingRecords();
      } else {
        _stopHeartbeat();
        _stopPresence();
        _cancelAllSubscriptions();
        _currentUser = null;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  bool _isFetchingUser = false;

  Future<void> _fetchCurrentUser(String uid) async {
    if (_isFetchingUser) return;
    _isFetchingUser = true;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        _listenToMyData();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    } finally {
      _isFetchingUser = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void _listenToMyData() {
    if (_currentUser == null) return;
    _cancelAllSubscriptions();

    _attendanceSub = _db.collection('attendance')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('attendanceDate', descending: true)
        .limit(30)
        .snapshots()
        .listen((snap) {
      _attendanceRecords = snap.docs.map((doc) => AttendanceRecord.fromFirestore(doc)).toList();
      notifyListeners();
    });

    _leaveSub = _db.collection('leaves')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _leaveRequests = snap.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
      notifyListeners();
    });

    _notifSub = _db.collection('userNotifications')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _updateNotifications(snap, isBroadcast: false);
    });

    _broadcastSub = _db.collection('broadcasts')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((snap) {
      _updateNotifications(snap, isBroadcast: true);
    });

    _eventSub = _db.collection('calendarEvents')
        .where('startDate', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 30)))
        .snapshots()
        .listen((snap) {
      _events = snap.docs.map((doc) => CalendarEvent.fromFirestore(doc)).toList();
      notifyListeners();
    });
  }

  void _updateNotifications(QuerySnapshot snap, {required bool isBroadcast}) {
    final newNotifs = snap.docs.map((doc) => AdminNotification.fromFirestore(doc)).toList();
    if (isBroadcast) {
      _broadcastNotifs
        ..clear()
        ..addAll(newNotifs);
    } else {
      _personalNotifs
        ..clear()
        ..addAll(newNotifs);
    }
    notifyListeners();
  }

  void _cancelAllSubscriptions() {
    _settingsSub?.cancel();
    _notifSub?.cancel();
    _broadcastSub?.cancel();
    _eventSub?.cancel();
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    _presenceSub?.cancel();
    _syncRetryTimer?.cancel();
  }

  // ── Heartbeat & Presence ──
   void _startHeartbeat() {
     _heartbeatTimer?.cancel();
     // Legacy heartbeats for admin dashboard
     HeartbeatService.startHeartbeat(userId: _auth.currentUser?.uid ?? '', deviceId: 'mobile_${_auth.currentUser?.uid}');
     // New presence system with explicit online flag
     _updatePresence(true);
     _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
       if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
         _updatePresence(true);
         HeartbeatService.startHeartbeat(userId: _auth.currentUser?.uid ?? '', deviceId: 'mobile_${_auth.currentUser?.uid}');
       }
     });
   }

   void _stopHeartbeat() {
     _heartbeatTimer?.cancel();
     _heartbeatTimer = null;
     HeartbeatService.stopHeartbeat();
     PresenceService.stop();
   }

  void _stopPresence() {
    PresenceService.stop();
  }

  Future<void> _updatePresence(bool isOnline) async {
    if (_auth.currentUser == null) return;
    try {
      PresenceService.start(deviceId: 'mobile_${_auth.currentUser!.uid}');
    } catch (e) {
      debugPrint('Presence update error: $e');
    }
  }

  void _schedulePeriodicSync() {
    _syncRetryTimer?.cancel();
    _syncRetryTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_hasPendingAttendance && isLoggedIn) {
        // Only sync if we have connectivity
        bool isOnline = await _checkConnectivity();
        if (isOnline) {
          syncPendingRecords();
        }
      }
    });
  }

  Future<void> _saveFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && _currentUser != null) {
        await _db.collection('fcm_tokens').doc(token).set({
          'userId': _currentUser!.uid,
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('FCM token save error: $e');
    }
  }


  // ── Auth Methods ──
  Future<void> login(String email, String password) async {
    _isProcessing = true;
    _fortressStatus = 'Menghubungkan ke server...';
    notifyListeners();
    try {
      await FortressUtils.wrapWithRetry(
        () => _auth.signInWithEmailAndPassword(email: email, password: password),
        taskName: 'Login',
        onStatusUpdate: (msg) {
          _fortressStatus = msg;
          notifyListeners();
        },
      );
      // Fetch user data immediately so login_page can read passwordChanged
      if (_auth.currentUser != null) {
        await _fetchCurrentUser(_auth.currentUser!.uid);
      }
      _updatePresence(true);
      _startHeartbeat();
    } on FirebaseAuthException catch (e) {
      // Map Firebase error codes to messages users can actually act on
      final msg = switch (e.code) {
        'invalid-email'         => 'Format email tidak valid.',
        'user-disabled'         => 'Akun dinonaktifkan. Hubungi admin.',
        'user-not-found'        => 'Akun tidak ditemukan. Cek email kembali.',
        'wrong-password'        => 'Password salah.',
        'invalid-credential'    => 'Email atau password salah.',
        'too-many-requests'     => 'Terlalu banyak percobaan. Tunggu beberapa menit.',
        'network-request-failed'=> 'Tidak ada koneksi internet. Cek jaringan kamu.',
        _                       => 'Gagal masuk (${e.code}). Coba lagi.',
      };
      throw Exception(msg);
    } catch (e) {
      // Non-auth failure (network during fetchCurrentUser, etc.)
      throw Exception('Gangguan koneksi. Cek internet kamu lalu coba lagi.');
    } finally {
      _isProcessing = false;
      _fortressStatus = '';
      notifyListeners();
    }
  }

  Future<void> markPasswordChanged() async {
    if (_currentUser == null) return;
    try {
      await _db.collection('users').doc(_currentUser!.uid).update({
        'passwordChanged': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUser = _currentUser!.copyWith(passwordChanged: true);
      notifyListeners();
    } catch (e) {
      debugPrint('markPasswordChanged error: $e');
    }
  }

  Future<void> changePassword(String newPassword) async {
    _isProcessing = true;
    notifyListeners();
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } catch (e) {
      debugPrint('Error changing password: $e');
      throw Exception('Gagal mengubah kata sandi. Pastikan Anda baru saja masuk (recent login) untuk alasan keamanan.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Re-authenticate with old password then change to new password.
  /// Required by Firebase for sensitive operations after session has aged.
  Future<void> reauthAndChangePassword(String oldPassword, String newPassword) async {
    _isProcessing = true;
    notifyListeners();
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Sesi tidak valid. Silakan login ulang.');
      }
      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      // Change password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      debugPrint('reauthAndChangePassword error: ${e.code}');
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Password lama salah. Periksa kembali.');
      }
      if (e.code == 'weak-password') {
        throw Exception('Password baru terlalu lemah.');
      }
      throw Exception('Gagal mengubah password: ${e.message}');
    } catch (e) {
      debugPrint('reauthAndChangePassword error: $e');
      throw Exception('Gagal mengubah password. Coba login ulang terlebih dahulu.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    // 1. Unregister FCM token for THIS device so the next user who logs in here
    // doesn't keep receiving the previous user's notifications. Best-effort:
    // if it fails (offline), the next saveFCMToken on new login will overwrite
    // the doc with the new userId anyway.
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('fcm_tokens').doc(token).delete();
      }
    } catch (e) {
      debugPrint('FCM token cleanup failed: $e');
    }

    // 2. Stop background work BEFORE signOut so listeners don't see a half-gone
    // auth state and write garbage.
    _stopHeartbeat();
    _stopPresence();
    _cancelAllSubscriptions();

    // 3. SignOut — this will also fire the authStateChanges listener which
    // does its own cleanup, but those calls are idempotent.
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Logout signOut error: $e');
    }

    // 4. Clear local caches so a re-login on same device starts fresh.
    _currentUser = null;
    _attendanceRecords.clear();
    _monthlyRecords.clear();
    _leaveRequests.clear();
    _personalNotifs.clear();
    _broadcastNotifs.clear();
    _events.clear();
    _hasPendingAttendance = false;
    notifyListeners();
  }

  Future<void> fetchAttendanceByMonth(int month, int year) async {
    if (_currentUser == null) return;
    _isLoadingHistory = true;
    notifyListeners();

    try {
      // Fetch limited records to avoid composite index requirement
      final snap = await _db.collection('attendance')
          .where('userId', isEqualTo: _currentUser!.uid)
          .orderBy('attendanceDate', descending: true)
          .limit(100)
          .get();

      _monthlyRecords = snap.docs
          .map((doc) => AttendanceRecord.fromFirestore(doc))
          .where((r) {
            final d = DateTime.tryParse(r.date);
            return d != null && d.month == month && d.year == year;
          })
          .toList();
    } catch (e) {
      debugPrint('Error fetching history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ── Attendance Logic ──
  bool get hasClockedInToday {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _attendanceRecords.any((r) => r.date == todayStr && r.checkIn != null && r.checkOut == null);
  }

  Future<void> addAttendanceCheckIn(String status, {String? localImagePath, double lat = 0, double lng = 0}) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    notifyListeners();

    try {
      bool isOnline = await _checkConnectivity();

      if (isOnline) {
        final serverNow = await FortressUtils.getServerTime();
        final dateStr = DateFormat('yyyy-MM-dd').format(serverNow);

        final data = {
          'userId': _currentUser!.uid,
          'employeeName': _currentUser!.name,
          'employeeId': _currentUser!.employeeId,
          'department': _currentUser!.department,
          'role': _currentUser!.role,
          'date': dateStr,
          'attendanceDate': dateStr,
          'status': _mapMobileStatusToAdmin(status),
          'checkIn': {
            'time': FieldValue.serverTimestamp(),
            'latitude': lat,
            'longitude': lng,
            'distance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
            'photoUrl': null,
          },
          'checkInTime': FieldValue.serverTimestamp(),
          'checkInLatitude': lat,
          'checkInLongitude': lng,
          'checkInDistance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
          'checkInPhotoUrl': null,
          'syncStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docId = '${_currentUser!.uid}_$dateStr';
        final docRef = _db.collection('attendance').doc(docId);

        await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) {
            final existingData = snapshot.data();
            if (existingData != null && existingData['checkIn'] != null) {
              throw Exception('ALREADY_CLOCKED_IN');
            }
          }
          transaction.set(docRef, data);
        });

        // Upload photo after transaction completes (not inside it)
        if (localImagePath != null) {
          _uploadAttendancePhoto(docId, localImagePath);
        }

        // Audit log (non-blocking)
        try {
          await _db.collection('audit_log').add({
            'action': 'attendance_created',
            'actorId': _auth.currentUser!.uid,
            'actorEmail': _currentUser?.email,
            'actorName': _currentUser?.name,
            'targetUserId': _currentUser!.uid,
            'metadata': {
              'attendanceId': docId,
              'type': 'check_in',
              'date': dateStr,
              'latitude': lat,
              'longitude': lng,
            },
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Audit log failed: $e');
        }

        // Mark as synced immediately since we wrote directly
        await _db.collection('attendance').doc(docId).update({'syncStatus': 'synced'});
      } else {
        final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final data = {
          'userId': _currentUser!.uid,
          'employeeName': _currentUser!.name,
          'employeeId': _currentUser!.employeeId,
          'department': _currentUser!.department,
          'role': _currentUser!.role,
          'date': dateStr,
          'attendanceDate': dateStr,
          'status': _mapMobileStatusToAdmin(status),
          'checkIn': {
            'time': DateTime.now().toIso8601String(),
            'latitude': lat,
            'longitude': lng,
            'distance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
            'photoUrl': localImagePath,
          },
          'checkInTime': DateTime.now().toIso8601String(),
          'checkInLatitude': lat,
          'checkInLongitude': lng,
          'checkInDistance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
          'checkInPhotoUrl': localImagePath,
          'syncStatus': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        await OfflineService.savePendingAttendance(data);
        _hasPendingAttendance = true;
      }
    } catch (e) {
      debugPrint('Attendance error: $e');
      if (e.toString().contains('ALREADY_CLOCKED_IN')) {
        throw Exception('Anda sudah melakukan absensi masuk hari ini.');
      }
      throw Exception('Gagal mengirim absensi. Pastikan koneksi stabil atau coba lagi.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final res = await _connectivity.checkConnectivity();
      return !res.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPendingRecords() async {
    if (_currentUser == null) return;
    final pending = await OfflineService.getPendingAttendance();
    if (pending.isEmpty) return;

    int successes = 0;
    int failures = 0;
    List<Map<String, dynamic>> stillPending = [];

     for (var record in pending) {
      try {
         final firestoreData = Map<String, dynamic>.from(record);
         
         // PRESERVE the original offline time if it exists
         final originalTime = record['checkIn']?['time'] ?? record['checkOut']?['time'];
         final DateTime offlineTime = originalTime != null 
             ? (originalTime is String ? DateTime.parse(originalTime) : DateTime.now())
             : await FortressUtils.getServerTime();
         
         final actualDateStr = DateFormat('yyyy-MM-dd').format(offlineTime);
         final docId = '${_currentUser!.uid}_$actualDateStr';
         
         await _db.runTransaction((transaction) async {
           final docRef = _db.collection('attendance').doc(docId);
           final snapshot = await transaction.get(docRef);
           
           if (snapshot.exists) {
             final existingData = snapshot.data();
             final isCheckIn = record['checkIn'] != null;
             
             if (isCheckIn && existingData?['checkIn'] != null) return;
             if (!isCheckIn && existingData?['checkOut'] != null) return;
             
             if (!isCheckIn) {
               transaction.update(docRef, {
                 'checkOut': {
                   ...record['checkOut'],
                   'time': Timestamp.fromDate(offlineTime),
                 },
                 'updatedAt': FieldValue.serverTimestamp(),
               });
               return;
             }
           }

           firestoreData['date'] = actualDateStr;
           firestoreData['attendanceDate'] = actualDateStr;
           
           if (firestoreData['checkIn'] != null) {
             firestoreData['checkIn']['time'] = Timestamp.fromDate(offlineTime);
           }
           if (firestoreData['checkOut'] != null) {
             firestoreData['checkOut']['time'] = Timestamp.fromDate(offlineTime);
           }
           
           firestoreData['createdAt'] = FieldValue.serverTimestamp();
           firestoreData['updatedAt'] = FieldValue.serverTimestamp();
           firestoreData['syncStatus'] = 'synced';

           transaction.set(docRef, firestoreData, SetOptions(merge: true));
         });

        final localPath = record['checkIn']['photoUrl'];
        if (localPath != null && File(localPath).existsSync()) {
          await _uploadAttendancePhoto(docId, localPath);
        }

        successes++;
        record['syncStatus'] = 'synced';
      } catch (e) {
        debugPrint('Sync failed for ${record['attendanceDate']}: $e');
        record['syncStatus'] = 'failed';
        failures++;
        stillPending.add(record);
      }
    }

    await OfflineService.clearPendingAttendance();
    for (var record in stillPending) {
      await OfflineService.savePendingAttendance(record);
    }

    _hasPendingAttendance = stillPending.isNotEmpty;
    notifyListeners();
    debugPrint('Sync complete: $successes success, $failures failed');
  }

  Future<void> addAttendanceCheckOut({String? localImagePath, double lat = 0, double lng = 0}) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    notifyListeners();

    try {
      final record = _attendanceRecords.firstWhere(
        (r) => r.checkIn != null && r.checkOut == null,
        orElse: () => throw Exception('Absensi masuk hari ini tidak ditemukan atau sudah absen keluar.'),
      );

      final checkOutData = {
        'time': DateTime.now().toIso8601String(),
        'latitude': lat,
        'longitude': lng,
        'distance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
        'photoUrl': localImagePath,
      };

      final flatCheckOutData = {
        'checkOutTime': DateTime.now().toIso8601String(),
        'checkOutLatitude': lat,
        'checkOutLongitude': lng,
        'checkOutDistance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
        'checkOutPhotoUrl': localImagePath,
      };

      bool isOnline = await _checkConnectivity();

      if (isOnline) {
        final checkOutMap = Map<String, dynamic>.from(checkOutData);
        final flatMap = Map<String, dynamic>.from(flatCheckOutData);
        final now = FieldValue.serverTimestamp();
        
        checkOutMap['time'] = now;
        flatMap['checkOutTime'] = now;

        final firestoreData = {
          'checkOut': checkOutMap,
          ...flatMap,
          'updatedAt': now,
        };
        
        await _db.collection('attendance').doc(record.id).update(firestoreData);
        if (localImagePath != null) {
          await _uploadAttendancePhoto(record.id, localImagePath, isCheckOut: true);
        }

        // Audit log (non-blocking)
        try {
          await _db.collection('audit_log').add({
            'action': 'attendance_created',
            'actorId': _auth.currentUser!.uid,
            'actorEmail': _currentUser?.email,
            'actorName': _currentUser?.name,
            'targetUserId': _currentUser!.uid,
            'metadata': {
              'attendanceId': record.id,
              'type': 'check_out',
              'date': record.date,
              'latitude': lat,
              'longitude': lng,
            },
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          debugPrint('Audit log failed: $e');
        }
      } else {
        // OFFLINE CHECK-OUT SUPPORT
        final offlineData = {
          'checkOut': {
            ...checkOutData,
            'time': DateTime.now().toIso8601String(),
          },
          'id': record.id,
          'userId': _currentUser!.uid,
          'attendanceDate': record.date,
          'syncStatus': 'pending',
          'updatedAt': DateTime.now().toIso8601String(),
        };

        await OfflineService.savePendingAttendance(offlineData);
        _hasPendingAttendance = true;
      }
    } catch (e) {
      debugPrint('Check-out error: $e');
      throw Exception('Gagal melakukan absen keluar: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _uploadAttendancePhoto(String docId, String localPath, {bool isCheckOut = false}) async {
    try {
      final prefix = isCheckOut ? 'checkout' : 'checkin';
      final ref = FirebaseStorage.instance.ref().child('attendance_photos/${prefix}_$docId.jpg');
      await ref.putFile(File(localPath));
      final url = await ref.getDownloadURL();

      final field = isCheckOut ? 'checkOut.photoUrl' : 'checkIn.photoUrl';
      final legacyField = isCheckOut ? 'checkOutPhotoUrl' : 'checkInPhotoUrl';

      await _db.collection('attendance').doc(docId).update({
        field: url,
        legacyField: url,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Photo upload failed: $e');
    }
  }

  // ── Stats Logic ──
  bool get isLateForClockIn {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, officeStartTime.hour, officeStartTime.minute);
    return now.isAfter(start.add(const Duration(minutes: 1)));
  }

  Map<String, dynamic> calculateOvertime() {
    final overtimeRecords = _attendanceRecords.where((r) => r.status == 'overtime').length;
    return {
      'hours': overtimeRecords * 2,
      'estimatedPay': overtimeRecords * 50000,
    };
  }

  Map<String, dynamic> getStatsForMonth(int month, int year) {
    final monthRecords = _attendanceRecords.where((r) {
      final d = DateTime.tryParse(r.date);
      return d?.month == month && d?.year == year;
    }).toList();

    final approvedLeaves = _leaveRequests.where((r) => 
      r.startDate.month == month && r.startDate.year == year && r.status == 'approved'
    ).toList();

    int present = monthRecords.length;
    int leaves = approvedLeaves.fold<int>(0, (acc, r) => acc + r.totalDays);
    int late = monthRecords.where((r) => r.status == 'late').length;
    
    double punctuality = present > 0 ? ((present - late) / present) : 1.0;

    return {
      'present': present.toString().padLeft(2, '0'),
      'leaves': leaves.toString().padLeft(2, '0'),
      'late': late.toString().padLeft(2, '0'),
      'hours': (present * 8).toString(),
      'punctuality': punctuality,
    };
  }

  // ── SOS Feature ──
  Future<void> sendSOS(double lat, double lng, String locationName) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    _fortressStatus = 'Mengirim sinyal SOS...';
    notifyListeners();

    try {
      await FortressUtils.wrapWithRetry(
        () async {
          final now = FieldValue.serverTimestamp();
          
          // 1. Send to dedicated SOS telemetry for real-time dashboard
          await _db.collection('sos_alerts').add({
            'userId': _currentUser!.uid,
            'employeeName': _currentUser!.name,
            'employeeId': _currentUser!.employeeId,
            'latitude': lat,
            'longitude': lng,
            'locationName': locationName,
            'status': 'active',
            'createdAt': now,
          });

          // 2. Send to global notification registry for history
          await _db.collection('adminNotifications').add({
            'title': '🚨 SOS: ${_currentUser!.name}',
            'message': 'Bantuan Darurat di $locationName ($lat, $lng)',
            'type': 'sos_alert',
            'employeeId': _currentUser!.uid,
            'employeeName': _currentUser!.name,
            'isRead': false,
            'createdAt': now,
          });
        },
        taskName: 'SOS Alert',
        onStatusUpdate: (msg) {
          _fortressStatus = msg;
          notifyListeners();
        },
      );
    } catch (e) {
      throw Exception('Gagal mengirim SOS. Coba hubungi Admin manual.');
    } finally {
      _isProcessing = false;
      _fortressStatus = '';
      notifyListeners();
    }
  }

  // ── Leave & Overtime Methods ──
  Future<void> submitLeave({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required int totalDays,
    required String reason,
  }) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    _fortressStatus = 'Mengirim pengajuan izin...';
    notifyListeners();

    try {
      await FortressUtils.wrapWithRetry(
        () async {
          await _db.collection('leaves').add({
            'userId': _currentUser!.uid,
            'employeeName': _currentUser!.name,
            'employeeId': _currentUser!.employeeId,
            'department': _currentUser!.department,
            'type': type,
            'status': 'pending',
            'startDate': Timestamp.fromDate(startDate),
            'endDate': Timestamp.fromDate(endDate),
            'totalDays': totalDays,
            'reason': reason,
            'createdAt': FieldValue.serverTimestamp(),
          });
        },
        taskName: 'Submit Leave',
        onStatusUpdate: (msg) {
          _fortressStatus = msg;
          notifyListeners();
        },
      );
    } catch (e) {
      throw Exception('Gagal mengirim pengajuan izin. Periksa koneksi Anda.');
    } finally {
      _isProcessing = false;
      _fortressStatus = '';
      notifyListeners();
    }
  }

  Future<void> submitOvertime({
    required DateTime date,
    required String reason,
    required int durationMinutes,
  }) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    notifyListeners();

    try {
      await _db.collection('attendance').add({
        'userId': _currentUser!.uid,
        'employeeName': _currentUser!.name,
        'employeeId': _currentUser!.employeeId,
        'department': _currentUser!.department,
        'date': DateFormat('yyyy-MM-dd').format(date),
        'attendanceDate': DateFormat('yyyy-MM-dd').format(date),
        'status': 'overtime',
        'overtimeMinutes': durationMinutes,
        'notes': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'checkIn': {
          'time': FieldValue.serverTimestamp(),
          'type': 'overtime_manual',
        }
      });
    } catch (e) {
      throw Exception('Gagal mengirim data lembur: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // ── Admin Retrieval for Chat ──
  Future<UserModel?> getFirstAdmin() async {
    try {
      final snap = await _db.collection('users')
          .where('role', whereIn: ['admin', 'superadmin'])
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        return UserModel.fromFirestore(snap.docs.first);
      }
    } catch (e) {
      debugPrint('Error finding admin: $e');
    }
    return null;
  }

  String _mapMobileStatusToAdmin(String status) {
    if (status.contains('Tepat')) return 'present';
    if (status.contains('Lambat')) return 'late';
    if (status.contains('Izin')) return 'leave';
    return 'present';
  }

  void _listenToSettings() {
    _settingsSub = _db.collection('settings').doc('system').snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['office'] != null) {
          _officeLat = (data['office']['latitude'] ?? -3.4150).toDouble();
          _officeLng = (data['office']['longitude'] ?? 114.8465).toDouble();
          _officeRadius = (data['office']['radiusMeters'] ?? 500).toDouble();
        }
      }
    });
  }

  Future<void> registerFace(String localPath) async {
    _isLoadingFace = true;
    notifyListeners();

    try {
      if (_currentUser != null) {
        final uid = _currentUser!.uid;
        final storageRef = FirebaseStorage.instance
            .ref('face_photos/$uid/face_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final uploadTask = await storageRef.putFile(
          File(localPath),
          SettableMetadata(contentType: 'image/jpeg'),
        );
        final faceUrl = await uploadTask.ref.getDownloadURL();

        await _db.collection('users').doc(uid).update({
          'faceRegistered': true,
          'facePhotoUrl': faceUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _currentUser = _currentUser!.copyWith(faceRegistered: true);
      }
    } catch (e) {
      debugPrint("Error registering face: $e");
      rethrow;
    } finally {
      _isLoadingFace = false;
      notifyListeners();
    }
  }

  Future<String> uploadProfilePhoto(String localPath) async {
    if (_currentUser == null) throw Exception('Belum login');
    final uid = _currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_photos/$uid.jpg');
    await ref.putFile(File(localPath));
    final url = await ref.getDownloadURL();
    await _db.collection('users').doc(uid).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _currentUser = _currentUser!.copyWith(photoUrl: url);
    notifyListeners();
    return url;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _syncRetryTimer?.cancel();
    _cancelAllSubscriptions();
    super.dispose();
  }
}
