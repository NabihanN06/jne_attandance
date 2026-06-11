import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Penjadwal pengingat absensi lokal (tetap jalan walau aplikasi ditutup).
///
/// Mengirim 3 notifikasi sebelum jam **masuk** dan 3 sebelum jam **keluar**,
/// pada 20, 10, dan 3 menit sebelum waktunya. Memakai `zonedSchedule` dengan
/// `matchDateTimeComponents: time` sehingga otomatis berulang setiap hari.
///
/// Plugin `FlutterLocalNotificationsPlugin()` bersifat singleton, jadi instance
/// di sini sama dengan yang sudah di-`initialize()` di `main.dart`.
class AttendanceReminderScheduler {
  AttendanceReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'attendance_reminder';
  static const String _channelName = 'Pengingat Absensi';
  static const String _channelDesc =
      'Pengingat otomatis sebelum jam masuk & keluar';

  // ID tetap 0..2 = pengingat masuk, 3..5 = pengingat keluar.
  static const List<int> _checkInIds = [9101, 9102, 9103];
  static const List<int> _checkOutIds = [9104, 9105, 9106];
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

  /// Buat channel Android lebih awal agar importance benar sejak awal.
  /// Dipanggil sekali dari `main()` setelah plugin di-initialize.
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
  /// dulu agar tidak dobel saat jam berubah. Jika [enabled] false → hanya
  /// membatalkan (mematikan pengingat).
  static Future<void> sync({
    required bool enabled,
    required TimeOfDay checkIn,
    required TimeOfDay checkOut,
  }) async {
    try {
      for (final id in [..._checkInIds, ..._checkOutIds]) {
        await _plugin.cancel(id);
      }
      if (!enabled) return;

      await requestPermissions();

      for (var i = 0; i < _offsetsMinutes.length; i++) {
        final m = _offsetsMinutes[i];
        await _scheduleDaily(
          id: _checkInIds[i],
          at: _subtract(checkIn, m),
          title: 'Pengingat absen masuk',
          body: m == 3
              ? 'Sebentar lagi jam masuk (${_fmt(checkIn)}). Siapkan absen masuk.'
              : '$m menit lagi jam masuk (${_fmt(checkIn)}). Jangan sampai telat!',
        );
        await _scheduleDaily(
          id: _checkOutIds[i],
          at: _subtract(checkOut, m),
          title: 'Pengingat absen keluar',
          body: m == 3
              ? 'Sebentar lagi jam pulang (${_fmt(checkOut)}). Jangan lupa absen keluar.'
              : '$m menit lagi jam pulang (${_fmt(checkOut)}). Siapkan absen keluar.',
        );
      }
    } catch (e) {
      debugPrint('AttendanceReminderScheduler.sync error: $e');
    }
  }

  static Future<void> _scheduleDaily({
    required int id,
    required TimeOfDay at,
    required String title,
    required String body,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOf(at),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // ulang tiap hari
    );
  }

  /// Instance [t] berikutnya pada zona lokal. Kalau hari ini sudah lewat,
  /// jadwalkan untuk besok.
  static tz.TZDateTime _nextInstanceOf(TimeOfDay t) {
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
