import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/offline_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Office Hours ──
  final TimeOfDay officeStartTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay officeEndTime = const TimeOfDay(hour: 17, minute: 0);

  // ── Sync Status ──
  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // ── Theme ──
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ── Office Config ──
  double _officeLat = -3.4150;
  double _officeLng = 114.8465;
  double _officeRadius = 500.0;
  // Office rules from DepartmentRules (simplified)
  double get officeLat => _officeLat;
  double get officeLng => _officeLng;
  double get officeRadius => _officeRadius;

  void Function(double lat, double lng, double radius)? onSettingsChanged;

  // ── Auth ──
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  
  // Subscriptions for cleanup
  StreamSubscription? _adminNotifSub;

  final List<UserModel> _accounts = [];
  List<UserModel> get allAccounts => List.unmodifiable(_accounts);
  List<UserModel> get allUsers => _accounts.where((a) => a.role == 'user' || a.role == 'employee').toList();

  // ── Notification Streams (Firestore) ──
  List<AdminNotification> _adminNotifications = [];
  List<AdminNotification> _userNotifications = [];
  List<AdminNotification> get notifications => isAdmin ? _adminNotifications : _userNotifications;
  int get unreadNotificationCount => notifications.where((n) => !n.isRead).length;

  StreamSubscription? _userNotifSub;

  AppProvider() {
    _loadUsers();
    _listenToSettings();
    _listenToSharedData();
  }

  Future<void> _loadUsers() async {
    // Dipanggil hanya untuk sync lokal jika diperlukan, tapi login via Auth
    if (_auth.currentUser != null) {
      await _fetchCurrentUser(_auth.currentUser!.uid);
    }
  }

  Future<void> _fetchCurrentUser(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final d = doc.data()!;
        _currentUser = UserModel(
          uid: doc.id,
          name: d['name'] ?? '',
          email: d['email'] ?? '',
          phone: d['phone'] ?? '',
          nik: d['employeeId'] ?? '',
          role: d['role'] ?? 'employee',
          department: d['department'] ?? '',
          position: d['position'] ?? '',
          faceRegistered: d['faceRegistered'] == true ? 'yes' : 'no',
          deviceName: d['deviceName'] ?? '',
          faceRegisteredDate: _parseDateTime(d['createdAt'])?.toIso8601String() ?? '',
        );
        _listenToMyData();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        if (kDebugMode && e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential')) {
          // Auto-signup for development in emulator
          try {
            await _auth.createUserWithEmailAndPassword(email: email, password: password);
            final user = _auth.currentUser;
            if (user != null) {
              await _db.collection('users').doc(user.uid).set({
                'name': email.split('@')[0].replaceAll('.', ' ').toUpperCase(),
                'email': email,
                'role': 'employee',
                'employeeId': 'JNE-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                'createdAt': FieldValue.serverTimestamp(),
                'faceRegistered': false,
              });
            }
          } catch (signUpError) {
            rethrow;
          }
        } else if (!e.toString().contains('PigeonUserDetails')) {
          rethrow;
        }
      }

      await Future.delayed(const Duration(milliseconds: 1000));
      final user = _auth.currentUser;
      
      if (user != null) {
        final doc = await _db.collection('users').doc(user.uid).get();
        
        if (doc.exists) {
          final d = doc.data()!;
          _currentUser = UserModel(
            uid: doc.id,
            name: d['name'] ?? 'User',
            email: d['email'] ?? email,
            phone: d['phone'] ?? '',
            nik: d['employeeId'] ?? d['nik'] ?? '',
            role: d['role'] ?? 'employee',
            department: d['department'] ?? 'Umum',
            position: d['position'] ?? 'Staff',
            faceRegistered: d['faceRegistered'] == true ? 'yes' : 'no',
            deviceName: d['deviceName'] ?? '',
            faceRegisteredDate: _parseDateTime(d['createdAt'])?.toIso8601String() ?? '',
          );
          
          _listenToMyData();
          notifyListeners();
        } else {
          await _auth.signOut();
          throw Exception('Data profil Anda belum dibuat oleh Admin. Hubungi pihak JNE.');
        }
      } else {
        throw Exception('Email atau password salah.');
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        String msg = 'Gagal masuk';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'user-not-found') {
          msg = 'Email atau password salah. Coba periksa koneksi emulator Anda.';
        } else if (e.code == 'user-disabled') {
          msg = 'Akun Anda telah dinonaktifkan';
        }
        throw Exception(msg);
      }
      
      if (e.toString().contains('PigeonUserDetails') && _auth.currentUser != null) {
        return login(email, password); 
      }
      throw Exception(e.toString());
    }
  }

  void logout() async {
    await _auth.signOut();
    _currentUser = null;
    _attendanceRecords.clear();
    _leaveRequests.clear();
    _adminNotifSub?.cancel();
    _adminNotifSub = null;
    _userNotifSub?.cancel();
    _userNotifSub = null;
    notifyListeners();
  }

  void register(UserModel user) async {
    final docRef = _db.collection('users').doc();
    await docRef.set({
      'uid': docRef.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'employeeId': user.nik,
      'role': user.role,
      'department': user.department,
      'position': user.position,
      'faceRegistered': user.faceRegistered == 'yes',
      'deviceName': user.deviceName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    _currentUser = UserModel(
      uid: docRef.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      nik: user.nik,
      role: user.role,
      department: user.department,
      position: user.position,
      faceRegistered: user.faceRegistered,
      deviceName: user.deviceName,
      faceRegisteredDate: user.faceRegisteredDate,
    );
    _listenToMyData();
    notifyListeners();
  }

  void updateCurrentUser(UserModel updated) async {
    await _db.collection('users').doc(updated.uid).update({
      'name': updated.name,
      'phone': updated.phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    _currentUser = updated;
    notifyListeners();
  }

  // ── Notification Settings ──
  NotificationSettings _notifSettings = const NotificationSettings();
  NotificationSettings get notifSettings => _notifSettings;
  void updateNotifSettings(NotificationSettings s) {
    _notifSettings = s;
    notifyListeners();
  }

  // ── Data Real-time Sync ──
  List<AttendanceRecord> _attendanceRecords = [];
  List<AttendanceRecord> get myAttendance => _attendanceRecords;
  
  bool get hasClockedInToday {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _attendanceRecords.any((r) => DateFormat('yyyy-MM-dd').format(r.date) == today && r.checkIn != null);
  }

  bool get isLateForClockIn {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, officeStartTime.hour, officeStartTime.minute);
    return now.isAfter(start) && !hasClockedInToday;
  }

  List<AttendanceRecord> get allAttendance => List.unmodifiable(_attendanceRecords);

  List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> get myLeaveRequests => _leaveRequests;
  List<LeaveRequest> get allLeaveRequests => List.unmodifiable(_leaveRequests);

  List<OvertimeRecord> _overtimeRequests = [];
  List<OvertimeRecord> get myOvertimeRequests => _overtimeRequests;
  int get totalOvertimeHours => _overtimeRequests.where((o) => o.status == 'approved').fold(0, (acc, item) => acc + item.durationHours);

  // ── Additional Shared Collections ──
  List<JamKerja> _shiftList = [];
  List<JamKerja> get shiftList => List.unmodifiable(_shiftList);

  List<DepartmentItem> _departments = [];
  List<DepartmentItem> get departments => List.unmodifiable(_departments);

  List<CalendarEvent> _events = [];
  List<CalendarEvent> get events => List.unmodifiable(_events);



  SystemSettings? _systemSettings;
  SystemSettings? get systemSettings => _systemSettings;

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // ── Mappers ──
  JamKerja _mapJamKerja(String id, Map<String, dynamic> d) {
    return JamKerja(
      id: id,
      name: d['name'] ?? '',
      checkInTime: d['checkInTime'] ?? '08:00',
      checkOutTime: d['checkOutTime'] ?? '17:00',
      toleranceMinutes: d['toleranceMinutes'] ?? 15,
      workingDays: List<String>.from(d['workingDays'] ?? ['monday','tuesday','wednesday','thursday','friday']),
      color: d['color'] ?? '#3B82F6',
      isActive: d['isActive'] ?? true,
      createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(d['updatedAt']) ?? DateTime.now(),
    );
  }

  DepartmentItem _mapDepartment(String id, Map<String, dynamic> d) {
    return DepartmentItem(
      id: id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      color: d['color'] ?? '#E31E24',
      isActive: d['isActive'] ?? true,
      createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(d['updatedAt']) ?? DateTime.now(),
    );
  }

  CalendarEvent _mapEvent(String id, Map<String, dynamic> d) {
    return CalendarEvent(
      id: id,
      title: d['title'] ?? '',
      description: d['description'] ?? '',
      startDate: _parseDateTime(d['startDate']) ?? DateTime.now(),
      endDate: _parseDateTime(d['endDate']) ?? DateTime.now(),
      location: d['location'],
      category: d['category'] ?? 'other',
      attendees: List<String>.from(d['attendees'] ?? []),
      departments: d['departments'] != null ? List<String>.from(d['departments']) : null,
      organizerId: d['organizerId'] ?? '',
      color: d['color'],
      imageUrl: d['imageUrl'],
      price: d['price']?.toInt(),
      ticketsLeft: d['ticketsLeft']?.toInt(),
      notificationSentDayBefore: d['notificationSentDayBefore'] ?? false,
      notificationSent30Min: d['notificationSent30Min'] ?? false,
      createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(d['updatedAt']) ?? DateTime.now(),
    );
  }

  AdminNotification _mapAdminNotification(String id, Map<String, dynamic> d) {
    return AdminNotification(
      id: id,
      type: d['type'] ?? 'system',
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      employeeId: d['employeeId'],
      employeeName: d['employeeName'],
      relatedId: d['relatedId'],
      isRead: d['isRead'] ?? false,
      createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
    );
  }

  SystemSettings? _mapSystemSettings(Map<String, dynamic>? data) {
    if (data == null) return null;
    try {
      final office = data['office'] ?? {};
      final attendance = data['attendance'] ?? {};
      final notifications = data['notifications'] ?? {};
      final company = data['company'] ?? {};
      return SystemSettings(
        office: OfficeSettings(
          name: office['name'] ?? 'Office',
          address: office['address'] ?? '',
          latitude: (office['latitude'] ?? -3.4150).toDouble(),
          longitude: (office['longitude'] ?? 114.8465).toDouble(),
          radiusMeters: (office['radiusMeters'] ?? 500).toInt(),
        ),
        attendance: AttendanceSettings(
          maxFaceAttempts: (attendance['maxFaceAttempts'] ?? 3).toInt(),
          faceSimilarityThreshold: (attendance['faceSimilarityThreshold'] ?? 80).toInt(),
          allowOfflineAttendance: attendance['allowOfflineAttendance'] ?? false,
          overtimeCalculation: attendance['overtimeCalculation'] ?? false,
        ),
        notifications: AdminNotificationSettings(
          notifyOnLeaveRequest: notifications['notifyOnLeaveRequest'] ?? true,
          notifyOnFaceEnrollment: notifications['notifyOnFaceEnrollment'] ?? true,
          notifyOnFaceFailure: notifications['notifyOnFaceFailure'] ?? true,
          notifyOnNewEmployee: notifications['notifyOnNewEmployee'] ?? true,
          emailNotifications: notifications['emailNotifications'] ?? false,
          adminEmail: notifications['adminEmail'] ?? '',
        ),
        company: CompanySettings(
          companyName: company['companyName'] ?? 'JNE MTP',
          logoUrl: company['logoUrl'],
          hrEmail: company['hrEmail'] ?? '',
          hrPhone: company['hrPhone'] ?? '',
          appDownloadUrl: company['appDownloadUrl'] ?? '',
        ),
      );
    } catch (e) {
      debugPrint('Error mapping system settings: $e');
      return null;
    }
  }

  void _listenToSettings() {
    _db.collection('settings').doc('system').snapshots().listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        if (data != null && data['office'] != null) {
          final office = data['office'];
          _officeLat = (office['latitude'] ?? -3.4150).toDouble();
          _officeLng = (office['longitude'] ?? 114.8465).toDouble();
          _officeRadius = (office['radiusMeters'] ?? 500).toDouble();
          
          debugPrint('Settings updated: $_officeLat, $_officeLng, $_officeRadius');
          onSettingsChanged?.call(_officeLat, _officeLng, _officeRadius);
        }
        // Map full settings
        _systemSettings = _mapSystemSettings(data);
        notifyListeners();
      }
    });
  }

  void _listenToSharedData() {
    // ── Shifts (Jam Kerja) ──
    _db.collection('shifts').snapshots().listen((snap) {
      _shiftList = snap.docs.map((d) => _mapJamKerja(d.id, d.data())).toList();
      notifyListeners();
    });

    // ── Departments ──
    _db.collection('departments').snapshots().listen((snap) {
      _departments = snap.docs.map((d) => _mapDepartment(d.id, d.data())).toList();
      notifyListeners();
    });

    // ── Events ──
    _db.collection('events').orderBy('startDate').snapshots().listen((snap) {
      _events = snap.docs.map((d) => _mapEvent(d.id, d.data())).toList();
      notifyListeners();
    });

    // ── Admin Notifications (only for admin users) ──
    if (_currentUser != null && (isAdmin)) {
      _db.collection('adminNotifications')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots()
          .listen((snap) {
        _adminNotifications = snap.docs.map((d) => _mapAdminNotification(d.id, d.data())).toList();
        notifyListeners();
      });
    }
  }

  void _listenToMyData() {
    if (_currentUser == null) return;

    // Cancel any existing notification subscriptions
    _adminNotifSub?.cancel();
    _adminNotifSub = null;
    _userNotifSub?.cancel();
    _userNotifSub = null;

    // Listen Attendance
    _db.collection('attendance').where('userId', isEqualTo: _currentUser!.uid).snapshots().listen((snap) {
      _attendanceRecords = snap.docs.map((doc) {
        final d = doc.data();
        final checkInTime = d['checkIn']?['time'];
        final checkOutTime = d['checkOut']?['time'];
        final dateParsed = _parseDateTime(d['date']);
        
        return AttendanceRecord(
          id: doc.id,
          userId: d['userId'] ?? '',
          userName: d['employeeName'] ?? '',
          date: dateParsed ?? DateTime.now(),
          checkIn: checkInTime != null ? DateFormat('HH:mm').format(_parseDateTime(checkInTime) ?? DateTime.now()) : null,
          checkOut: checkOutTime != null ? DateFormat('HH:mm').format(_parseDateTime(checkOutTime) ?? DateTime.now()) : null,
          checkInStatus: _mapAdminStatusToMobile(d['status']),
          checkOutStatus: checkOutTime != null ? 'Selesai' : 'Menunggu',
          location: 'JNE Martapura',
        );
      }).toList();
      notifyListeners();
    });

    // Listen Leaves
    _db.collection('leaves').where('userId', isEqualTo: _currentUser!.uid).snapshots().listen((snap) {
      _leaveRequests = snap.docs.map((doc) {
        final d = doc.data();
        return LeaveRequest(
          id: doc.id,
          userId: d['userId'] ?? '',
          userName: d['employeeName'] ?? '',
          fromDate: _parseDateTime(d['startDate']) ?? DateTime.now(),
          toDate: _parseDateTime(d['endDate']) ?? DateTime.now(),
          reason: d['reason'] ?? '',
          status: d['status'] ?? 'pending',
          submittedAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
        );
      }).toList();
      notifyListeners();
    });

    // Listen Overtime
    _db.collection('overtime').where('userId', isEqualTo: _currentUser!.uid).snapshots().listen((snap) {
      _overtimeRequests = snap.docs.map((doc) {
        final d = doc.data();
        return OvertimeRecord(
          id: doc.id,
          userId: d['userId'] ?? '',
          userName: d['employeeName'] ?? '',
          date: _parseDateTime(d['date']) ?? DateTime.now(),
          durationHours: d['durationHours'] ?? 0,
          reason: d['reason'] ?? '',
          status: d['status'] ?? 'pending',
          createdAt: _parseDateTime(d['createdAt']) ?? DateTime.now(),
        );
      }).toList();
      notifyListeners();
    });

    // ── Notifications ──
    if (isAdmin) {
      // Admin sees all notifications
      _adminNotifSub = _db.collection('adminNotifications')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snap) {
        _adminNotifications = snap.docs.map((d) => _mapAdminNotification(d.id, d.data())).toList();
        notifyListeners();
      });
    } else {
      // Employee sees only their own notifications (by employeeId)
      _userNotifSub = _db.collection('adminNotifications')
          .where('employeeId', isEqualTo: _currentUser!.uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snap) {
        _userNotifications = snap.docs.map((d) => _mapAdminNotification(d.id, d.data())).toList();
        notifyListeners();
      });
    }
  }

  String _mapAdminStatusToMobile(String? status) {
    switch (status) {
      case 'present': return 'Tepat Waktu';
      case 'late': return 'Terlambat';
      case 'absent': return 'Alpha';
      case 'leave': return 'Izin';
      case 'overtime': return 'Lembur';
      default: return 'Tepat Waktu';
    }
  }

  String _mapMobileStatusToAdmin(String status) {
    if (status.contains('Tepat')) return 'present';
    if (status.contains('Lambat')) return 'late';
    if (status.contains('Izin')) return 'leave';
    if (status.contains('Alpha')) return 'absent';
    return 'present';
  }

  Future<void> addAttendanceCheckIn(String userId, String userName, String status, String location, {
    bool isOffline = false, 
    String? localImagePath,
    double lat = 0,
    double lng = 0,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final data = {
      'userId': userId,
      'employeeName': userName,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? 'Logistik',
      'date': dateStr,
      'status': _mapMobileStatusToAdmin(status),
      'checkIn': {
        'time': FieldValue.serverTimestamp(),
        'latitude': lat,
        'longitude': lng,
        'distance': Geolocator.distanceBetween(
          lat, 
          lng, 
          _officeLat, 
          _officeLng
        ).round(),
        'faceScore': 100,
        'photoUrl': localImagePath ?? '',
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isOffline) {
      await OfflineService.savePendingAttendance(data);
      _checkPendingSync();
      addNotification('Offline Absensi', 'Absensi disimpan di device (PENDING). Akan otomatis upload saat internet kembali.');
    } else {
      await _db.collection('attendance').add(data);
    }
  }

  Future<void> _checkPendingSync() async {
    final pending = await OfflineService.getPendingAttendance();
    _pendingSyncCount = pending.length;
    notifyListeners();
  }

  Future<void> syncPendingAttendance() async {
    if (_isSyncing) return;
    _isSyncing = true;
    notifyListeners();

    try {
      final pending = await OfflineService.getPendingAttendance();
      for (var item in pending) {
        await _db.collection('attendance').add(item);
      }
      await OfflineService.clearPendingAttendance();
      await _checkPendingSync();
      addNotification('Sync Success', 'Semua absensi offline telah berhasil diunggah.');
    } catch (e) {
      debugPrint('Sync failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> calculateOvertime() {
    int totalHours = totalOvertimeHours;
    int estimatedPay = totalHours * 25000; // Mock rate per hour
    return {
      'hours': totalHours,
      'pay': estimatedPay,
    };
  }

  Future<void> submitEditRequest(String attendanceId, String reason, Map<String, dynamic> changes) async {
    await _db.collection('edit_requests').add({
      'attendanceId': attendanceId,
      'userId': _currentUser?.uid,
      'userName': _currentUser?.name,
      'reason': reason,
      'status': 'pending',
      'requestedChanges': changes,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    addNotification('Pengajuan Edit', 'Permintaan koreksi data absensi telah dikirim ke Admin.');
  }

  Future<void> submitLeave(LeaveRequest req) async {
    await _db.collection('leaves').add({
      'userId': req.userId,
      'employeeName': req.userName,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? '',
      'type': 'other',
      'status': 'pending',
      'startDate': req.fromDate.toIso8601String(),
      'endDate': req.toDate.toIso8601String(),
      'totalDays': req.toDate.difference(req.fromDate).inDays + 1,
      'reason': req.reason,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void updateLeaveStatus(String id, String status) {
    _db.collection('leaves').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Meetings (Mock for now or sync if admin has collection) ──
  final List<MeetingModel> _meetings = [
    MeetingModel(id: 'm1', title: 'Briefing Tim Operasional', dateTime: DateTime(2026, 2, 18, 14, 0), room: 'Ruang Rapat A', createdBy: 'admin_001', description: 'Briefing rutin tim mingguan'),
  ];
  List<MeetingModel> get meetings => List.unmodifiable(_meetings);
  
  // ── Notifications (Mock) ──
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get myNotifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['read'] == false).length;
  
  void markAllRead() {
    for (var n in _notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  void addNotification(String title, String body, {String targetUserId = ''}) {
    _notifications.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'read': false,
      'targetUserId': targetUserId,
      'time': DateTime.now(),
    });
    notifyListeners();
  }

  // ── Overtime Feature ──
  Future<void> submitOvertime(DateTime date, int durationHours, String reason) async {
    await _db.collection('overtime').add({
      'userId': _currentUser?.uid,
      'employeeName': _currentUser?.name,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? '',
      'date': DateFormat('yyyy-MM-dd').format(date),
      'durationHours': durationHours,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    addNotification('Pengajuan Lembur', 'Permintaan lembur untuk tanggal ${DateFormat('dd MMM').format(date)} telah dikirim.');
  }

  // ── Emergency SOS Feature ──
  Future<void> sendSOS(double lat, double lng, String locationName) async {
    await _db.collection('sos_alerts').add({
      'userId': _currentUser?.uid,
      'employeeName': _currentUser?.name,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? '',
      'latitude': lat,
      'longitude': lng,
      'locationName': locationName,
      'status': 'active',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    addNotification('SOS TERKIRIM', 'Pesan darurat dan lokasi Anda telah dikirim ke pusat kendali Admin.');
  }
}