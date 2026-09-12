import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Enum representing the evaluated update status of the application.
enum AppUpdateStatus {
  upToDate,
  softUpdate,
  forceUpdate,
  maintenance,
}

/// Service responsible for managing in-app updates, version enforcement, and maintenance mode.
class AppUpdateService {
  static const String _keyLastSoftUpdatePrompt = 'last_soft_update_dismiss_timestamp';
  static bool _isDialogOpen = false;

  static bool get isDialogOpen => _isDialogOpen;

  /// Resets the dialog open flag (useful if a dialog is dismissed or cleared)
  static void resetDialogState() {
    _isDialogOpen = false;
  }

  /// Compares two version strings (e.g. "1.0.0" vs "1.1.0" or "1.0.0+17" vs "1.0.0+18").
  /// Returns:
  ///   negative if v1 < v2 (v1 is older than v2)
  ///   0 if v1 == v2
  ///   positive if v1 > v2 (v1 is newer than v2)
  static int compareVersions(String v1, String v2) {
    if (v1.trim().isEmpty || v2.trim().isEmpty) return 0;

    final clean1 = v1.split('+').first.trim();
    final clean2 = v2.split('+').first.trim();

    final parts1 = clean1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = clean2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }

    // Compare build numbers if base semver is identical
    if (v1.contains('+') && v2.contains('+')) {
      final b1 = int.tryParse(v1.split('+').last.trim()) ?? 0;
      final b2 = int.tryParse(v2.split('+').last.trim()) ?? 0;
      if (b1 < b2) return -1;
      if (b1 > b2) return 1;
    }

