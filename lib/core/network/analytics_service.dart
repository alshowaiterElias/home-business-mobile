import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AnalyticsService {
  /// Track a product view (fire-and-forget, non-blocking)
  static Future<void> trackProductView(String productId, {String source = 'browse'}) async {
    if (productId.isEmpty) return;
    try {
      await ApiClient.instance.post(
        '/analytics/product-view',
        data: {
          'productId': productId,
          'source': source,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Analytics] trackProductView failed: $e');
    }
  }

  /// Track a store view (fire-and-forget, non-blocking)
  static Future<void> trackStoreView(String businessId, {String source = 'browse'}) async {
    if (businessId.isEmpty) return;
    try {
      await ApiClient.instance.post(
        '/analytics/store-view',
        data: {
          'businessId': businessId,
          'source': source,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Analytics] trackStoreView failed: $e');
    }
  }

  /// Track an ad impression (fire-and-forget, non-blocking)
  static Future<void> trackAdImpression(String advertisementId) async {
    if (advertisementId.isEmpty) return;
    try {
      await ApiClient.instance.post(
        '/analytics/ad-event',
        data: {
          'advertisementId': advertisementId,
          'eventType': 'impression',
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Analytics] trackAdImpression failed: $e');
    }
  }

  /// Track an ad click (fire-and-forget, non-blocking)
  static Future<void> trackAdClick(String advertisementId) async {
    if (advertisementId.isEmpty) return;
    try {
      await ApiClient.instance.post(
        '/analytics/ad-event',
        data: {
          'advertisementId': advertisementId,
          'eventType': 'click',
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Analytics] trackAdClick failed: $e');
    }
  }

  /// Track a WhatsApp inquiry event (fire-and-forget, non-blocking)
  static Future<void> trackWhatsAppInquiry({
    required String businessId,
    String? productId,
    required String inquiryType,
  }) async {
    if (businessId.isEmpty) return;
    if (!StorageService.hasToken()) return;

    try {
      await ApiClient.instance.post(
        '/analytics/whatsapp-inquiry',
        data: {
          'businessId': businessId,
          if (productId != null && productId.isNotEmpty) 'productId': productId,
          'inquiryType': inquiryType,
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [Analytics] trackWhatsAppInquiry failed: $e');
    }
  }
}
