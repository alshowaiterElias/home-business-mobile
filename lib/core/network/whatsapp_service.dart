import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'api_client.dart';
import '../../models/dummy_data.dart';

class WhatsAppService {
  static final _templates = <String, String>{}.obs;

  static Future<void> loadTemplates() async {
    try {
      final response = await ApiClient.instance.get('/whatsapp/templates');
      final data = response.data['data'] as List<dynamic>;
      for (var template in data) {
        _templates[template['type']] = template['content'];
      }
    } catch (e) {
      print('Failed to load WhatsApp templates: $e');
      // Safely show snackbar only if UI overlay context is ready
      if (Get.context != null && Get.overlayContext != null) {
        Get.snackbar(
          'تنبيه',
          'تعذر تحميل قوالب الواتساب. يتم استخدام القوالب الافتراضية.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  static String _getTemplate(
    String type,
    Map<String, String> placeholders,
    String defaultTemplate,
  ) {
    String template = _templates[type] ?? defaultTemplate;
    placeholders.forEach((key, value) {
      template = template.replaceAll('{{$key}}', value);
    });
    return template;
  }

  static Future<void> openWhatsAppForProduct({
    required String phoneNumber,
    required String storeName,
    required String productName,
    String? imageUrl,
  }) async {
    final message = _getTemplate(
      'PRODUCT_INQUIRY',
      {
        'store_name': storeName,
        'product_name': productName,
        'image_url': imageUrl ?? '',
      },
      "مرحباً متجر $storeName،\n\nأنا مهتم بالمنتج التالي:\nاسم المنتج: $productName\n${imageUrl != null && imageUrl.isNotEmpty ? 'صورة المنتج: $imageUrl\n' : ''}\nهل يمكنك توفير المزيد من المعلومات؟",
    );
    await _launchWhatsApp(phoneNumber, message);
  }

  static Future<void> openWhatsAppForStore({
    required String phoneNumber,
    required String storeName,
  }) async {
    final message = _getTemplate(
      'STORE_INQUIRY',
      {'store_name': storeName},
      "مرحباً متجر $storeName،\n\nأود الاستفسار عن خدماتكم ومنتجاتكم. هل يمكنك تزويدي بمزيد من التفاصيل؟",
    );
    await _launchWhatsApp(phoneNumber, message);
  }

  static Future<void> _launchWhatsApp(String phone, String message) async {
    // Format phone number: remove non-digits, add country code if needed
    String formattedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!formattedPhone.startsWith('+') && !formattedPhone.startsWith('967')) {
      formattedPhone =
          '+967$formattedPhone'; // Assuming Yemen code as default if missing
    }

    final url = Uri.parse(
      'whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}',
    );
    final webUrl = Uri.parse(
      'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'تعذر فتح الواتساب. تأكد من تثبيت التطبيق.');
    }
  }

  static Future<void> shareProduct(Product product) async {
    final message =
        '''
تفاصيل المنتج:
الاسم: ${product.title}
السعر: ${product.price} ر.ي
التقييم: ${product.rating} (${product.reviewCount} تقييم)
المتجر: ${product.sellerName}
''';

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      if (product.imageUrl.isNotEmpty) {
        final fullUrl = ApiClient.getImageUrl(product.imageUrl);
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/share_product_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(fullUrl, filePath);
        if (Get.isDialogOpen ?? false) Get.back(); // close loader
        await Share.shareXFiles([XFile(filePath)], text: message);
      } else {
        if (Get.isDialogOpen ?? false) Get.back();
        await Share.share(message);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      // Fallback
      await Share.share(
        '$message\nصورة المنتج: ${ApiClient.getImageUrl(product.imageUrl)}',
      );
    }
  }

  static Future<void> shareStore(
    Map<String, dynamic> businessData,
    int productCount,
  ) async {
    final businessName = businessData['businessName'] ?? 'متجر';
    final location = businessData['city']?['nameAr'] ?? 'غير محدد';
    final activeSince = businessData['createdAt'] != null
        ? DateTime.parse(businessData['createdAt']).year.toString()
        : '٢٠٢٤';

    final message =
        '''
تفاصيل المتجر:
الاسم: $businessName
الموقع: $location
منذ: $activeSinceؤقم
عدد المنتجات: $productCount
''';

    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final logoUrl = businessData['logoUrl'];
      if (logoUrl != null && logoUrl.toString().isNotEmpty) {
        final fullUrl = ApiClient.getImageUrl(logoUrl.toString());
        final tempDir = await getTemporaryDirectory();
        final filePath =
            '${tempDir.path}/share_store_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Dio().download(fullUrl, filePath);
        if (Get.isDialogOpen ?? false) Get.back(); // close loader
        await Share.shareXFiles([XFile(filePath)], text: message);
      } else {
        if (Get.isDialogOpen ?? false) Get.back();
        await Share.share(message);
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      await Share.share(message);
    }
  }
}
