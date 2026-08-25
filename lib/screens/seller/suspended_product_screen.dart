import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/data_controller.dart';

class SuspendedProductScreen extends StatelessWidget {
  final String productTitle;
  final String? storeName;
  final String? imageUrl;

  const SuspendedProductScreen({
    super.key,
    required this.productTitle,
    this.storeName,
    this.imageUrl,
  });

  Future<void> _openWhatsAppSupport() async {
    final dataController = Get.isRegistered<DataController>()
        ? Get.find<DataController>()
        : Get.put(DataController());
    final rawPhone = dataController.supportPhone.value;
    final adminPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    
    final message = Uri.encodeComponent(
      'مرحباً إدارة تطبيق السوق المنزلي،\n\nأنا صاحب متجر ${storeName ?? ""}. أود الاستفسار عن سبب توقيف منتجي "$productTitle" وكيفية إعادة تفعيله. شكراً لكم.',
    );
    final whatsappUrl = Uri.parse('whatsapp://send?phone=$adminPhone&text=$message');
    final webUrl = Uri.parse('https://wa.me/$adminPhone?text=$message');

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar('خطأ', 'تعذر فتح الواتساب. تأكد من وجود التطبيق على هاتفك.');
    }
  }

  Future<void> _makeSupportCall() async {
    final dataController = Get.isRegistered<DataController>()
        ? Get.find<DataController>()
        : Get.put(DataController());
    final rawPhone = dataController.supportPhone.value;
    final phoneUrl = rawPhone.startsWith('+') ? rawPhone : '+$rawPhone';

    final uri = Uri.parse('tel:$phoneUrl');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('خطأ', 'تعذر إجراء الاتصال مباشرة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('حالة المنتج'),
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Red warning header badge with product icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.remove_shopping_cart_rounded,
                      size: 50,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Product Title
                Text(
                  'تم توقيف المنتج 🚫',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space8),
                Text(
                  productTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space20),

                // Explanation Box
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                    border: Border.all(
                      color: AppTheme.error.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'نأسف، تم توقيف عرض منتجك مؤقتاً من قبل إدارة التطبيق لانتهاك السياسات أو بانتظار المراجعة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.space12),
                      const Divider(height: 1),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'تم إخفاء هذا المنتج تلقائياً من التطبيق ولن يظهر للعملاء في البحث أو أقسام المنتجات حتى يتم تفاعيله مجدداً.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space32),

                // Action 1: Contact via WhatsApp
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _openWhatsAppSupport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.chat_outlined, size: 22),
                    label: const Text(
                      'مراسلة الإدارة عبر الواتساب 💬',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space12),

                // Action 2: Phone Call
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _makeSupportCall,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 22),
                    label: const Text(
                      'الاتصال بالدعم الفني 📞',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Back Button
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('العودة للخلف', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
