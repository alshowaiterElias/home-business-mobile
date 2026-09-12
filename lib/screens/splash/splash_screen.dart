import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/app_update_service.dart';
import '../../core/network/data_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _installedVersion = '1.0.0+17';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Start initialization and update checks
    _initAppAndCheckUpdates();
  }

  Future<void> _initAppAndCheckUpdates() async {
    // 1. Ensure splash animation plays for at least 1800ms
    final minSplashDuration = Future.delayed(const Duration(milliseconds: 1800));

    Map<String, dynamic> config = {};
    AppUpdateStatus updateStatus = AppUpdateStatus.upToDate;

    try {
      final installed = await AppUpdateService.getInstalledVersion();
      if (mounted) {
        setState(() {
          _installedVersion = '${installed.version}+${installed.buildNumber}';
        });
      }

      config = await DataService.getAppConfig().timeout(const Duration(seconds: 4));
      if (config.isNotEmpty) {
        updateStatus = await AppUpdateService.checkUpdateStatus(config);
      }
    } catch (e) {
      debugPrint('[SplashScreen] Config check error/timeout: $e');
    }

    // Wait for the minimum splash animation to finish
    await minSplashDuration;
    if (!mounted) return;

    // 2. Handle Maintenance Mode
    if (updateStatus == AppUpdateStatus.maintenance) {
      AppUpdateService.showMaintenanceDialog(config);
      return; // Stop navigation! Stay on splash screen
    }

    // 3. Handle Force Update
    if (updateStatus == AppUpdateStatus.forceUpdate) {
      final installed = await AppUpdateService.getInstalledVersion();
      final minAppVersion = config['minAppVersion']?.toString().trim() ?? '2.0.0';
      final appStoreUrl = config['appStoreUrl']?.toString().trim() ??
          'https://play.google.com/store/apps/details?id=com.homebusiness.app';

      AppUpdateService.showForceUpdateDialog(
        title: config['forceUpdateTitleAr']?.toString() ?? 'تحديث هام وإلزامي',
        message: config['forceUpdateMessageAr']?.toString() ??
            'يتطلب التطبيق تحديثاً ضرورياً لمتابعة استخدامه بشكل آمن ومستقر.',
        storeUrl: appStoreUrl,
        installedVersion: installed.version,
        requiredVersion: minAppVersion,
      );
      return; // Stop navigation! Stay on splash screen with blocking modal
    }

    // 4. Normal flow: Proceed to /main
    Get.offAllNamed('/main');

    // 5. If Soft Update is available, prompt smoothly after main screen renders
    if (updateStatus == AppUpdateStatus.softUpdate) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        AppUpdateService.checkForUpdates(config);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/icon/app_logo.png',
                  width: 135,
                  height: 135,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space32),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'السوق المنزلي',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'صُنع بحب.. من البيت إلى البيت',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      'الإصدار $_installedVersion',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
