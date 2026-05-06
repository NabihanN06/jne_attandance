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
  final String photoUrl;

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
    this.photoUrl = '',
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
    String? photoUrl,
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
      photoUrl: photoUrl ?? this.photoUrl,
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

class OvertimeRecord {
  final String id;
  final String userId;
  final String userName;
  final DateTime date;
  final int durationHours;
  final String reason;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;

  const OvertimeRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.date,
    required this.durationHours,
    required this.reason,
    this.status = 'pending',
    required this.createdAt,
  });
}

// ── Shift / Jam Kerja (from admin 'shifts' collection) ──
class JamKerja {
  final String id;
  final String name;
  final String checkInTime;   // "HH:mm"
  final String checkOutTime;  // "HH:mm"
  final int toleranceMinutes;
  final List<String> workingDays;  // ['monday', ...]
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JamKerja({
    required this.id,
    required this.name,
    required this.checkInTime,
    required this.checkOutTime,
    this.toleranceMinutes = 15,
    this.workingDays = const ['monday','tuesday','wednesday','thursday','friday'],
    this.color = '#3B82F6',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

// ── Department (from admin 'departments' collection) ──
class DepartmentItem {
  final String id;
  final String name;
  final String description;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DepartmentItem({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#E31E24',
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

// ── Calendar Event (from admin 'events' collection) ──
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String? location;
  final String category;  // 'meeting' | 'training' | 'social' | 'deadline' | 'other'
  final List<String> attendees;    // Employee IDs
  final List<String>? departments; // Department IDs
  final String organizerId;
  final String? color;
  final String? imageUrl;
  final int? price;
  final int? ticketsLeft;
  final bool notificationSentDayBefore;
  final bool notificationSent30Min;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    this.location,
    this.category = 'other',
    this.attendees = const [],
    this.departments,
    required this.organizerId,
    this.color,
    this.imageUrl,
    this.price,
    this.ticketsLeft,
    this.notificationSentDayBefore = false,
    this.notificationSent30Min = false,
    required this.createdAt,
    required this.updatedAt,
  });
}

// ── Admin Notification (from admin 'adminNotifications' collection) ──
class AdminNotification {
  final String id;
  final String type;  // 'leave_request' | 'face_enrolled' | 'face_failed' | 'new_employee' | 'attendance_alert' | 'meeting_reminder' | 'system'
  final String title;
  final String message;
  final String? employeeId;
  final String? employeeName;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.employeeId,
    this.employeeName,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });
}

// ── System Settings (full config from admin 'settings/system') ──
class SystemSettings {
  final OfficeSettings office;
  final AttendanceSettings attendance;
  final AdminNotificationSettings notifications;
  final CompanySettings company;

  const SystemSettings({
    required this.office,
    required this.attendance,
    required this.notifications,
    required this.company,
  });
}

class OfficeSettings {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  const OfficeSettings({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });
}

class AttendanceSettings {
  final int maxFaceAttempts;
  final int faceSimilarityThreshold;
  final bool allowOfflineAttendance;
  final bool overtimeCalculation;

  const AttendanceSettings({
    required this.maxFaceAttempts,
    required this.faceSimilarityThreshold,
    required this.allowOfflineAttendance,
    required this.overtimeCalculation,
  });
}

class AdminNotificationSettings {
  final bool notifyOnLeaveRequest;
  final bool notifyOnFaceEnrollment;
  final bool notifyOnFaceFailure;
  final bool notifyOnNewEmployee;
  final bool emailNotifications;
  final String adminEmail;

  const AdminNotificationSettings({
    required this.notifyOnLeaveRequest,
    required this.notifyOnFaceEnrollment,
    required this.notifyOnFaceFailure,
    required this.notifyOnNewEmployee,
    required this.emailNotifications,
    required this.adminEmail,
  });
}

class CompanySettings {
  final String companyName;
  final String? logoUrl;
  final String hrEmail;
  final String hrPhone;
  final String appDownloadUrl;

  const CompanySettings({
    required this.companyName,
    this.logoUrl,
    required this.hrEmail,
    required this.hrPhone,
    required this.appDownloadUrl,
  });
}

