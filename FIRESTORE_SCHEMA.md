# Firestore Database Schema - Unified

## Collections Overview

Both admin dashboard and mobile app share the same Firebase project: `admin-absensi-jne-mtp`

### 1. users
**Collection**: `users`
**Purpose**: Employee and admin user profiles

**Fields**:
```typescript
{
  uid: string              // Auth UID (document ID)
  name: string
  email: string
  phone?: string
  employeeId: string       // NIK
  department: string
  position: string
  role: 'admin' | 'superadmin' | 'employee'
  faceRegistered: boolean
  fcmToken?: string        // For push notifications
  deviceId?: string
  deviceModel?: string
  registeredDeviceId?: string
  photoUrl?: string
  joinDate: Timestamp | string
  contractType: 'permanent' | 'contract' | 'intern'
  isActive: boolean
  firstLogin: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 2. shifts (Jam Kerja)
**Collection**: `shifts`
**Purpose**: Work shift/work hour definitions

**Fields**:
```typescript
{
  name: string             // e.g., "Shift Pagi"
  checkInTime: string      // "HH:mm" format
  checkOutTime: string     // "HH:mm" format
  toleranceMinutes: number // Late tolerance (default 15)
  workingDays: string[]    // ['monday', 'tuesday', ...]
  color: string            // Hex color for UI
  isActive: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 3. attendance
**Collection**: `attendance`
**Purpose**: Daily attendance records

**Fields**:
```typescript
{
  userId: string
  employeeName: string
  employeeId: string
  department: string
  jamKerjaId: string       // Reference to shift
  date: string             // "YYYY-MM-DD"

  status: 'present' | 'late' | 'absent' | 'leave' | 'overtime' | 'holiday'

  checkIn?: {
    time: Timestamp
    latitude: number
    longitude: number
    distance: number       // Distance from office (meters)
    faceScore: number      // Face recognition confidence (0-100)
    photoUrl?: string      // Path to stored photo
  }

  checkOut?: {
    time: Timestamp
    latitude: number
    longitude: number
    distance: number
    faceScore: number
    photoUrl?: string
  }

  totalWorkMinutes?: number
  overtimeMinutes?: number
  lateMinutes?: number
  notes?: string

  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 4. leaves
**Collection**: `leaves`
**Purpose**: Leave requests

**Fields**:
```typescript
{
  userId: string
  employeeName: string
  employeeId: string
  department: string
  type: 'sick' | 'annual' | 'personal' | 'emergency' | 'other'
  status: 'pending' | 'approved' | 'rejected'

  startDate: string | Timestamp  // ISO format
  endDate: string | Timestamp
  totalDays: number
  reason: string

  documentUrl?: string     // URL to supporting document
  documentName?: string

  rejectionReason?: string
  reviewedBy?: string      // Admin UID
  reviewedAt?: Timestamp

  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 5. settings
**Collection**: `settings`
**Document**: `system` (single document)
**Purpose**: System configuration

**Structure**:
```typescript
{
  office: {
    name: string
    address: string
    latitude: number
    longitude: number
    radiusMeters: number   // Geofence radius
  }

  attendance: {
    maxFaceAttempts: number
    faceSimilarityThreshold: number  // 0-100
    allowOfflineAttendance: boolean
    overtimeCalculation: boolean
  }

  notifications: {
    notifyOnLeaveRequest: boolean
    notifyOnFaceEnrollment: boolean
    notifyOnFaceFailure: boolean
    notifyOnNewEmployee: boolean
    emailNotifications: boolean
    adminEmail: string
  }

  company: {
    companyName: string
    logoUrl?: string
    hrEmail: string
    hrPhone: string
    appDownloadUrl: string  // Mobile app download link
  }

  updatedAt: Timestamp
}
```

---

### 6. adminNotifications
**Collection**: `adminNotifications`
**Purpose**: Notifications for admin dashboard

**Fields**:
```typescript
{
  type: 'leave_request' | 'face_enrolled' | 'face_failed' |
        'new_employee' | 'attendance_alert' | 'meeting_reminder' | 'system'
  title: string
  message: string
  employeeId?: string
  employeeName?: string
  relatedId?: string        // Reference to related record (leave ID, etc.)
  isRead: boolean
  createdAt: Timestamp
}
```

---

### 7. events
**Collection**: `events`
**Purpose**: Calendar events and meetings

**Fields**:
```typescript
{
  title: string
  description: string
  startDate: Timestamp | string  // ISO
  endDate: Timestamp | string
  location?: string
  category: 'meeting' | 'training' | 'social' | 'deadline' | 'other'
  attendees: string[]      // Employee IDs
  departments?: string[]   // Department IDs (for meetings)
  organizerId: string
  color?: string           // Hex color for calendar
  imageUrl?: string
  price?: number
  ticketsLeft?: number
  notificationSentDayBefore: boolean
  notificationSent30Min: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 8. meetingNotifications (subcollection metadata)
**Collection**: `meetingNotifications` (top-level, managed by Cloud Functions)
**Purpose**: Scheduled meeting notifications

**Fields**:
```typescript
{
  eventId: string
  eventTitle: string
  targetDepartments: string[]
  targetEmployees: string[]
  type: 'day_before' | '30_min_before'
  scheduledAt: string      // ISO timestamp when to send
  sent: boolean
  createdAt: Timestamp
}
```

---

### 9. departments
**Collection**: `departments`
**Purpose**: Department definitions

**Fields**:
```typescript
{
  name: string
  description: string
  color: string           // Hex color for UI
  isActive: boolean
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 10. overtime (NEW - needs admin support)
**Collection**: `overtime`
**Purpose**: Overtime requests from employees

**Fields**:
```typescript
{
  userId: string
  employeeName: string
  employeeId: string
  department: string
  date: string           // "YYYY-MM-DD"
  durationHours: number
  reason: string
  status: 'pending' | 'approved' | 'rejected'
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 11. edit_requests
**Collection**: `edit_requests`
**Purpose**: Attendance correction requests

**Fields**:
```typescript
{
  attendanceId: string
  userId: string
  userName: string
  reason: string
  status: 'pending' | 'approved' | 'rejected'
  requestedChanges: {
    checkIn?: string
    checkOut?: string
    status?: AttendanceStatus
  }
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

---

### 12. sos_alerts
**Collection**: `sos_alerts`
**Purpose**: Emergency SOS alerts from mobile

**Fields**:
```typescript
{
  userId: string
  employeeName: string
  employeeId: string
  department: string
  latitude: number
  longitude: number
  locationName: string
  status: 'active' | 'resolved'
  timestamp: Timestamp
  createdAt: Timestamp
}
```

---

## Indexes Required

Firestore composite indexes should be defined in `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "attendance",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "leaves",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "overtime",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

---

## Data Flow Summary

### Admin Dashboard (Next.js)
- Uses full schema with nested objects for `checkIn`/`checkOut`
- Real-time listeners on: users, shifts, attendance, leaves, events, departments, notifications
- Reads/writes settings document

### Mobile App (Flutter)
- Flattens complex structures for simplicity
- Real-time listeners on: attendance (by userId), leaves (by userId), overtime (by userId)
- Reads settings document for office config
- pending sync: OfflineService for local storage

---

## Migration Notes

- Ensure all timestamps are stored as Firestore `Timestamp` type, not strings
- Admin writes nested objects; mobile reads and flattens
- Mobile stores checkIn/checkOut times as formatted strings "HH:mm" locally
- Both apps must handle null values gracefully for optional fields
