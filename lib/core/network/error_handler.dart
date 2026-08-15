import 'package:dio/dio.dart';

class ApiErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'انتهى وقت الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
        case DioExceptionType.sendTimeout:
          return 'انتهى وقت إرسال الطلب. يرجى المحاولة مرة أخرى.';
        case DioExceptionType.receiveTimeout:
          return 'انتهى وقت استلام الاستجابة من الخادم.';
        case DioExceptionType.badResponse:
          return _handleBadResponse(error.response);
        case DioExceptionType.cancel:
          return 'تم إلغاء الطلب.';
        case DioExceptionType.connectionError:
          return 'لا يوجد اتصال بالإنترنت أو تعذر الوصول للخادم.';
        case DioExceptionType.unknown:
          return 'حدث خطأ غير متوقع. يرجى المحاولة لاحقاً.';
        default:
          return 'حدث خطأ غير معروف في الاتصال بالخادم.';
      }
    }
    return 'حدث خطأ غير معروف: ${error.toString()}';
  }

  static String _handleBadResponse(Response? response) {
    if (response == null) return 'استجابة فارغة من الخادم.';

    // Extract backend's specific error message if it exists
    String? backendMessage;
    if (response.data is Map && response.data['message'] != null) {
      backendMessage = response.data['message'].toString();
      backendMessage = _translateBackendMessage(backendMessage);
    }

    switch (response.statusCode) {
      case 400:
        return backendMessage ?? 'طلب غير صالح. يرجى التحقق من البيانات المدخلة.';
      case 401:
        return backendMessage ?? 'غير مصرح لك. يرجى تسجيل الدخول مجدداً.';
      case 403:
        return backendMessage ?? 'ليس لديك صلاحية للقيام بهذا الإجراء.';
      case 404:
        return backendMessage ?? 'المورد المطلوب غير موجود.';
      case 409:
        return backendMessage ?? 'حدث تعارض في البيانات.';
      case 422:
        return backendMessage ?? 'البيانات المدخلة غير صحيحة.';
      case 500:
        return backendMessage ?? 'حدث خطأ داخلي في الخادم. يرجى المحاولة لاحقاً.';
      case 503:
        return backendMessage ?? 'الخدمة غير متوفرة حالياً.';
      default:
        return backendMessage ?? 'حدث خطأ (كود: ${response.statusCode}).';
    }
  }

  static String _translateBackendMessage(String message) {
    if (message.contains('description') && message.contains('at least')) {
      return 'وصف المنتج قصير جداً. يرجى إدخال 3 أحرف على الأقل.';
    }
    if (message.contains('title') && message.contains('at least')) {
      return 'اسم المنتج قصير جداً. يرجى إدخال حرفين على الأقل.';
    }
    if (message.contains('At least one product image is required')) {
      return 'يرجى إضافة صورة واحدة على الأقل للمنتج.';
    }
    if (message.contains('You must create a business profile')) {
      return 'يجب إنشاء ملف متجر أولاً قبل إضافة المنتجات.';
    }
    if (message.contains('Invalid or inactive category')) {
      return 'القسم المحدد غير صالح أو غير متاح حالياً.';
    }
    if (message.contains('Invalid file type detected')) {
      return 'نوع الملف المرفق غير مدعوم. يرجى اختيار صور فقط.';
    }
    if (message.contains('Too many requests')) {
      return 'تم تجاوز عدد المحاولات المسموح به. يرجى الانتظار والمحاولة لاحقاً.';
    }
    if (message.contains('Route not found')) {
      return 'الخدمة المطلوبة غير متوفرة.';
    }
    return message;
  }
}
