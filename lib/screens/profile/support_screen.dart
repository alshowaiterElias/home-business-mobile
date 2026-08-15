import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
              decoration: BoxDecoration(
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
              subtitle: '+967 777 000 000',
              color: AppTheme.whatsapp,
              onTap: () {
                Get.snackbar(
                  'واتساب', 'جاري فتح محادثة الدعم الفني...',
                  backgroundColor: AppTheme.whatsapp, colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16),
                );
              },
            ),
            const SizedBox(height: AppTheme.space16),
            _ContactOption(
              icon: Icons.phone_in_talk_rounded,
              title: 'اتصال هاتفي',
              subtitle: '+967 777 000 000',
              color: AppTheme.primary,
              onTap: () {},
            ),
            const SizedBox(height: AppTheme.space16),
            _ContactOption(
              icon: Icons.email_rounded,
              title: 'البريد الإلكتروني',
              subtitle: 'support@yemenhomebusiness.com',
              color: const Color(0xFFD32F2F),
              onTap: () {},
            ),
            
            const SizedBox(height: AppTheme.space48),
            const Divider(),
            const SizedBox(height: AppTheme.space16),
            
            Text('أوقات العمل: من السبت إلى الخميس، 8 صباحاً - 8 مساءً', 
              style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
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
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 1), textDirection: TextDirection.ltr),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }
}
