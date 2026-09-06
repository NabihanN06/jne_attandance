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

    group('calendarAgeInDays — penjaga jendela sinkronisasi offline', () {
      // Batas di AppProvider: lebih tua dari 2 hari TIDAK ditulis ke Firestore.
      const batasHari = 2;
      // 10 Sep 2026 03:00 WITA (= 09 Sep 19:00 UTC).
      final sekarang = DateTime.utc(2026, 9, 9, 19, 0);

      int? umur(String tanggal) =>
          BusinessTime.calendarAgeInDays(tanggal, now: sekarang);

      test('hari ini, kemarin, dan 2 hari lalu masih boleh dikirim', () {
        expect(umur('2026-09-10'), 0);
        expect(umur('2026-09-09'), 1);
        expect(umur('2026-09-08'), batasHari);
        for (final t in ['2026-09-10', '2026-09-09', '2026-09-08']) {
          expect(umur(t)! > batasHari, isFalse, reason: t);
        }
      });

      test('3 hari lalu dan bulan lalu DITAHAN — data lama tak tersentuh', () {
        expect(umur('2026-09-07'), 3);
        expect(umur('2026-09-07')! > batasHari, isTrue);
        expect(umur('2026-08-10'), 31);
        expect(umur('2026-08-10')! > batasHari, isTrue);
      });

      test('tanggal tak dikenali → null, biar lewat jalur normal', () {
        expect(umur('bukan-tanggal'), isNull);
        expect(umur(''), isNull);
      });

      test('umur dihitung dari kalender WITA, bukan UTC', () {
        // Pada instant ini UTC masih 09 Sep, tapi WITA sudah 10 Sep.
        // Kalau salah pakai UTC, absen 08 Sep terbaca 1 hari, bukan 2.
        expect(umur('2026-09-08'), 2);
      });
    });

    test('formatHm memakai jam WITA', () {
      expect(BusinessTime.formatHm(pagi), '09:30');
      expect(BusinessTime.label, 'WITA');
    });
  });
}
