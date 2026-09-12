import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized crash and error monitoring service powered by Firebase Crashlytics.
class CrashService {
  /// Crashlytics is natively supported on Android & iOS.
  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Initializes Crashlytics hooks for fatal framework errors and uncaught async errors.
  static Future<void> init() async {
    if (!isSupported) {
      debugPrint('[CrashService] Crashlytics not supported on this platform, skipping.');
      return;
    }

    try {
      // In development mode, toggle collection if needed. Default enables in release and debug.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('✅ [CrashService] Firebase Crashlytics initialized successfully');
    } catch (e) {
      debugPrint('[CrashService] Failed to initialize Crashlytics: $e');
    }
  }

  /// Associate crashes with the authenticated user ID for rapid debugging.
  static Future<void> setUserIdentifier(String userId) async {
    if (!isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('[CrashService] Failed to set user identifier: $e');
    }
  }

  /// Clear user identification upon logout.
  static Future<void> clearUserIdentifier() async {
    if (!isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier('');
    } catch (_) {}
  }

  /// Manually record non-fatal or caught exceptions with stack traces.
  static Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    if (!isSupported) {
      debugPrint('[CrashService] Error logged ($reason): $error');
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[CrashService] Failed to record error: $e');
    }
  }

  /// Log custom breadcrumb messages for Crashlytics logs.
  static Future<void> log(String message) async {
    if (!isSupported) {
      debugPrint('[CrashService] Breadcrumb: $message');
      return;
    }
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Set custom key-value metadata for crash reports.
  static Future<void> setCustomKey(String key, Object value) async {
    if (!isSupported) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {}
  }
}
