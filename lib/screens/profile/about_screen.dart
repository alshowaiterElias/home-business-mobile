import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              child: const Icon(Icons.store_rounded, color: Colors.white, size: 50),
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
              child: Text('المطور', style: theme.textTheme.titleLarge),
            ),
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primary,
                    child: Text('D', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white)),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تم تطوير هذا التطبيق بواسطة', style: theme.textTheme.bodySmall),
                        Text('المطور الخاص بك', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.primaryDark)),
                        const SizedBox(height: 4),
                        Text('شغف بالبرمجة ودعم المجتمع.', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.space48),
            Text('جميع الحقوق محفوظة © 2024', style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }
}
