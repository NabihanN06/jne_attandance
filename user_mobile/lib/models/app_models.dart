// ─────────────────────────────────────────────
// models/app_models.dart
// ─────────────────────────────────────────────

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String nik;
  final String role; // 'admin' | 'user'
  final String department;
  final String position;
  final String faceRegistered;
  final String deviceName;
  final String faceRegisteredDate;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.nik,
    required this.role,
    required this.department,
    required this.position,
    this.faceRegistered = '',
    this.deviceName = '',
    this.faceRegisteredDate = '',
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? nik,
    String? role,
    String? department,
    String? position,
    String? faceRegistered,
    String? deviceName,
    String? faceRegisteredDate,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      nik: nik ?? this.nik,
      role: role ?? this.role,
      department: department ?? this.department,
      position: position ?? this.position,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      deviceName: deviceName ?? this.deviceName,
      faceRegisteredDate: faceRegisteredDate ?? this.faceRegisteredDate,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final String? checkIn;
  final String? checkOut;
  final String checkInStatus; // 'Tepat Waktu' | 'Terlambat' | 'Izin' | 'Alpha' | 'Lembur'
  final String? checkOutStatus;
  final String location;
  final double latitude;
  final double longitude;
  final String shift;
  final String? photoUrl;
  final bool isOffline;
  final DateTime? createdAt;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    this.checkIn,
    this.checkOut,
    this.checkInStatus = 'Tepat Waktu',
    this.checkOutStatus,
    this.location = 'JNE Martapura',
    this.latitude = 0,
    this.longitude = 0,
    this.shift = 'Shift Pagi (08.00 - 16.00)',
    this.photoUrl,
    this.isOffline = false,
    this.createdAt,
  });
}

class NotificationLog {
  final String id;
  final String title;
  final String body;
  final DateTime time;
  final bool isRead;
  final String type; // 'reminder', 'status', 'meeting'

  const NotificationLog({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    this.isRead = false,
    this.type = 'reminder',
  });
}

class EditRequest {
  final String id;
  final String attendanceId;
  final String userId;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime requestedAt;
  final Map<String, dynamic> requestedChanges;

  const EditRequest({
    required this.id,
    required this.attendanceId,
    required this.userId,
    required this.reason,
    this.status = 'pending',
    required this.requestedAt,
    required this.requestedChanges,
  });
}

class LeaveRequest {
  final String id;
  final String userId;
  final String userName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String? documentPath;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime submittedAt;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.documentPath,
    this.status = 'pending',
    required this.submittedAt,
  });

  LeaveRequest copyWith({String? status}) {
    return LeaveRequest(
      id: id,
      userId: userId,
      userName: userName,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      documentPath: documentPath,
      status: status ?? this.status,
      submittedAt: submittedAt,
    );
  }
}

class MeetingModel {
  final String id;
  final String title;
  final DateTime dateTime;
  final String room;
  final String createdBy;
  final String description;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.room,
    required this.createdBy,
    this.description = '',
  });
}

class NotificationSettings {
  final bool reminderAbsenMasuk;
  final bool reminderAbsenPulang;
  final bool notifikasiStatusIzin;
  final bool notifikasiMeeting;

  const NotificationSettings({
    this.reminderAbsenMasuk = true,
    this.reminderAbsenPulang = true,
    this.notifikasiStatusIzin = true,
    this.notifikasiMeeting = false,
  });

  NotificationSettings copyWith({
    bool? reminderAbsenMasuk,
    bool? reminderAbsenPulang,
    bool? notifikasiStatusIzin,
    bool? notifikasiMeeting,
  }) {
    return NotificationSettings(
      reminderAbsenMasuk: reminderAbsenMasuk ?? this.reminderAbsenMasuk,
      reminderAbsenPulang: reminderAbsenPulang ?? this.reminderAbsenPulang,
      notifikasiStatusIzin: notifikasiStatusIzin ?? this.notifikasiStatusIzin,
      notifikasiMeeting: notifikasiMeeting ?? this.notifikasiMeeting,
    );
  }
}