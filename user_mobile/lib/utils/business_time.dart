import 'package:flutter/material.dart' show TimeOfDay;

/// Jam operasional kantor JNE Martapura: **WITA (Asia/Makassar, UTC+8)**.
///
/// Absensi TIDAK BOLEH bergantung pada zona waktu perangkat. Panduan karyawan
/// (`PANDUAN_KURIR.md`) menjanjikan "Sistem kami menggunakan Waktu Server
/// (WITA). Mengubah jam di HP tidak akan berpengaruh", dan pengingat absensi
/// (`AttendanceReminderScheduler`) sudah dikunci ke `Asia/Makassar`. Sebelum
/// kelas ini ada, perhitungan telat & tanggal absensi memakai `DateTime.now()`
/// / `.toLocal()` — artinya HP yang di-set WIB (UTC+7) membaca absen 08:30
/// WITA sebagai 07:30 dan tersimpan "tepat waktu", padahal panel admin (yang
/// merender WITA) menampilkannya sebagai terlambat.
///
/// Semua nilai yang dikembalikan bertanda UTC dan dipakai sebagai wadah *wall
/// clock*: field `year`/`month`/`day`/`hour`/`minute`-nya SUDAH dalam WITA.
/// Selisih antar dua nilai dari kelas ini (atau `DateTime.utc(...)`) karena
/// itu bebas dari zona waktu perangkat.
class BusinessTime {
  const BusinessTime._();

  /// Selisih WITA terhadap UTC.
  static const Duration utcOffset = Duration(hours: 8);

  /// Label zona waktu untuk ditampilkan ke karyawan.
  static const String label = 'WITA';

  /// Jam dinding WITA untuk [instant] (boleh lokal maupun UTC).
  static DateTime wallClock(DateTime instant) => instant.toUtc().add(utcOffset);

  /// Jam dinding WITA sekarang.
  static DateTime now() => wallClock(DateTime.now());

  /// Kunci hari kerja `yyyy-MM-dd` menurut kalender WITA. Dipakai sebagai ID
  /// dokumen absensi (`{uid}_{tanggal}`), jadi harus stabil lintas perangkat.
  static String dateKey(DateTime instant) {
    final w = wallClock(instant);
    final month = w.month.toString().padLeft(2, '0');
    final day = w.day.toString().padLeft(2, '0');
    return '${w.year}-$month-$day';
  }

  /// Kunci hari kerja hari ini.
  static String todayKey() => dateKey(DateTime.now());

  /// Jam [time] pada hari kerja yang memuat [instant], dalam WITA.
  /// Dipakai untuk membangun jam masuk/pulang shift agar bisa dibandingkan
  /// langsung dengan [wallClock].
  static DateTime atTime(DateTime instant, TimeOfDay time) {
    final w = wallClock(instant);
    return DateTime.utc(w.year, w.month, w.day, time.hour, time.minute);
  }

  /// `HH:mm` WITA untuk [instant].
  static String formatHm(DateTime instant) {
    final w = wallClock(instant);
    final hour = w.hour.toString().padLeft(2, '0');
    final minute = w.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
