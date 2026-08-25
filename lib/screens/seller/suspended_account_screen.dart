import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';

class SuspendedAccountScreen extends StatelessWidget {
  final String? storeName;
  const SuspendedAccountScreen({super.key, this.storeName});

  Future<void> _openWhatsAppSupport() async {
    const adminPhone = '+967772546343';
    final message = Uri.encodeComponent(
      'مرحباً إدارة تطبيق السوق المنزلي،\n\nأنا صاحب متجر ${storeName ?? ""}. أود الاستفسار عن سبب تعليق حساب المتجر وكيفية إعادة تفعيله. شكراً لكم.',
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
    final uri = Uri.parse('tel:+967772546343');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('خطأ', 'تعذر إجراء الاتصال مباشرة');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('حالة الحساب'),
        automaticallyImplyLeading: true,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.error),
            tooltip: 'تسجيل الخروج',
            onPressed: () => auth.logout(),
          )
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.space24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Red warning header badge with lock icon
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
                      Icons.no_accounts_rounded,
                      size: 52,
                      color: AppTheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // Title
                Text(
                  'تم تعليق حساب المتجر 🚫',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space12),

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
                        'نأسف، تم إيقاف نشاط متجرك موقتاً من قبل إدارة التطبيق لانتهاك السياسات أو بانتظار استكمال التوثيق.',
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
                        'تم إخفاء منتجات متجرك تلقائياً من جميع أقسام التطبيق ولن تظهر للعملاء حتى إعادة تفعيل الحساب.',
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
                      'التواصل مع الإدارة عبر الواتساب 💬',
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

                // Action 3: Logout Button
                TextButton.icon(
                  onPressed: () => auth.logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.textSecondary),
                  label: const Text(
                    'تسجيل الخروج من الحساب',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
