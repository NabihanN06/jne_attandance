import 'package:flutter_test/flutter_test.dart';
import 'package:jneattendance_mobile/utils/app_version.dart';

void main() {
  group('compareVersionNames', () {
    test('membandingkan per segmen numerik, bukan leksikografis', () {
      expect(compareVersionNames('1.0.9', '1.0.11'), lessThan(0));
      expect(compareVersionNames('1.0.11', '1.0.9'), greaterThan(0));
      expect(compareVersionNames('1.0.11', '1.0.11'), 0);
    });

    test('segmen yang hilang dianggap nol', () {
      expect(compareVersionNames('1.1', '1.1.0'), 0);
      expect(compareVersionNames('2', '1.9.9'), greaterThan(0));
    });

    test('segmen non-numerik tidak melempar', () {
      expect(compareVersionNames('1.0.x', '1.0.0'), 0);
      expect(compareVersionNames('', ''), 0);
    });
  });

  group('isReleaseNewer', () {
    test(
      'regresi: buildNumber manifest yang melenceng tidak memicu update palsu',
      () {
        // Kondisi produksi nyata: app-latest.json menyimpan buildNumber 2035
        // sementara versionCode APK terpasang 35, dengan versionName yang sama.
        // Perbandingan lama (2035 > 35) membuat banner "Update tersedia"
        // menempel selamanya di HP karyawan.
        expect(
          isReleaseNewer(
            latestVersionName: '1.0.11',
            latestBuild: 2035,
            currentVersionName: '1.0.11',
            currentBuild: 35,
          ),
          isFalse,
        );
      },
    );

    test('rilis yang benar-benar baru tetap terdeteksi', () {
      expect(
        isReleaseNewer(
          latestVersionName: '1.0.12',
          latestBuild: 36,
          currentVersionName: '1.0.11',
          currentBuild: 35,
        ),
        isTrue,
      );
    });

    test(
      'versi terpasang lebih baru dari manifest → tidak menawarkan update',
      () {
        expect(
          isReleaseNewer(
            latestVersionName: '1.0.10',
            latestBuild: 34,
            currentVersionName: '1.0.11',
            currentBuild: 35,
          ),
          isFalse,
        );
      },
    );

    test('manifest tanpa versionName jatuh ke perbandingan buildNumber', () {
      expect(
        isReleaseNewer(
          latestVersionName: '',
          latestBuild: 36,
          currentVersionName: '1.0.11',
          currentBuild: 35,
        ),
        isTrue,
      );
      expect(
        isReleaseNewer(
          latestVersionName: '',
          latestBuild: 35,
          currentVersionName: '1.0.11',
          currentBuild: 35,
        ),
        isFalse,
      );
    });
  });
}
