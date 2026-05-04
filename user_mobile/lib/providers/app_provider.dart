import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';
import 'package:intl/intl.dart';
import '../utils/offline_service.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Office Config ──
  final TimeOfDay officeStartTime = const TimeOfDay(hour: 8, minute: 0);
  final TimeOfDay officeEndTime = const TimeOfDay(hour: 17, minute: 0);
  
  // ── Sync Status ──
  int _pendingSyncCount = 0;
  int get pendingSyncCount => _pendingSyncCount;
  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // ── Auth ──
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';

  final List<UserModel> _accounts = [];
  List<UserModel> get allAccounts => List.unmodifiable(_accounts);
  List<UserModel> get allUsers => _accounts.where((a) => a.role == 'user' || a.role == 'employee').toList();

  AppProvider() {
    _loadUsers();
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
          faceRegisteredDate: d['createdAt'] != null ? DateTime.tryParse(d['createdAt'])?.toIso8601String() ?? '' : '',
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
      // ── STEP 1: PROSES SIGN IN ──
      // Kita hanya melakukan Login (SignIn), bukan mendaftar (Register)
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      } catch (e) {
        if (!e.toString().contains('PigeonUserDetails')) rethrow;
      }

      // ── STEP 2: TUNGGU & VERIFIKASI ──
      await Future.delayed(const Duration(milliseconds: 1000));
      final user = _auth.currentUser;
      
      if (user != null) {
        // ── STEP 3: AMBIL DATA DARI ADMIN (FIRESTORE) ──
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
            faceRegisteredDate: d['createdAt'] != null ? DateTime.tryParse(d['createdAt'])?.toIso8601String() ?? '' : '',
          );
          
          _listenToMyData();
          notifyListeners();
        } else {
          // Jika di Auth ada tapi di Firestore (Admin) belum buat, kita batalkan
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
          msg = 'Email atau password salah';
        } else if (e.code == 'user-disabled') {
          msg = 'Akun Anda telah dinonaktifkan';
        }
        throw Exception(msg);
      }
      
      // Jika error Pigeon muncul tapi login sukses, biarkan lanjut
      if (e.toString().contains('PigeonUserDetails') && _auth.currentUser != null) {
        // Cek ulang data Firestore setelah delay singkat
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
      'createdAt': DateTime.now().toIso8601String(),
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

  void _listenToMyData() {
    if (_currentUser == null) return;

    // Listen Attendance
    _db.collection('attendance').where('userId', isEqualTo: _currentUser!.uid).snapshots().listen((snap) {
      _attendanceRecords = snap.docs.map((doc) {
        final d = doc.data();
        final checkInTime = d['checkIn']?['time'];
        final checkOutTime = d['checkOut']?['time'];
        final dateParsed = d['date'] != null ? DateTime.tryParse(d['date']) : DateTime.now();
        
        return AttendanceRecord(
          id: doc.id,
          userId: d['userId'] ?? '',
          userName: d['employeeName'] ?? '',
          date: dateParsed ?? DateTime.now(),
          checkIn: checkInTime != null ? DateFormat('HH:mm').format(DateTime.parse(checkInTime)) : null,
          checkOut: checkOutTime != null ? DateFormat('HH:mm').format(DateTime.parse(checkOutTime)) : null,
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
          fromDate: d['startDate'] != null ? DateTime.tryParse(d['startDate']) ?? DateTime.now() : DateTime.now(),
          toDate: d['endDate'] != null ? DateTime.tryParse(d['endDate']) ?? DateTime.now() : DateTime.now(),
          reason: d['reason'] ?? '',
          status: d['status'] ?? 'pending',
          submittedAt: d['createdAt'] != null ? DateTime.tryParse(d['createdAt']) ?? DateTime.now() : DateTime.now(),
        );
      }).toList();
      notifyListeners();
    });
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
    final isoStr = now.toIso8601String();

    final data = {
      'userId': userId,
      'employeeName': userName,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? 'Logistik',
      'date': dateStr,
      'status': _mapMobileStatusToAdmin(status),
      'checkIn': {
        'time': isoStr,
        'latitude': lat,
        'longitude': lng,
        'distance': 0,
        'faceScore': 100,
        'photoUrl': localImagePath ?? '',
      },
      'createdAt': isoStr,
      'updatedAt': isoStr,
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
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = _attendanceRecords.firstWhere(
      (r) => DateFormat('yyyy-MM-dd').format(r.date) == today,
      orElse: () => AttendanceRecord(id: '', userId: '', userName: '', date: DateTime(2000)),
    );

    if (record.id == '' || record.checkOut == null) {
      return {'hours': 0, 'minutes': 0, 'pay': 0};
    }

    final checkOutTime = DateTime.parse(record.checkOut!);
    final standardEndTime = DateTime(
      checkOutTime.year, checkOutTime.month, checkOutTime.day,
      officeEndTime.hour, officeEndTime.minute,
    );

    if (checkOutTime.isAfter(standardEndTime)) {
      final diff = checkOutTime.difference(standardEndTime);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final pay = (hours + (minutes / 60)) * 75000; // Contoh Rp 75.000 / jam
      return {'hours': hours, 'minutes': minutes, 'pay': pay};
    }

    return {'hours': 0, 'minutes': 0, 'pay': 0};
  }

  Future<void> submitEditRequest(String attendanceId, String reason, Map<String, dynamic> changes) async {
    final isoStr = DateTime.now().toIso8601String();
    await _db.collection('edit_requests').add({
      'attendanceId': attendanceId,
      'userId': _currentUser?.uid,
      'userName': _currentUser?.name,
      'reason': reason,
      'status': 'pending',
      'requestedChanges': changes,
      'createdAt': isoStr,
      'updatedAt': isoStr,
    });
    addNotification('Pengajuan Edit', 'Permintaan koreksi data absensi telah dikirim ke Admin.');
  }

  Future<void> submitLeave(LeaveRequest req) async {
    final isoStr = DateTime.now().toIso8601String();
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
      'createdAt': isoStr,
      'updatedAt': isoStr,
    });
  }

  void updateLeaveStatus(String id, String status) {
    _db.collection('leaves').doc(id).update({
      'status': status,
      'updatedAt': DateTime.now().toIso8601String(),
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
}