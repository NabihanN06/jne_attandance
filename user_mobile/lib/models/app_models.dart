// ─────────────────────────────────────────────
// models/app_models.dart - 100% SYNCED VERSION
// ─────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  final String role; 
  final String department;
  final String position;
  final bool faceRegistered;
  final String? photoUrl;
  final bool allowRemoteAttendance;
  final String? jamKerjaId;
  final bool isOnline;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
    required this.role,
    required this.department,
    required this.position,
    this.faceRegistered = false,
    this.photoUrl,
    this.allowRemoteAttendance = false,
    this.jamKerjaId,
    this.isOnline = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      employeeId: data['employeeId'] ?? '',
      role: data['role'] ?? 'employee',
      department: data['department'] ?? '',
      position: data['position'] ?? '',
      faceRegistered: data['faceRegistered'] ?? false,
      photoUrl: data['photoUrl'],
      allowRemoteAttendance: data['allowRemoteAttendance'] ?? false,
      jamKerjaId: data['jamKerjaId'],
      isOnline: data['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'employeeId': employeeId,
      'role': role,
      'department': department,
      'position': position,
      'faceRegistered': faceRegistered,
      'photoUrl': photoUrl,
      'allowRemoteAttendance': allowRemoteAttendance,
      'jamKerjaId': jamKerjaId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? employeeId,
    String? role,
    String? department,
    String? position,
    bool? faceRegistered,
    String? photoUrl,
    bool? allowRemoteAttendance,
    String? jamKerjaId,
    bool? isOnline,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      employeeId: employeeId ?? this.employeeId,
      role: role ?? this.role,
      department: department ?? this.department,
      position: position ?? this.position,
      faceRegistered: faceRegistered ?? this.faceRegistered,
      photoUrl: photoUrl ?? this.photoUrl,
      allowRemoteAttendance: allowRemoteAttendance ?? this.allowRemoteAttendance,
      jamKerjaId: jamKerjaId ?? this.jamKerjaId,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String userId;
  final String employeeName;
  final String employeeId;
  final String department;
  final String date; // yyyy-MM-dd
  final String status; // 'present' | 'absent' | 'late' | 'leave'
  final AttendanceCheck? checkIn;
  final AttendanceCheck? checkOut;
  final int? totalWorkMinutes;
  final int? lateMinutes;
  final int? overtimeMinutes;
  final String? notes;

  const AttendanceRecord({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.totalWorkMinutes,
    this.lateMinutes,
    this.overtimeMinutes,
    this.notes,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Support both nested (old) and flat (new Data Connect style) formats
    AttendanceCheck? checkIn;
    if (data['checkIn'] != null) {
      checkIn = AttendanceCheck.fromMap(data['checkIn']);
    } else if (data['checkInTime'] != null) {
      checkIn = AttendanceCheck(
        time: (data['checkInTime'] as Timestamp).toDate(),
        latitude: data['checkInLatitude']?.toDouble(),
        longitude: data['checkInLongitude']?.toDouble(),
        distance: data['checkInDistance']?.toInt(),
        photoUrl: data['checkInPhotoUrl'],
        faceScore: data['checkInFaceScore']?.toDouble(),
      );
    }

    AttendanceCheck? checkOut;
    if (data['checkOut'] != null) {
      checkOut = AttendanceCheck.fromMap(data['checkOut']);
    } else if (data['checkOutTime'] != null) {
      checkOut = AttendanceCheck(
        time: (data['checkOutTime'] as Timestamp).toDate(),
        latitude: data['checkOutLatitude']?.toDouble(),
        longitude: data['checkOutLongitude']?.toDouble(),
        distance: data['checkOutDistance']?.toInt(),
        photoUrl: data['checkOutPhotoUrl'],
        faceScore: data['checkOutFaceScore']?.toDouble(),
      );
    }

    return AttendanceRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      date: data['attendanceDate'] ?? data['date'] ?? '',
      status: data['status'] ?? 'absent',
      checkIn: checkIn,
      checkOut: checkOut,
      totalWorkMinutes: data['totalWorkMinutes'],
      lateMinutes: data['lateMinutes'],
      overtimeMinutes: data['overtimeMinutes'],
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'employeeName': employeeName,
      'employeeId': employeeId,
      'department': department,
      'date': date,
      'status': status,
      'checkIn': checkIn?.toMap(),
      'checkOut': checkOut?.toMap(),
      'totalWorkMinutes': totalWorkMinutes,
      'lateMinutes': lateMinutes,
      'overtimeMinutes': overtimeMinutes,
      'notes': notes,
      // Flat fields for Data Connect compatibility
      'checkInTime': checkIn?.time?.toIso8601String(),
      'checkInLatitude': checkIn?.latitude,
      'checkInLongitude': checkIn?.longitude,
      'checkInPhotoUrl': checkIn?.photoUrl,
      'checkInDistance': checkIn?.distance,
      'checkInFaceScore': checkIn?.faceScore,
      'checkOutTime': checkOut?.time?.toIso8601String(),
      'checkOutLatitude': checkOut?.latitude,
      'checkOutLongitude': checkOut?.longitude,
      'checkOutPhotoUrl': checkOut?.photoUrl,
      'checkOutDistance': checkOut?.distance,
      'checkOutFaceScore': checkOut?.faceScore,
    };
  }

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      employeeName: json['employeeName'] ?? '',
      employeeId: json['employeeId'] ?? '',
      department: json['department'] ?? '',
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      checkIn: json['checkIn'] != null ? AttendanceCheck.fromMap(json['checkIn']) : null,
      checkOut: json['checkOut'] != null ? AttendanceCheck.fromMap(json['checkOut']) : null,
      totalWorkMinutes: json['totalWorkMinutes'],
      lateMinutes: json['lateMinutes'],
      overtimeMinutes: json['overtimeMinutes'],
      notes: json['notes'],
    );
  }
}