    return 0;
  }

  /// Launch store or download URL in external browser/store app
  static Future<void> launchUpdateUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[AppUpdateService] Failed to launch update URL: $e');
    }
  }

  /// Safely retrieves installed version and build number.
  /// Falls back gracefully to pubspec default version (1.0.0+17) if platform info is unavailable.
  static Future<({String version, String buildNumber})> getInstalledVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final v = packageInfo.version.trim();
      final b = packageInfo.buildNumber.trim();
      if (v.isNotEmpty && v != 'unknown') {
        return (version: v, buildNumber: b.isNotEmpty ? b : '17');
      }
    } catch (e) {
      debugPrint('[AppUpdateService] PackageInfo from platform unavailable: $e');
    }
    return (version: '1.0.0', buildNumber: '17');
  }

  /// Evaluates remote configuration against the installed app version and returns the status.
  static Future<AppUpdateStatus> checkUpdateStatus(Map<String, dynamic> config) async {
    if (config['maintenanceMode'] == true) {
      return AppUpdateStatus.maintenance;
    }

    final installed = await getInstalledVersion();
    final localVersion = installed.version;
    final localBuild = installed.buildNumber;
    final localFull = '$localVersion+$localBuild';

    final minAppVersion = config['minAppVersion']?.toString().trim();
    final latestAppVersion = config['latestAppVersion']?.toString().trim();

    debugPrint('[AppUpdateService] Version Check: Installed=$localFull (v=$localVersion), MinReq=$minAppVersion, Latest=$latestAppVersion');

    // 1. Force Update check
    if (minAppVersion != null && minAppVersion.isNotEmpty) {
      final isBelowMin = compareVersions(localVersion, minAppVersion) < 0 ||
          (minAppVersion.contains('+') && compareVersions(localFull, minAppVersion) < 0);

      if (isBelowMin) {
        debugPrint('[AppUpdateService] ⚠️ Force Update Triggered! ($localFull < $minAppVersion)');
        return AppUpdateStatus.forceUpdate;
      }
    }

    // 2. Soft Update check
    if (latestAppVersion != null && latestAppVersion.isNotEmpty) {
      final isBelowLatest = compareVersions(localVersion, latestAppVersion) < 0 ||
          (latestAppVersion.contains('+') && compareVersions(localFull, latestAppVersion) < 0);

      if (isBelowLatest) {
        debugPrint('[AppUpdateService] ℹ️ Soft Update Available! ($localFull < $latestAppVersion)');
        return AppUpdateStatus.softUpdate;
      }
    }

    return AppUpdateStatus.upToDate;
  }

  /// Evaluates remote configuration and displays the appropriate dialog if needed.
  static Future<void> checkForUpdates(
    Map<String, dynamic> config, {
    bool isFromSplash = false,
  }) async {
    if (_isDialogOpen) return;

    final status = await checkUpdateStatus(config);

    if (status == AppUpdateStatus.maintenance) {
      showMaintenanceDialog(config);
      return;
    }

    if (status == AppUpdateStatus.forceUpdate) {
      final installed = await getInstalledVersion();
      final minAppVersion = config['minAppVersion']?.toString().trim() ?? '2.0.0';
      final appStoreUrl = config['appStoreUrl']?.toString().trim() ??
          'https://play.google.com/store/apps/details?id=com.homebusiness.app';

      showForceUpdateDialog(
        title: config['forceUpdateTitleAr']?.toString() ?? 'تحديث هام وإلزامي',
        message: config['forceUpdateMessageAr']?.toString() ??
            'يتطلب التطبيق تحديثاً ضرورياً لمتابعة استخدامه بشكل آمن ومستقر.',
        storeUrl: appStoreUrl,
        installedVersion: installed.version,
        requiredVersion: minAppVersion,
      );
      return;
    }

    if (status == AppUpdateStatus.softUpdate && !isFromSplash) {
      final installed = await getInstalledVersion();
      final latestAppVersion = config['latestAppVersion']?.toString().trim() ?? '2.0.0';
      final appStoreUrl = config['appStoreUrl']?.toString().trim() ??
          'https://play.google.com/store/apps/details?id=com.homebusiness.app';

      final prefs = await SharedPreferences.getInstance();
      final lastDismiss = prefs.getInt(_keyLastSoftUpdatePrompt) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      const cooldownMs = 24 * 60 * 60 * 1000; // 24 hours

      if (now - lastDismiss > cooldownMs) {
        showSoftUpdateDialog(
          title: config['appUpdateTitleAr']?.toString() ?? 'تحديث جديد متوفر',
          message: config['appUpdateMessageAr']?.toString() ??
              'يتوفر إصدار جديد من تطبيق السوق المنزلي مع تحسينات ومميزات جديدة. يرجى التحديث لتجربة أفضل.',
          storeUrl: appStoreUrl,
          installedVersion: installed.version,
          latestVersion: latestAppVersion,
          onDismiss: () async {
            await prefs.setInt(_keyLastSoftUpdatePrompt, DateTime.now().millisecondsSinceEpoch);
          },
        );
      }
    }
  }

  /// Non-dismissable Full Screen / Modal dialog when app is under maintenance.
  static void showMaintenanceDialog(Map<String, dynamic> config) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final supportPhone = config['supportPhone'] ?? '+967772546343';

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.construction_rounded,
                    color: Colors.amber.shade800,
                    size: 40,
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                const Text(
                  'النظام في وضع الصيانة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space12),
                Text(
                  'نعمل حالياً على إجراء بعض التحديثات والتحسينات الدورية لنقدم لكم تجربة تسوق أفضل وأكثر سرعة. سنعود للعمل قريباً جداً.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url = 'https://wa.me/${supportPhone.toString().replaceAll('+', '')}';
                      launchUpdateUrl(url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.support_agent_rounded, color: Colors.white),
                    label: const Text(
                      'التواصل مع الدعم الفني',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  /// Non-dismissable Force Update Dialog (Blocks usage until updated).
  static void showForceUpdateDialog({
    required String title,
    required String message,
    required String storeUrl,
    required String installedVersion,
    required String requiredVersion,
  }) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_security_update_rounded,
                    color: AppTheme.error,
                    size: 42,
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    'الإصدار الحالي: $installedVersion  ←  المطلوب: $requiredVersion',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => launchUpdateUrl(storeUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'تحديث التطبيق الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  /// Dismissable Soft Update Dialog (Reminder with "Update" and "Later" options).
  static void showSoftUpdateDialog({
    required String title,
    required String message,
    required String storeUrl,
    required String installedVersion,
    required String latestVersion,
    required VoidCallback onDismiss,
  }) {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppTheme.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  'إصدار جديد متاح: v$latestVersion',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  textDirection: TextDirection.ltr,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        _isDialogOpen = false;
                        onDismiss();
                        Get.back();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'لاحقاً',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _isDialogOpen = false;
                        Get.back();
                        launchUpdateUrl(storeUrl);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'تحديث الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    ).then((_) {
      _isDialogOpen = false;
    });
  }
}
