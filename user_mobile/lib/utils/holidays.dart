/// Hari libur nasional tanggal-tetap (disamakan dengan admin calendar).
/// Libur yang ikut kalender Hijriah/Imlek/Saka sengaja tidak di-hardcode
/// karena tanggalnya berubah tiap tahun.
class IndonesianHolidays {
  IndonesianHolidays._();

  // key: 'MM-dd' → nama libur
  static const Map<String, String> _fixed = {
    '01-01': 'Tahun Baru Masehi',
    '05-01': 'Hari Buruh Internasional',
    '06-01': 'Hari Lahir Pancasila',
    '08-17': 'Hari Kemerdekaan RI',
    '12-25': 'Hari Raya Natal',
  };

  static String _key(DateTime d) =>
      '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Nama libur untuk tanggal [d], atau null kalau bukan libur nasional tetap.
  static String? nameFor(DateTime d) => _fixed[_key(d)];

  /// True kalau [d] hari libur nasional (tanggal tetap).
  static bool isHoliday(DateTime d) => _fixed.containsKey(_key(d));
}
