import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_business_mobile/core/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../controllers/data_controller.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri);
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر فتح الرابط',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataController = Get.isRegistered<DataController>()
        ? Get.find<DataController>()
        : Get.put(DataController());

    return Scaffold(
      appBar: AppBar(title: const Text('عن التطبيق')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppTheme.space24),

            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
                boxShadow: AppTheme.shadowMd,
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            Text('السوق المنزلي', style: theme.textTheme.headlineLarge),
            const SizedBox(height: 4),
            Text('الإصدار 1.0.0', style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.space32),

            // Description
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Text(
                'السوق المنزلي هو منصة إلكترونية تهدف إلى دعم وتمكين الأسر المنتجة وأصحاب المشاريع المنزلية في اليمن. نسعى لتوفير بيئة تسوق آمنة وسهلة تربط المشترين بأفضل المنتجات المحلية المصنوعة بحب.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppTheme.space32),

            // Developer Section
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'المطور والتواصل الفني',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppTheme.space12),

            Obx(() {
              final devPhone = dataController.developerPhone.value;
              final devEmail = dataController.developerEmail.value;
              final cleanPhone = devPhone.replaceAll(RegExp(r'[^\d+]'), '');

              return Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.primarySurface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: AppTheme.primaryLight.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.primary,
                          child: Text(
                            'E',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تم تطوير التطبيق بواسطة',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Elias Al-Showaiter',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppTheme.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Divider(),
                    const SizedBox(height: AppTheme.space8),

                    // Contact Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // WhatsApp Button
                        TextButton.icon(
                          onPressed: () =>
                              _launchUrl('https://wa.me/$cleanPhone'),
                          icon: const Icon(
                            Icons.chat_rounded,
                            color: AppTheme.whatsapp,
                            size: 20,
                          ),
                          label: const Text(
                            'واتساب',
                            style: TextStyle(
                              color: AppTheme.whatsapp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Call Button
                        TextButton.icon(
                          onPressed: () => _launchUrl('tel:$devPhone'),
                          icon: const Icon(
                            Icons.phone_rounded,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          label: const Text(
                            'اتصال',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Email Button
                        TextButton.icon(
                          onPressed: () => _launchUrl('mailto:$devEmail'),
                          icon: const Icon(
                            Icons.email_rounded,
                            color: Color(0xFFD32F2F),
                            size: 20,
                          ),
                          label: const Text(
                            'إيميل',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: AppTheme.space48),
            Text('جميع الحقوق محفوظة © 2026', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }
}
