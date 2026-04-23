import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';
import 'package:intl/intl.dart';

class AppProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Theme ──
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

  List<UserModel> _accounts = [];
  List<UserModel> get allAccounts => List.unmodifiable(_accounts);
  List<UserModel> get allUsers => _accounts.where((a) => a.role == 'user' || a.role == 'employee').toList();

  AppProvider() {
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final snap = await _db.collection('employees').get();
      if (snap.docs.isEmpty) {
        // Fallback to memory if empty (to avoid blank screen)
        _accounts = [
          const UserModel(uid: 'admin_001', name: 'Admin JNE', email: 'admin@jne.co.id', phone: '+62 811-0000-0001', nik: 'ADM001', role: 'admin', department: 'Management', position: 'Administrator', faceRegistered: 'yes', deviceName: 'Admin Device', faceRegisteredDate: '1 Jan 2026'),
          const UserModel(uid: 'user_001', name: 'Nabihan', email: 'nabihan.testing@jne', phone: '+62 000-0000-0000', nik: '0012345', role: 'employee', department: 'Departemen Logistik', position: 'Staff Operasional', faceRegistered: 'yes', deviceName: 'Samsung Galaxy S24 Ultra', faceRegisteredDate: '1 Jan 2026'),
        ];
      } else {
        _accounts = snap.docs.map((doc) {
          final d = doc.data();
          return UserModel(
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
        }).toList();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  Future<void> login(String email, String password) async {
    try {
      // Refresh users
      await _loadUsers();
      final acc = _accounts.firstWhere(
        (a) => a.email.toLowerCase() == email.toLowerCase(),
        orElse: () => const UserModel(uid: '', name: '', email: '', phone: '', nik: '', role: '', department: '', position: ''),
      );
      if (acc.uid.isNotEmpty) {
        _currentUser = acc;
        _listenToMyData();
        notifyListeners();
      } else {
        throw Exception('Email atau password salah');
      }
    } catch (e) {
      throw Exception('Gagal login: $e');
    }
  }

  void logout() {
    _currentUser = null;
    _attendanceRecords.clear();
    _leaveRequests.clear();
    notifyListeners();
  }

  void register(UserModel user) async {
    final docRef = _db.collection('employees').doc();
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
    await _db.collection('employees').doc(updated.uid).update({
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

  Future<void> addAttendanceCheckIn(String userId, String userName, String status, String location) async {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final isoStr = now.toIso8601String();

    await _db.collection('attendance').add({
      'userId': userId,
      'employeeName': userName,
      'employeeId': _currentUser?.nik ?? '',
      'department': _currentUser?.department ?? 'Logistik',
      'date': dateStr,
      'status': _mapMobileStatusToAdmin(status),
      'checkIn': {
        'time': isoStr,
        'latitude': 0,
        'longitude': 0,
        'distance': 0,
        'faceScore': 100,
      },
      'createdAt': isoStr,
      'updatedAt': isoStr,
    });
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