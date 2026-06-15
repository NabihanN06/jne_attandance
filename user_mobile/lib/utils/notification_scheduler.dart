import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'holidays.dart';

/// Penjadwal pengingat absensi lokal (tetap jalan walau aplikasi ditutup).
///
/// Mengirim pengingat 20, 10, dan 3 menit sebelum jam **masuk** dan sebelum jam
/// **keluar**, hanya pada **hari kerja** (Senin–Sabtu; Minggu & libur nasional
/// dilewati). Pakai pendekatan *rolling window*: menjadwalkan beberapa hari
/// kerja ke depan sebagai notifikasi sekali-tembak, lalu dijadwalkan ulang
/// setiap aplikasi dibuka (sync dipanggil saat startup, login, setting kantor
/// berubah, dan toggle pengingat) — sehingga bisa melewati tanggal libur
/// tertentu (tidak bisa dilakukan dengan repeat mingguan).
class AttendanceReminderScheduler {
  AttendanceReminderScheduler._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'attendance_reminder';
  static const String _channelName = 'Pengingat Absensi';
  static const String _channelDesc =
      'Pengingat otomatis sebelum jam masuk & keluar';

  /// Berapa hari KERJA ke depan dijadwalkan (≈2 minggu kalender).
  static const int _workdayCount = 10;
  static const List<int> _offsetsMinutes = [20, 10, 3]; // menit sebelum

  // Slot ID: 9000 + indeksHariKerja*10 + indeksReminder (0..2 masuk, 3..5 keluar).
  static int _id(int dayIdx, int reminderIdx) =>
      9000 + dayIdx * 10 + reminderIdx;

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

  /// Buat channel Android lebih awal. Dipanggil sekali dari `main()`.
  static Future<void> init() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
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
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Sinkronkan jadwal. Selalu membatalkan jadwal lama dulu. Jika [enabled]
  /// false → hanya membatalkan.
  static Future<void> sync({
    required bool enabled,
    required TimeOfDay checkIn,
    required TimeOfDay checkOut,
  }) async {
    try {
      await _cancelAllSlots();
      if (!enabled) return;

      await requestPermissions();

      final now = tz.TZDateTime.now(tz.local);
      var cursor = tz.TZDateTime(tz.local, now.year, now.month, now.day);
      var dayIdx = 0;
      var safety = 0; // cegah loop tak terbatas

      while (dayIdx < _workdayCount && safety < 40) {
        safety++;
        if (_isWorkday(cursor)) {
          for (var i = 0; i < _offsetsMinutes.length; i++) {
            final m = _offsetsMinutes[i];
            final inAt = _at(cursor, _subtract(checkIn, m));
            if (inAt.isAfter(now)) {
              await _scheduleOnce(
                id: _id(dayIdx, i),
                when: inAt,
                title: 'Pengingat absen masuk',
                body: m == 3
                    ? 'Sebentar lagi jam masuk (${_fmt(checkIn)}). Siapkan absen masuk.'
                    : '$m menit lagi jam masuk (${_fmt(checkIn)}). Jangan sampai telat!',
              );
            }
            final outAt = _at(cursor, _subtract(checkOut, m));
            if (outAt.isAfter(now)) {
              await _scheduleOnce(
                id: _id(dayIdx, i + 3),
                when: outAt,
                title: 'Pengingat absen keluar',
                body: m == 3
                    ? 'Sebentar lagi jam pulang (${_fmt(checkOut)}). Jangan lupa absen keluar.'
                    : '$m menit lagi jam pulang (${_fmt(checkOut)}). Siapkan absen keluar.',
              );
            }
          }
          dayIdx++;
        }
        cursor = cursor.add(const Duration(days: 1));
      }
    } catch (e) {
      debugPrint('AttendanceReminderScheduler.sync error: $e');
    }
  }

  /// Hari kerja = bukan Minggu DAN bukan libur nasional.
  static bool _isWorkday(tz.TZDateTime d) =>
      d.weekday != DateTime.sunday && !IndonesianHolidays.isHoliday(d);

  static Future<void> _scheduleOnce({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    // Sekali-tembak (tanpa matchDateTimeComponents) → bisa lewati tanggal libur.
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      when,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Batalkan semua slot yang mungkin dipakai (skema baru 9000–9095 + sisa
  /// skema mingguan lama 9300–9369 agar tidak menumpuk saat upgrade).
  static Future<void> _cancelAllSlots() async {
    for (var d = 0; d < _workdayCount; d++) {
      for (var r = 0; r < 6; r++) {
        await _plugin.cancel(_id(d, r));
      }
    }
    for (var id = 9300; id <= 9369; id++) {
      await _plugin.cancel(id);
    }
  }

  static tz.TZDateTime _at(tz.TZDateTime date, TimeOfDay t) => tz.TZDateTime(
    tz.local,
    date.year,
    date.month,
    date.day,
    t.hour,
    t.minute,
  );

  /// Kurangi [minutes] dari jam, dibungkus aman dalam 24 jam.
  static TimeOfDay _subtract(TimeOfDay t, int minutes) {
    final total = ((t.hour * 60 + t.minute - minutes) % 1440 + 1440) % 1440;
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
