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
import 'package:geolocator/geolocator.dart';
import '../models/app_models.dart';
import '../utils/offline_service.dart';
import '../utils/connectivity_service.dart';
import '../utils/fortress_utils.dart';
import '../utils/presence_service.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // Data Lists
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> get myAttendance => _attendanceRecords;

  List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> get myLeaveRequests => _leaveRequests;

  List<OvertimeRequest> _overtimeRequests = [];
  List<OvertimeRequest> get myOvertimeRequests => _overtimeRequests;

  List<DisputeRequest> _disputeRequests = [];
  List<DisputeRequest> get myDisputeRequests => _disputeRequests;

  // Admin-set leave balance from Firestore (null = not yet loaded)
  LeaveBalance? _firestoreLeaveBalance;

  /// Returns admin-set quota if available, otherwise computes from leave history.
  LeaveBalance get leaveBalance {
    if (_firestoreLeaveBalance != null) {
      final now = DateTime.now();
      final pending = _leaveRequests.where((l) =>
          l.status == 'pending' &&
          (l.startDate.year == now.year || l.endDate.year == now.year));
      return LeaveBalance(
        annualQuota: _firestoreLeaveBalance!.annualQuota,
        usedAnnual: _firestoreLeaveBalance!.usedAnnual,
        usedSick: _firestoreLeaveBalance!.usedSick,
        usedPermission: _firestoreLeaveBalance!.usedPermission,
        pendingDays: pending.fold(0, (s, l) => s + l.totalDays),
        updatedBy: _firestoreLeaveBalance!.updatedBy,
        updatedAt: _firestoreLeaveBalance!.updatedAt,
      );
    }
    const quota = 12;
    final now = DateTime.now();
    final thisYear = now.year;
    final yearLeaves = _leaveRequests.where((l) {
      return l.startDate.year == thisYear || l.endDate.year == thisYear;
    });
    final approved = yearLeaves.where((l) => l.status == 'approved');
    final pending  = yearLeaves.where((l) => l.status == 'pending');
    return LeaveBalance(
      annualQuota: quota,
      usedAnnual:     approved.where((l) => l.type == 'annual').fold(0, (s, l) => s + l.totalDays),
      usedSick:       approved.where((l) => l.type == 'sick').fold(0, (s, l) => s + l.totalDays),
      usedPermission: approved.where((l) => l.type != 'annual' && l.type != 'sick').fold(0, (s, l) => s + l.totalDays),
      pendingDays:    pending.fold(0, (s, l) => s + l.totalDays),
    );
  }

  // Dipisah agar tidak ada race condition saat kedua snapshot tiba bersamaan
  final List<AdminNotification> _personalNotifs = [];
  final List<AdminNotification> _broadcastNotifs = [];

  List<AdminNotification> get notifications {
    final merged = [..._personalNotifs, ..._broadcastNotifs];
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(merged);
  }

  int get unreadNotificationCount {
    return [..._personalNotifs, ..._broadcastNotifs].where((n) => !n.isRead).length;
  }

  Future<void> markNotificationAsRead(String notifId) async {
    try {
      // Try userNotifications first, then broadcasts
      try {
        await _db.collection('userNotifications').doc(notifId).update({'isRead': true});
      } catch (_) {
        try {
          await _db.collection('broadcasts').doc(notifId).update({'isRead': true});
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('markNotificationAsRead error: $e');
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      final batch = _db.batch();
      for (final n in _personalNotifs.where((n) => !n.isRead)) {
        batch.update(_db.collection('userNotifications').doc(n.id), {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('markAllNotificationsRead error: $e');
    }
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
  StreamSubscription? _overtimeSub;
  StreamSubscription? _disputeSub;
  StreamSubscription? _leaveBalanceSub;
  StreamSubscription? _presenceSub;

  // Timers
  Timer? _heartbeatTimer;
  Timer? _syncRetryTimer;

  AppProvider(ConnectivityService connectivityService) {
    _init();
    WidgetsBinding.instance.addObserver(this);
    
    connectivityService.addListener(() {
      if (connectivityService.isOnline && isLoggedIn) {
        syncPendingRecords();
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    });
  }

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
        _listenToLeaves();
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

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = UserModel.fromFirestore(doc);
        _listenToMyData();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    } finally {
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

    _overtimeSub = _db.collection('overtime')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _overtimeRequests = snap.docs.map((doc) => OvertimeRequest.fromFirestore(doc)).toList();
      notifyListeners();
    });

    // Disputes
    _disputeSub = _db.collection('disputes')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .listen((snap) {
      _disputeRequests = snap.docs.map((doc) => DisputeRequest.fromFirestore(doc)).toList();
      notifyListeners();
    }, onError: (e) => debugPrint('Dispute listener error: $e'));

    // Leave balance from admin (collection: leave_balances/{uid})
    _leaveBalanceSub = _db.collection('leave_balances')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen((snap) {
      _firestoreLeaveBalance = snap.exists ? LeaveBalance.fromFirestore(snap) : null;
      notifyListeners();
    }, onError: (e) => debugPrint('LeaveBalance listener error: $e'));
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
      _notifications.removeWhere((n) => n.type == 'broadcast');
      _notifications.addAll(newNotifs);
    } else {
      _notifications.removeWhere((n) => n.type != 'broadcast');
      _notifications.addAll(newNotifs);
    }
    
    _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  void _cancelAllSubscriptions() {
    _settingsSub?.cancel();
    _notifSub?.cancel();
    _broadcastSub?.cancel();
    _eventSub?.cancel();
    _attendanceSub?.cancel();
    _leaveSub?.cancel();
    _overtimeSub?.cancel();
    _disputeSub?.cancel();
    _leaveBalanceSub?.cancel();
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

  void _listenToLeaves() {
    if (_currentUser == null) return;
    _leaveSub = _db
        .collection('leaves')
        .where('userId', isEqualTo: _currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _leaveRequests = snap.docs.map((doc) => LeaveRequest.fromFirestore(doc)).toList();
      notifyListeners();
    });
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
      _updatePresence(true);
      _startHeartbeat();
    } catch (e) {
      throw Exception('Email atau password salah atau gangguan server. Coba cek kembali ya.');
    } finally {
      _isProcessing = false;
      _fortressStatus = '';
      notifyListeners();
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

  void logout() async {
    _stopHeartbeat();
    _cancelAllSubscriptions();
    await _auth.signOut();
    _currentUser = null;
    _attendanceRecords.clear();
    _monthlyRecords.clear();
    _leaveRequests.clear();
    _notifications.clear();
    _events.clear();
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
    return _attendanceRecords.any((r) => r.checkIn != null && r.checkOut == null);
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
          'attendanceDate': dateStr,
          'status': _mapMobileStatusToAdmin(status),
          'checkIn': {
            'time': FieldValue.serverTimestamp(),
            'latitude': lat,
            'longitude': lng,
            'distance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
            'photoUrl': localImagePath,
          },
          'checkInTime': FieldValue.serverTimestamp(),
          'checkInLatitude': lat,
          'checkInLongitude': lng,
          'checkInDistance': Geolocator.distanceBetween(lat, lng, _officeLat, _officeLng).round(),
          'checkInPhotoUrl': localImagePath,
          'syncStatus': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docId = '${_currentUser!.uid}_$dateStr';
        final docRef = _db.collection('attendance').doc(docId);

        await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (snapshot.exists) {
            throw Exception('Anda sudah melakukan absensi masuk hari ini.');
          }
          transaction.set(docRef, data);
          if (localImagePath != null) {
            _uploadAttendancePhoto(docId, localImagePath);
          }
        });

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
      throw Exception('Gagal mengirim absensi. Data akan disimpan secara otomatis jika offline.');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncPendingRecords() async {
    final pending = await OfflineService.getPendingAttendance();
    if (pending.isEmpty) return;

    int successes = 0;
    int failures = 0;
    List<Map<String, dynamic>> stillPending = [];

    for (var record in pending) {
      try {
        // Use server time to determine the attendance date (prevent device clock manipulation)
        final serverNow = await FortressUtils.getServerTime();
        final dateStr = DateFormat('yyyy-MM-dd').format(serverNow);
        final docId = '${_currentUser!.uid}_$dateStr';
        
         await _db.runTransaction((transaction) async {
           final docRef = _db.collection('attendance').doc(docId);
           final snapshot = await transaction.get(docRef);
           if (snapshot.exists) {
             return; // Already exists
           }
           final firestoreData = Map<String, dynamic>.from(record);
           final now = FieldValue.serverTimestamp();

           // Override with server timestamp for all time fields
           firestoreData['attendanceDate'] = dateStr;
           firestoreData['checkIn']['time'] = now;
           firestoreData['checkInTime'] = now;
           firestoreData['createdAt'] = now;
           firestoreData['updatedAt'] = now;
           firestoreData['syncStatus'] = 'syncing';

           firestoreData['checkIn']['photoUrl'] = 'uploading...';
           firestoreData['checkInPhotoUrl'] = 'uploading...';

           transaction.set(docRef, firestoreData);
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
        throw Exception('Koneksi internet diperlukan untuk absen keluar.');
      }
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
          .where('role', whereIn: ['admin', 'moderator'])
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
        await Future.delayed(const Duration(seconds: 2));
        await _db.collection('users').doc(_currentUser!.uid).update({
          'faceRegistered': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        _currentUser = _currentUser!.copyWith(faceRegistered: true);
      }
    } catch (e) {
      debugPrint("Error registering face: $e");
    } finally {
      _isLoadingFace = false;
      notifyListeners();
    }
  }

  Future<void> submitDispute({
    required String category,
    required String title,
    required String description,
    String? relatedAttendanceId,
  }) async {
    if (_currentUser == null) return;
    _isProcessing = true;
    _fortressStatus = 'Mengirim komplain...';
    notifyListeners();

    try {
      await _db.collection('disputes').add({
        'userId': _currentUser!.uid,
        'employeeName': _currentUser!.name,
        'employeeId': _currentUser!.employeeId,
        'department': _currentUser!.department,
        'category': category,
        'title': title,
        'description': description,
        'relatedAttendanceId': relatedAttendanceId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Notify Admin
      await _db.collection('adminNotifications').add({
        'title': '🚨 Komplain Baru: ${_currentUser!.name}',
        'message': '$title ($category)',
        'type': 'dispute',
        'employeeId': _currentUser!.uid,
        'employeeName': _currentUser!.name,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengirim komplain: $e');
    } finally {
      _isProcessing = false;
      _fortressStatus = '';
      notifyListeners();
    }
  }

  Future<void> cancelLeaveRequest(String requestId) async {
    try {
      await _db.collection('leaves').doc(requestId).delete();
    } catch (e) {
      throw Exception('Gagal membatalkan izin: $e');
    }
  }

  Future<void> cancelOvertimeRequest(String requestId) async {
    try {
      await _db.collection('overtime').doc(requestId).delete();
    } catch (e) {
      throw Exception('Gagal membatalkan lembur: $e');
    }
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
