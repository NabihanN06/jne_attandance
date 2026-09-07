/// Perbandingan versi rilis aplikasi (APK sideload).
///
/// Dipisah dari `AppProvider` supaya logikanya murni (tanpa Firebase/IO) dan
/// bisa diuji langsung — lihat `test/app_version_test.dart`.
library;

/// Bandingkan dua nomor versi bergaya `"1.0.11"`.
///
/// Segmen dipisah titik dan dibaca sebagai angka; segmen yang hilang dianggap
/// 0 (`"1.1"` == `"1.1.0"`) dan segmen non-numerik dianggap 0.
///
/// Return `< 0` bila [a] lebih lama dari [b], `0` bila sama, `> 0` bila [a]
/// lebih baru.
int compareVersionNames(String a, String b) {
  final partsA = a.trim().split('.');
  final partsB = b.trim().split('.');
  final length = partsA.length > partsB.length ? partsA.length : partsB.length;
  for (var i = 0; i < length; i++) {
    final numA = i < partsA.length ? (int.tryParse(partsA[i].trim()) ?? 0) : 0;
    final numB = i < partsB.length ? (int.tryParse(partsB[i].trim()) ?? 0) : 0;
    if (numA != numB) return numA < numB ? -1 : 1;
  }
  return 0;
}

/// Apakah rilis yang diumumkan server benar-benar lebih baru dari yang
/// terpasang di HP karyawan?
///
/// `versionName` adalah SUMBER KEBENARAN. Itu identitas rilis yang dilihat
/// karyawan di banner ("v1.0.12") dan satu-satunya field yang tidak pernah
/// dipakai ulang. `buildNumber` hanya dipakai sebagai cadangan ketika salah
/// satu `versionName` kosong (metadata lama), karena angka itu gampang
/// melenceng dari `versionCode` APK: `--split-per-abi` diam-diam menambah
/// offset ABI (arm64 = 2000+N), jadi rilis 1.0.11+35 terpasang sebagai
/// versionCode 2035 di HP karyawan. Manifest yang menyebut 35 untuk APK yang
/// sama membuat banner "Update tersedia" menempel SELAMANYA di HP yang
/// sebenarnya sudah paling baru. Sejak 1.0.12 offset itu ditulis eksplisit di
/// `pubspec.yaml` dan rilis dibangun tanpa `--split-per-abi`.
///
/// - [latestVersionName]/[latestBuild]: dari `app-latest.json` di Storage.
/// - [currentVersionName]/[currentBuild]: dari `PackageInfo.fromPlatform()`.
bool isReleaseNewer({
  required String latestVersionName,
  required int latestBuild,
  required String currentVersionName,
  required int currentBuild,
}) {
  final latestName = latestVersionName.trim();
  final currentName = currentVersionName.trim();
  if (latestName.isEmpty || currentName.isEmpty) {
    // Metadata tidak menyebut versionName → tidak ada pembanding yang bisa
    // dipercaya selain nomor build.
    return latestBuild > currentBuild;
  }
  return compareVersionNames(latestName, currentName) > 0;
}
