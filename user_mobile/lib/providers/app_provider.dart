import 'package:flutter/material.dart';
import '../models/app_models.dart';

class AppProvider extends ChangeNotifier {
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

  // Registered accounts (in-memory, persists in session)
  final List<UserModel> _accounts = [
    // Default admin
    const UserModel(
      uid: 'admin_001',
      name: 'Admin JNE',
      email: 'admin@jne.co.id',
      phone: '+62 811-0000-0001',
      nik: 'ADM001',
      role: 'admin',
      department: 'Management',
      position: 'Administrator',
      faceRegistered: 'yes',
      deviceName: 'Admin Device',
      faceRegisteredDate: '1 Jan 2026',
    ),
    // Demo user
    const UserModel(
      uid: 'user_001',
      name: 'Nabihan',
      email: 'nabihan.testing@jne',
      phone: '+62 000-0000-0000',
      nik: '0012345',
      role: 'user',
      department: 'Departemen Logistik',
      position: 'Staff Operasional',
      faceRegistered: 'yes',
      deviceName: 'Samsung Galaxy S24 Ultra',
      faceRegisteredDate: '1 Jan 2026',
    ),
  ];

  List<UserModel> get allAccounts => List.unmodifiable(_accounts);
  List<UserModel> get allUsers => _accounts.where((a) => a.role == 'user').toList();

  void login(String email, String password) {
    // Simple match — in production use hashed passwords
    final acc = _accounts.firstWhere(
      (a) => a.email.toLowerCase() == email.toLowerCase(),
      orElse: () => const UserModel(uid: '', name: '', email: '', phone: '', nik: '', role: '', department: '', position: ''),
    );
    if (acc.uid.isNotEmpty) {
      _currentUser = acc;
      notifyListeners();
    } else {
      throw Exception('Email atau password salah');
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void register(UserModel user) {
    _accounts.add(user);
    _currentUser = user;
    notifyListeners();
  }

  void updateCurrentUser(UserModel updated) {
    final idx = _accounts.indexWhere((a) => a.uid == updated.uid);
    if (idx != -1) _accounts[idx] = updated;
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

  // ── Attendance Records ──
  final List<AttendanceRecord> _attendanceRecords = [
    AttendanceRecord(id: 'a1', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 18), checkIn: '08:05', checkOut: null, checkInStatus: 'Tepat Waktu', checkOutStatus: 'Menunggu', location: 'JNE Martapura | 25m'),
    AttendanceRecord(id: 'a2', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 17), checkIn: '08:22', checkOut: '17:10', checkInStatus: 'Terlambat', checkOutStatus: 'Lembur', location: 'JNE Martapura'),
    AttendanceRecord(id: 'a3', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 14), checkIn: null, checkOut: null, checkInStatus: 'Izin', location: 'JNE Martapura'),
    AttendanceRecord(id: 'a4', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 13), checkIn: '08:01', checkOut: '16:00', checkInStatus: 'Tepat Waktu', checkOutStatus: 'Tepat Waktu', location: 'JNE Martapura'),
    AttendanceRecord(id: 'a5', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 12), checkIn: null, checkOut: null, checkInStatus: 'Alpha', location: '-'),
    AttendanceRecord(id: 'a6', userId: 'user_001', userName: 'Nabihan', date: DateTime(2026, 2, 11), checkIn: '08:10', checkOut: '16:30', checkInStatus: 'Tepat Waktu', checkOutStatus: 'Lembur', location: 'JNE Martapura'),
  ];

  List<AttendanceRecord> get myAttendance =>
      _attendanceRecords.where((r) => r.userId == _currentUser?.uid).toList();

  List<AttendanceRecord> get allAttendance => List.unmodifiable(_attendanceRecords);

  void addAttendanceCheckIn(String userId, String userName, String status, String location) {
    final rec = AttendanceRecord(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      date: DateTime.now(),
      checkIn: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      checkInStatus: status,
      location: location,
    );
    _attendanceRecords.insert(0, rec);
    notifyListeners();
  }

  // ── Leave Requests ──
  final List<LeaveRequest> _leaveRequests = [];
  List<LeaveRequest> get myLeaveRequests =>
      _leaveRequests.where((r) => r.userId == _currentUser?.uid).toList();
  List<LeaveRequest> get allLeaveRequests => List.unmodifiable(_leaveRequests);

  void submitLeave(LeaveRequest req) {
    _leaveRequests.add(req);
    notifyListeners();
  }

  void updateLeaveStatus(String id, String status) {
    final idx = _leaveRequests.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _leaveRequests[idx] = _leaveRequests[idx].copyWith(status: status);
      notifyListeners();
    }
  }

  // ── Meetings ──
  final List<MeetingModel> _meetings = [
    MeetingModel(
      id: 'm1',
      title: 'Briefing Tim Operasional',
      dateTime: DateTime(2026, 2, 18, 14, 0),
      room: 'Ruang Rapat A',
      createdBy: 'admin_001',
      description: 'Briefing rutin tim operasional mingguan',
    ),
    MeetingModel(
      id: 'm2',
      title: 'Evaluasi Kinerja Bulanan',
      dateTime: DateTime(2026, 2, 20, 9, 0),
      room: 'Ruang Rapat B',
      createdBy: 'admin_001',
      description: 'Review performa seluruh tim bulan Februari',
    ),
  ];

  List<MeetingModel> get meetings => List.unmodifiable(_meetings);

  void addMeeting(MeetingModel m) {
    _meetings.add(m);
    notifyListeners();
  }

  void updateMeeting(MeetingModel m) {
    final idx = _meetings.indexWhere((x) => x.id == m.id);
    if (idx != -1) {
      _meetings[idx] = m;
      notifyListeners();
    }
  }

  void deleteMeeting(String id) {
    _meetings.removeWhere((m) => m.id == id);
    notifyListeners();
  }

  // ── In-app Notifications ──
  final List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => n['read'] == false).length;

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

  void markAllRead() {
    for (var n in _notifications) {
      n['read'] = true;
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> get myNotifications {
    return _notifications.where((n) =>
      n['targetUserId'] == '' ||
      n['targetUserId'] == _currentUser?.uid).toList();
  }
}