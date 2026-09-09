import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

import '../../controllers/data_controller.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('https://wa.me/$cleanPhone');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر فتح تطبيق الواتساب',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _launchPhoneCall(String phone) async {
    final cleanPhone = phone.startsWith('+') ? phone : '+$phone';
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (!await launchUrl(url)) {
        Get.snackbar('خطأ', 'تعذر إجراء الاتصال الهاتفي',
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر إيجاد تطبيق لإجراء المكالمة',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر فتح تطبيق البريد الإلكتروني',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataController = Get.isRegistered<DataController>()
        ? Get.find<DataController>()
        : Get.put(DataController());

    return Scaffold(
      appBar: AppBar(title: const Text('المساعدة والدعم')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.space24),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.colors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                size: 50,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text(
              'كيف يمكننا مساعدتك؟',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              'فريق الدعم الفني متواجد للإجابة على استفساراتك وحل أي مشكلة تواجهك في التطبيق.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space48),

            // Contact Options (Dynamic from Admin Settings)
            Obx(() {
              final phone = dataController.supportPhone.value;
              final email = dataController.supportEmail.value;

              return Column(
                children: [
                  _ContactOption(
                    icon: Icons.chat_rounded,
                    title: 'تواصل عبر واتساب',
                    subtitle: phone,
                    color: AppTheme.whatsapp,
                    onTap: () => _launchWhatsApp(phone),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _ContactOption(
                    icon: Icons.phone_in_talk_rounded,
                    title: 'اتصال هاتفي مباشر',
                    subtitle: phone,
                    color: context.colors.primary,
                    onTap: () => _launchPhoneCall(phone),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  _ContactOption(
                    icon: Icons.email_rounded,
                    title: 'البريد الإلكتروني',
                    subtitle: email,
                    color: const Color(0xFFD32F2F),
                    onTap: () => _launchEmail(email),
                  ),
                ],
              );
            }),

            const SizedBox(height: AppTheme.space48),
            Divider(color: context.colors.divider),
            const SizedBox(height: AppTheme.space16),
            
            Text(
              'أوقات الدعم والاستجابة: متواجدون على مدار 24 ساعة لخدمتكم', 
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ), 
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          border: Border.all(color: context.colors.divider),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: context.colors.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 0.5,
                      color: context.colors.textSecondary,
                    ), 
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.colors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
