import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:jneattendance_mobile/utils/business_time.dart';

void main() {
  // 05 Sep 2026 01:30 UTC = 09:30 WITA.
  final pagi = DateTime.utc(2026, 9, 5, 1, 30);

  group('BusinessTime', () {
    test('wallClock menerjemahkan instant ke jam WITA', () {
      final w = BusinessTime.wallClock(pagi);
      expect(w.hour, 9);
      expect(w.minute, 30);
      expect(w.day, 5);
    });

    test('dateKey memakai kalender WITA, bukan UTC', () {
      // 16:30 UTC sudah tanggal berikutnya di WITA (00:30).
      final malam = DateTime.utc(2026, 9, 5, 16, 30);
      expect(BusinessTime.dateKey(malam), '2026-09-06');
      expect(BusinessTime.dateKey(pagi), '2026-09-05');
    });

    test('dateKey memberi hasil sama untuk instant yang sama', () {
      // Nilai lokal dan UTC yang menunjuk detik yang sama harus sepakat —
      // inilah yang dulu gagal saat zona waktu HP berbeda dari WITA.
      final asLocal = pagi.toLocal();
      expect(BusinessTime.dateKey(asLocal), BusinessTime.dateKey(pagi));
      expect(BusinessTime.wallClock(asLocal), BusinessTime.wallClock(pagi));
    });

    test('atTime membangun jam shift pada hari kerja WITA yang sama', () {
      final start = BusinessTime.atTime(
        pagi,
        const TimeOfDay(hour: 8, minute: 0),
      );
      expect(start.isUtc, isTrue);
      expect(start.year, 2026);
      expect(start.month, 9);
      expect(start.day, 5);
      expect(start.hour, 8);
    });

    test('selisih wallClock vs atTime = keterlambatan sebenarnya', () {
      // Absen 09:30 WITA dengan jam masuk 08:00 → telat 90 menit, apa pun
      // zona waktu perangkat.
      final start = BusinessTime.atTime(
        pagi,
        const TimeOfDay(hour: 8, minute: 0),
      );
      final late = BusinessTime.wallClock(pagi).difference(start).inMinutes;
      expect(late, 90);
    });

    test('formatHm memakai jam WITA', () {
      expect(BusinessTime.formatHm(pagi), '09:30');
      expect(BusinessTime.label, 'WITA');
    });
  });
}
