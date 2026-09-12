import 'package:flutter_test/flutter_test.dart';
import 'package:home_business_mobile/core/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppUpdateService.compareVersions', () {
    test('identical versions return 0', () {
      expect(AppUpdateService.compareVersions('1.0.0', '1.0.0'), equals(0));
      expect(AppUpdateService.compareVersions('1.2.3+10', '1.2.3+10'), equals(0));
    });

    test('older minor version returns negative', () {
      expect(AppUpdateService.compareVersions('1.0.0', '1.1.0'), lessThan(0));
      expect(AppUpdateService.compareVersions('1.0.5', '1.1.0'), lessThan(0));
    });

    test('newer minor version returns positive', () {
      expect(AppUpdateService.compareVersions('1.2.0', '1.1.0'), greaterThan(0));
      expect(AppUpdateService.compareVersions('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('patch version differences are detected', () {
      expect(AppUpdateService.compareVersions('1.0.0', '1.0.1'), lessThan(0));
      expect(AppUpdateService.compareVersions('1.0.2', '1.0.1'), greaterThan(0));
    });

    test('build numbers differences when semver is identical', () {
      expect(AppUpdateService.compareVersions('1.0.0+17', '1.0.0+18'), lessThan(0));
      expect(AppUpdateService.compareVersions('1.0.0+20', '1.0.0+17'), greaterThan(0));
    });

    test('handles empty or whitespace inputs gracefully', () {
      expect(AppUpdateService.compareVersions('', '1.0.0'), equals(0));
      expect(AppUpdateService.compareVersions('   ', '1.0.0'), equals(0));
    });
  });

  group('AppUpdateService.checkUpdateStatus', () {
    test('returns maintenance when maintenanceMode is true', () async {
      final config = {'maintenanceMode': true};
      final status = await AppUpdateService.checkUpdateStatus(config);
      expect(status, equals(AppUpdateStatus.maintenance));
    });

    test('returns forceUpdate when minAppVersion is higher than installed', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Home Business',
        packageName: 'com.homebusiness.app',
        version: '1.0.0',
        buildNumber: '17',
        buildSignature: '',
      );

      final config = {
        'minAppVersion': '2.0.0',
        'latestAppVersion': '2.1.0',
        'maintenanceMode': false,
      };
      final status = await AppUpdateService.checkUpdateStatus(config);
      expect(status, equals(AppUpdateStatus.forceUpdate));
    });

    test('returns softUpdate when latestAppVersion is higher but minAppVersion is satisfied', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Home Business',
        packageName: 'com.homebusiness.app',
        version: '1.0.0',
        buildNumber: '17',
        buildSignature: '',
      );

      final config = {
        'minAppVersion': '1.0.0',
        'latestAppVersion': '1.1.0',
        'maintenanceMode': false,
      };
      final status = await AppUpdateService.checkUpdateStatus(config);
      expect(status, equals(AppUpdateStatus.softUpdate));
    });

    test('returns upToDate when app version matches latest version', () async {
      PackageInfo.setMockInitialValues(
        appName: 'Home Business',
        packageName: 'com.homebusiness.app',
        version: '2.1.0',
        buildNumber: '25',
        buildSignature: '',
      );

      final config = {
        'minAppVersion': '2.0.0',
        'latestAppVersion': '2.1.0',
        'maintenanceMode': false,
      };
      final status = await AppUpdateService.checkUpdateStatus(config);
      expect(status, equals(AppUpdateStatus.upToDate));
    });
  });
}
