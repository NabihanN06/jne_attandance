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
  final bool passwordChanged;
  final String? facePhotoUrl;

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
    this.passwordChanged = false,
    this.facePhotoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id, // Always use Firestore doc ID = Firebase Auth UID
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
      passwordChanged: data['passwordChanged'] ?? false,
      facePhotoUrl: data['facePhotoUrl'],
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
      'facePhotoUrl': facePhotoUrl,
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
    bool? passwordChanged,
    String? facePhotoUrl,
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
      allowRemoteAttendance:
          allowRemoteAttendance ?? this.allowRemoteAttendance,
      jamKerjaId: jamKerjaId ?? this.jamKerjaId,
      isOnline: isOnline ?? this.isOnline,
      passwordChanged: passwordChanged ?? this.passwordChanged,
      facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};

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
      checkIn: json['checkIn'] != null
          ? AttendanceCheck.fromMap(json['checkIn'])
          : null,
      checkOut: json['checkOut'] != null
          ? AttendanceCheck.fromMap(json['checkOut'])
          : null,
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
  final String type; // 'annual' | 'sick' | 'permission' | 'personal' | 'urgent'
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final String reason;
  final String? documentUrl;
  final String? rejectionReason;
  final String? adminReason;
  final String? reviewedBy;

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
    this.rejectionReason,
    this.adminReason,
    this.reviewedBy,
  });

  factory LeaveRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final sD = data['startDate'];
    final eD = data['endDate'];
    return LeaveRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      employeeName: data['employeeName'] ?? '',
      employeeId: data['employeeId'] ?? '',
      department: data['department'] ?? '',
      type: data['type'] ?? 'personal',
      status: data['status'] ?? 'pending',
      startDate: sD is Timestamp
          ? sD.toDate()
          : (sD is String
                ? DateTime.tryParse(sD) ?? DateTime.now()
                : DateTime.now()),
      endDate: eD is Timestamp
          ? eD.toDate()
          : (eD is String
                ? DateTime.tryParse(eD) ?? DateTime.now()
                : DateTime.now()),
      totalDays: data['totalDays'] ?? 1,
      reason: data['reason'] ?? '',
      documentUrl: data['documentUrl'],
      rejectionReason: data['rejectionReason'] ?? data['adminReason'],
      adminReason: data['adminReason'] ?? data['rejectionReason'],
      reviewedBy: data['reviewedBy'],
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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final sD = data['startDate'];
    final eD = data['endDate'];
    return CalendarEvent(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startDate: sD is Timestamp
          ? sD.toDate()
          : (sD is String
                ? DateTime.tryParse(sD) ?? DateTime.now()
                : DateTime.now()),
      endDate: eD is Timestamp
          ? eD.toDate()
          : (eD is String
                ? DateTime.tryParse(eD) ?? DateTime.now()
                : DateTime.now()),
      type: data['type'] ?? 'event',
      category: data['category'] ?? 'social',
      location: data['location'],
      attendees: List<String>.from(data['attendees'] ?? []),
      departments: data['departments'] != null
          ? List<String>.from(data['departments'])
          : null,
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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();
    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'info',
      createdAt: createdAt,
      isRead: data['isRead'] ?? false,
    );
  }
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
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
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
  final int annualQuota; // Total jatah cuti setahun (admin-set or default 12)
  final int usedAnnual; // Sudah terpakai (approved leave type=annual)
  final int usedSick; // Sakit terpakai
  final int usedPermission; // Izin mendadak terpakai
  final int pendingDays; // Sedang diajukan (pending)
  final String? updatedBy; // Admin yang terakhir set
  final DateTime? updatedAt; // Kapan terakhir di-update admin

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
  double get usagePercent =>
      annualQuota > 0 ? (usedAnnual / annualQuota).clamp(0.0, 1.0) : 0.0;

  factory LeaveBalance.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
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
  // 'pending' | 'in_review' | 'resolved' | 'rejected' | 'reopened' | 'closed'
  final String status;
  final String? adminResponse;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Two-way resolution loop
  final bool userConfirmedResolution;
  final String? userResolutionStatus; // 'satisfied' | 'reopened'
  final int? userRating; // 1..5
  final String? userFeedback;
  final DateTime? confirmedAt;
  final int messageCount;

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
    this.userConfirmedResolution = false,
    this.userResolutionStatus,
    this.userRating,
    this.userFeedback,
    this.confirmedAt,
    this.messageCount = 0,
  });

  bool get needsUserConfirmation =>
      status == 'resolved' && !userConfirmedResolution;

  bool get isClosed =>
      status == 'closed' ||
      status == 'rejected' ||
      (status == 'resolved' &&
          userConfirmedResolution &&
          userResolutionStatus == 'satisfied');

  factory DisputeRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final ts = data['createdAt'];
    final us = data['updatedAt'];
    final rs = data['resolvedAt'];
    final cf = data['confirmedAt'];
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
      adminResponse: data['adminResponse'] ?? data['adminReason'],
      resolvedBy: data['resolvedBy'] ?? data['reviewedBy'],
      resolvedAt: rs is Timestamp ? rs.toDate() : null,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      updatedAt: us is Timestamp ? us.toDate() : DateTime.now(),
      userConfirmedResolution: data['userConfirmedResolution'] == true,
      userResolutionStatus: data['userResolutionStatus'],
      userRating: (data['userRating'] as num?)?.toInt(),
      userFeedback: data['userFeedback'],
      confirmedAt: cf is Timestamp ? cf.toDate() : null,
      messageCount: (data['messageCount'] as num?)?.toInt() ?? 0,
    );
  }
}

// ── Smart Tip (derived, tidak di Firestore) ───────────────────
class SmartTip {
  final String id;
  final String title;
  final String message;
  // 'urgent' | 'warning' | 'info' | 'success'
  final String severity;
  // route-ish hint: 'attendance' | 'leave_balance' | 'dispute' | 'statistic'
  final String action;
  // nama icon Material: 'access_time' | 'logout' | 'beach_access' | etc
  final String icon;

  const SmartTip({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.action,
    required this.icon,
  });
}

// ── Dispute Thread Message ────────────────────────────────────
class DisputeMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole; // 'user' | 'admin'
  final String text;
  final String? attachmentUrl;
  final DateTime createdAt;
  final bool isSystem;

  const DisputeMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    this.attachmentUrl,
    required this.createdAt,
    this.isSystem = false,
  });

  factory DisputeMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    final ts = data['createdAt'];
    return DisputeMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderRole: data['senderRole'] ?? 'user',
      text: data['text'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isSystem: data['isSystem'] == true,
    );
  }
}