class AttendanceCheck {
  final DateTime? time;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final int? distance;
  final double? faceScore;

  const AttendanceCheck({
    this.time,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.distance,
    this.faceScore,
  });

  factory AttendanceCheck.fromMap(Map<String, dynamic> data) {
    DateTime? parsedTime;
    if (data['time'] != null) {
      if (data['time'] is Timestamp) {
        parsedTime = (data['time'] as Timestamp).toDate();
      } else if (data['time'] is String) {
        parsedTime = DateTime.tryParse(data['time']);
      }
    }

    return AttendanceCheck(
      time: parsedTime,
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      photoUrl: data['photoUrl'],
      distance: data['distance']?.toInt(),
      faceScore: data['faceScore']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'time': time?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'photoUrl': photoUrl,
      'distance': distance,
      'faceScore': faceScore,
    };
  }
}


class LeaveRequest {
  final String id;
  final String userId;
  final String employeeName;
  final String employeeId;
  final String department;
  final String type; // 'personal' | 'sick' | 'vacation'
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String? documentUrl;

  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    this.documentUrl,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LeaveRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      type: data['type'] ?? 'personal',
      status: data['status'] ?? 'pending',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      totalDays: data['totalDays'] ?? 1,
      reason: data['reason'] ?? '',
      documentUrl: data['documentUrl'],
    );
  }
}

class JamKerja {
  final String id;
  final String name;
  final String checkInTime;
  final String checkOutTime;
  final int toleranceMinutes;

  const JamKerja({
    required this.id,
    required this.name,
    required this.checkInTime,
    required this.checkOutTime,
    required this.toleranceMinutes,
  });

  factory JamKerja.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return JamKerja(
      id: doc.id,
      name: data['name'] ?? '',
      checkInTime: data['checkInTime'] ?? '08:00',
      checkOutTime: data['checkOutTime'] ?? '17:00',
      toleranceMinutes: data['toleranceMinutes'] ?? 15,
    );
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final String type; 
  final String category; // 'meeting' | 'training' | 'deadline' | 'social'
  final String? location;
  final List<String> attendees;
  final List<String>? departments;
  final String? color;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.category,
    this.location,
    this.attendees = const [],
    this.departments,
    this.color,
  });

  factory CalendarEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      type: data['type'] ?? 'event',
      category: data['category'] ?? 'social',
      location: data['location'],
      attendees: List<String>.from(data['attendees'] ?? []),
      departments: data['departments'] != null ? List<String>.from(data['departments']) : null,
      color: data['color'],
    );
  }
}

class AdminNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });

  factory AdminNotification.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }
<<<<<<< Updated upstream
=======
}

// ── Overtime Request Model ────────────────────────────────────
class OvertimeRequest {
  final String id;
  final String userId;
  final String employeeName;
  final String employeeId;
  final String department;
  final String date;
  final int overtimeMinutes;
  final int overtimeHours;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String reason;
  final String? adminReason;
  final String? reviewedBy;
  final DateTime createdAt;

  const OvertimeRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.date,
    required this.overtimeMinutes,
    required this.overtimeHours,
    required this.status,
    required this.reason,
    this.adminReason,
    this.reviewedBy,
    required this.createdAt,
  });

  factory OvertimeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'];
    final minutes = data['overtimeMinutes'] as int? ?? 0;
    return OvertimeRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      date: data['date'] ?? '',
      overtimeMinutes: minutes,
      overtimeHours: data['overtimeHours'] as int? ?? (minutes / 60).ceil(),
      status: data['status'] ?? 'pending',
      reason: data['reason'] ?? '',
      adminReason: data['adminReason'] ?? data['rejectionReason'],
      reviewedBy: data['reviewedBy'],
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

// ── Leave Balance Model ───────────────────────────────────────
class LeaveBalance {
  final int annualQuota;      // Total jatah cuti setahun (admin-set or default 12)
  final int usedAnnual;       // Sudah terpakai (approved leave type=annual)
  final int usedSick;         // Sakit terpakai
  final int usedPermission;   // Izin mendadak terpakai
  final int pendingDays;      // Sedang diajukan (pending)
  final String? updatedBy;    // Admin yang terakhir set
  final DateTime? updatedAt;  // Kapan terakhir di-update admin

  const LeaveBalance({
    this.annualQuota = 12,
    this.usedAnnual = 0,
    this.usedSick = 0,
    this.usedPermission = 0,
    this.pendingDays = 0,
    this.updatedBy,
    this.updatedAt,
  });

  int get remainingAnnual => (annualQuota - usedAnnual).clamp(0, annualQuota);
  int get totalUsed => usedAnnual + usedSick + usedPermission;
  double get usagePercent => annualQuota > 0 ? (usedAnnual / annualQuota).clamp(0.0, 1.0) : 0.0;

  factory LeaveBalance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['updatedAt'];
    return LeaveBalance(
      annualQuota: data['annualQuota'] as int? ?? 12,
      usedAnnual: data['usedAnnual'] as int? ?? 0,
      usedSick: data['usedSick'] as int? ?? 0,
      usedPermission: data['usedPermission'] as int? ?? 0,
      pendingDays: data['pendingDays'] as int? ?? 0,
      updatedBy: data['updatedBy'],
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

// ── Dispute / Komplain Model ──────────────────────────────────
class DisputeRequest {
  final String id;
  final String userId;
  final String employeeName;
  final String employeeId;
  final String department;
  // 'attendance_error' | 'system_issue' | 'overtime_issue' | 'leave_issue' | 'other'
  final String category;
  final String title;
  final String description;
  final String? attachmentUrl;
  final String? relatedAttendanceId;
  // 'pending' | 'in_review' | 'resolved' | 'rejected'
  final String status;
  final String? adminResponse;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DisputeRequest({
    required this.id,
    required this.userId,
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.category,
    required this.title,
    required this.description,
    this.attachmentUrl,
    this.relatedAttendanceId,
    required this.status,
    this.adminResponse,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DisputeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final ts = data['createdAt'];
    final us = data['updatedAt'];
    final rs = data['resolvedAt'];
    return DisputeRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      category: data['category'] ?? 'other',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      relatedAttendanceId: data['relatedAttendanceId'],
      status: data['status'] ?? 'pending',
      adminResponse: data['adminResponse'],
      resolvedBy: data['resolvedBy'],
      resolvedAt: rs is Timestamp ? rs.toDate() : null,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      updatedAt: us is Timestamp ? us.toDate() : DateTime.now(),
    );
  }
>>>>>>> Stashed changes
}