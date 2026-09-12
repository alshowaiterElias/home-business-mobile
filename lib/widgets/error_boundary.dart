import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/services/crash_service.dart';
import '../core/theme/app_theme.dart';

/// Configures global error handling for Flutter build/layout exceptions,
/// preventing the red/grey screen of death in production.
void setupGlobalErrorBoundary() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    // Record the rendering exception to Crashlytics
    CrashService.recordError(
      details.exception,
      details.stack,
      reason: 'Flutter Render/Build Exception: ${details.library}',
      fatal: false,
    );

    // In debug mode, allow developers to see the original stack trace if preferred,
    // but still present the graceful UI wrapper
    return AppErrorFallbackWidget(details: details);
  };
}

/// A graceful Arabic fallback screen displayed when a widget tree throws an unhandled error.
class AppErrorFallbackWidget extends StatelessWidget {
  final FlutterErrorDetails details;

  const AppErrorFallbackWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 44,
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                Text(
                  'عذراً، حدث خطأ غير متوقع',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  'تم إرسال تقرير بالخطأ إلى الفريق الفني وسيعملون على حله في أسرع وقت.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppTheme.space12),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: Colors.red,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space24),
                SizedBox(
                  width: 200,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to main dashboard safely
                      Get.offAllNamed('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    label: const Text(
                      'العودة للرئيسية',
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
    );
  }
}
