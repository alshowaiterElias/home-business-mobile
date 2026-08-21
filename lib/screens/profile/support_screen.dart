import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchWhatsApp() async {
    const phone = '967772546343';
    final Uri url = Uri.parse('https://wa.me/$phone');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر فتح تطبيق الواتساب',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _launchPhoneCall() async {
    final Uri url = Uri.parse('tel:+967772546343');
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

  Future<void> _launchEmail() async {
    final Uri url = Uri.parse('mailto:alshowaiterelias@gmail.com');
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
              decoration: const BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.support_agent_rounded, size: 50, color: AppTheme.primary),
            ),
            const SizedBox(height: AppTheme.space24),
            Text('كيف يمكننا مساعدتك؟', style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppTheme.space8),
            Text(
              'فريق الدعم الفني متواجد للإجابة على استفساراتك وحل أي مشكلة تواجهك في التطبيق.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space48),

            // Contact Options
            _ContactOption(
              icon: Icons.chat_rounded,
              title: 'تواصل عبر واتساب',
              subtitle: '+967 772546343',
              color: AppTheme.whatsapp,
              onTap: _launchWhatsApp,
            ),
            const SizedBox(height: AppTheme.space16),
            _ContactOption(
              icon: Icons.phone_in_talk_rounded,
              title: 'اتصال هاتفي مباشر',
              subtitle: '+967 772546343',
              color: AppTheme.primary,
              onTap: _launchPhoneCall,
            ),
            const SizedBox(height: AppTheme.space16),
            _ContactOption(
              icon: Icons.email_rounded,
              title: 'البريد الإلكتروني',
              subtitle: 'alshowaiterelias@gmail.com',
              color: const Color(0xFFD32F2F),
              onTap: _launchEmail,
            ),
            
            const SizedBox(height: AppTheme.space48),
            const Divider(),
            const SizedBox(height: AppTheme.space16),
            
            Text(
              'أوقات الدعم والاستجابة: متواجدون على مدار 24 ساعة لخدمتكم', 
              style: theme.textTheme.bodySmall, 
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
          border: Border.all(color: AppTheme.divider),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          color: AppTheme.surface,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 0.5), 
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
