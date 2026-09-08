import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        throw Exception(
          'استغرق المساعد وقتاً أطول من المتوقع. يرجى المحاولة مرة أخرى.',
        );
      }
      if (e.response?.statusCode == 503) {
        throw Exception(
          e.response?.data['message'] ?? 'المساعد غير متاح مؤقتاً',
        );
      }
      if (e.response?.statusCode == 422) {
        throw Exception(e.response?.data['message'] ?? 'سياق غير صالح');
      }
      if (e.response?.statusCode == 401) {
        throw Exception('يرجى تسجيل الدخول لاستخدام المساعد الذكي');
      }
      throw Exception(
        e.response?.data['message'] ?? 'تعذر الاتصال بالمساعد الذكي',
      );
    }
  }

  /// Progressive Server-Sent Events (SSE) stream reader for real-time typewriter tokens
  Stream<AiStreamEvent> askAssistantStream({
    required String message,
    required Map<String, dynamic> context,
    List<Map<String, String>>? history,
    List<String>? shownProductIds,
    CancelToken? cancelToken,
  }) async* {
    final clientRequestId = _uuid.v4();

    try {
      final response = await ApiClient.instance.post<ResponseBody>(
        '/ai/assistant/stream',
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
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream', 'Cache-Control': 'no-cache'},
          receiveTimeout: const Duration(seconds: 40),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield AiErrorEvent('تعذر فتح قناة البث المباشر مع المساعد الذكي');
        return;
      }

      String currentEvent = 'message';
      StringBuffer dataBuffer = StringBuffer();

      await for (final line
          in stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (line.isEmpty) {
          if (dataBuffer.isNotEmpty) {
            final rawData = dataBuffer.toString().trim();
            dataBuffer.clear();

            try {
              final parsedJson = jsonDecode(rawData) as Map<String, dynamic>;
              if (currentEvent == 'token') {
                final text = parsedJson['text']?.toString() ?? '';
                if (text.isNotEmpty) {
                  if (kDebugMode) debugPrint('🎯 [SSE Token] "$text"');
                  yield AiTokenEvent(text);
                }
              } else if (currentEvent == 'status') {
                final msg = parsedJson['message']?.toString() ?? '';
                if (msg.isNotEmpty) {
                  if (kDebugMode) debugPrint('📊 [SSE Status] "$msg"');
                  yield AiStatusEvent(msg);
                }
              } else if (currentEvent == 'done') {
                if (kDebugMode) debugPrint('🏁 [SSE Done] Payload received');
                final aiResponse = AiResponse.fromJson(parsedJson);
                yield AiDoneEvent(aiResponse);
              } else if (currentEvent == 'error') {
                final err =
                    parsedJson['message']?.toString() ?? 'حدث خطأ غير متوقع';
                if (kDebugMode) debugPrint('❌ [SSE Error] $err');
                yield AiErrorEvent(err);
              }
            } catch (e) {
              if (kDebugMode)
                debugPrint('⚠️ [SSE Parse Warning] $e for data: $rawData');
            }
          }
          currentEvent = 'message';
          continue;
        }

        if (line.startsWith('event:')) {
          currentEvent = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
          dataBuffer.write(line.substring(5).trim());
        }
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        yield AiErrorEvent('تم إلغاء الطلب');
        return;
      }
      final msg = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'تعذر الاتصال بالمساعد الذكي')
          : 'تعذر الاتصال بالمساعد الذكي';
      yield AiErrorEvent(msg.toString());
    } catch (e) {
      yield AiErrorEvent(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
