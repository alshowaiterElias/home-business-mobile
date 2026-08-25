import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

class ApiClient {
  static late Dio _dio;

  // IMPORTANT: For physical mobile devices testing against a local backend,
  // Use --dart-define=API_URL=https://your-production-url.com/api/v1 when building for production.
  // Falls back to local dev IP if not provided.
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://home-business-backend.onrender.com/api/v1',
  );

  static String getImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Remove the /api/v1 part to point directly to the host for static files
    final serverUrl = baseUrl.replaceAll('/api/v1', '');
    if (!path.startsWith('/')) path = '/$path';
    return '$serverUrl$path';
  }

  static void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Inject the JWT token into the headers if it exists
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          if (kDebugMode) {
            debugPrint('🌐 [API Request] ${options.method} ${options.uri}');
            if (options.data != null) debugPrint('📦 Data: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '✅ [API Response] ${response.statusCode} ${response.requestOptions.uri}',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            debugPrint('❌ [API Error] ${e.type} - ${e.message}');
            if (e.response != null) {
              debugPrint('🚨 Error Data: ${e.response?.data}');
            }
          }

          // Auto-logout on 401 (expired/invalid token)
          if (e.response?.statusCode == 401 && StorageService.hasToken()) {
            StorageService.removeToken();
            Get.offAllNamed('/auth');
          }

          return handler.next(e);
        },
      ),
    );
  }

  static Dio get instance => _dio;
}
