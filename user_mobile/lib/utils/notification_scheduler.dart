import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Penjadwal pengingat absensi lokal (tetap jalan walau aplikasi ditutup).
///
/// Mengirim pengingat 20, 10, dan 3 menit sebelum jam **masuk** dan sebelum jam
/// **keluar**, hanya pada **hari kerja** (Senin–Sabtu; Minggu dilewati). Memakai
/// `zonedSchedule` dengan `matchDateTimeComponents: dayOfWeekAndTime` sehingga
/// otomatis berulang mingguan pada hari & jam yang sama.
///
/// `FlutterLocalNotificationsPlugin()` singleton → instance sama dgn `main.dart`.
class AttendanceReminderScheduler {
  AttendanceReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'attendance_reminder';
  static const String _channelName = 'Pengingat Absensi';
  static const String _channelDesc =
      'Pengingat otomatis sebelum jam masuk & keluar';

  /// Hari kerja (DateTime.monday=1 .. saturday=6). Minggu (7) dilewati.
  /// Ubah di sini kalau Sabtu juga libur (mis. [1,2,3,4,5]).
  static const List<int> _workdays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  static const List<int> _offsetsMinutes = [20, 10, 3]; // menit sebelum

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  // Rentang ID yang dipakai (untuk dibatalkan saat sync). Lihat _idFor().
  // checkIn: 9000+day*10+i, checkOut: 9300+day*10+i  (day 1..6, i 0..2).
  static int _idFor({required bool checkIn, required int day, required int i}) =>
      (checkIn ? 9000 : 9300) + day * 10 + i;

  /// Buat channel Android lebih awal. Dipanggil sekali dari `main()`.
  static Future<void> init() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.max,
      ),
    );
  }

  /// Minta izin notifikasi (Android 13+ POST_NOTIFICATIONS & iOS).
  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Sinkronkan jadwal dengan setting terbaru. Selalu membatalkan jadwal lama
  /// dulu agar tidak dobel. Jika [enabled] false → hanya membatalkan.
  static Future<void> sync({
    required bool enabled,
    required TimeOfDay checkIn,
    required TimeOfDay checkOut,
  }) async {
    try {
      // Bersihkan semua ID yang mungkin pernah dijadwalkan.
      for (final day in _workdays) {
        for (var i = 0; i < _offsetsMinutes.length; i++) {
          await _plugin.cancel(_idFor(checkIn: true, day: day, i: i));
          await _plugin.cancel(_idFor(checkIn: false, day: day, i: i));
        }
      }
      if (!enabled) return;

      await requestPermissions();

      for (final day in _workdays) {
        for (var i = 0; i < _offsetsMinutes.length; i++) {
          final m = _offsetsMinutes[i];
          await _scheduleWeekly(
            id: _idFor(checkIn: true, day: day, i: i),
            day: day,
            at: _subtract(checkIn, m),
            title: 'Pengingat absen masuk',
            body: m == 3
                ? 'Sebentar lagi jam masuk (${_fmt(checkIn)}). Siapkan absen masuk.'
                : '$m menit lagi jam masuk (${_fmt(checkIn)}). Jangan sampai telat!',
          );
          await _scheduleWeekly(
            id: _idFor(checkIn: false, day: day, i: i),
            day: day,
            at: _subtract(checkOut, m),
            title: 'Pengingat absen keluar',
            body: m == 3
                ? 'Sebentar lagi jam pulang (${_fmt(checkOut)}). Jangan lupa absen keluar.'
                : '$m menit lagi jam pulang (${_fmt(checkOut)}). Siapkan absen keluar.',
          );
        }
      }
    } catch (e) {
      debugPrint('AttendanceReminderScheduler.sync error: $e');
    }
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required int day,
    required TimeOfDay at,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayTime(day, at),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.dayOfWeekAndTime, // ulang tiap minggu di hari ini
    );
  }

  /// Kemunculan berikutnya untuk [weekday] (1=Senin..7=Minggu) pada jam [t].
  static tz.TZDateTime _nextInstanceOfDayTime(int weekday, TimeOfDay t) {
    var scheduled = _nextInstanceOfTime(t);
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Kurangi [minutes] dari jam, dibungkus aman dalam 24 jam.
  static TimeOfDay _subtract(TimeOfDay t, int minutes) {
    final total = ((t.hour * 60 + t.minute - minutes) % 1440 + 1440) % 1440;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
