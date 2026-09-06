import 'package:dio/dio.dart';
import 'package:home_business_mobile/core/network/api_client.dart';
import 'package:home_business_mobile/models/ai_models.dart';
import 'package:uuid/uuid.dart';

class AiService {
  final Uuid _uuid = const Uuid();

  AiService();

  Future<AiResponse> askAssistant({
    required String message,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
    List<String>? shownProductIds,
    CancelToken? cancelToken,
  }) async {
    final clientRequestId = _uuid.v4();

    try {
      final response = await ApiClient.instance.post(
        '/ai/assistant',
        data: {
          'message': message,
          'context': context,
          'clientRequestId': clientRequestId,
          if (history != null && history.isNotEmpty) 'history': history,
          if (shownProductIds != null && shownProductIds.isNotEmpty)
            'shownProductIds': shownProductIds,
        },
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(seconds: 35),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      return AiResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        throw Exception('تم إلغاء الطلب');
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('استغرق المساعد وقتاً أطول من المتوقع. يرجى المحاولة مرة أخرى.');
      }
      if (e.response?.statusCode == 503) {
        throw Exception(e.response?.data['message'] ?? 'المساعد غير متاح مؤقتاً');
      }
      if (e.response?.statusCode == 422) {
        throw Exception(e.response?.data['message'] ?? 'سياق غير صالح');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('يرجى تسجيل الدخول لاستخدام المساعد الذكي');
      }
      throw Exception(e.response?.data['message'] ?? 'تعذر الاتصال بالمساعد الذكي');
    }
  }
}
