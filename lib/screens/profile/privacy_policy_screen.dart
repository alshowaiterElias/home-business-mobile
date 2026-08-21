import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _openWebPrivacyPolicy() async {
    final String serverUrl = ApiClient.baseUrl.replaceAll('/api/v1', '');
    final Uri privacyUri = Uri.parse('$serverUrl/privacy');

    try {
      if (!await launchUrl(privacyUri, mode: LaunchMode.externalApplication)) {
        await launchUrl(privacyUri);
      }
    } catch (e) {
      debugPrint('Error launching web privacy policy: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                boxShadow: AppTheme.shadowSm,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'سياسة الخصوصية وحماية البيانات',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'تطبيق السوق المنزلي ملتزم بأعلى معايير حماية وخصوصية أصحاب المتاجر والمشترين',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space20),

            // Policy Content Cards
            _buildSectionCard(
              context,
              icon: Icons.assignment_outlined,
              iconColor: AppTheme.primary,
              title: '١. المعلومات التي نجمعها',
              content:
                  '• رقم الهاتف: يُستخدم فقط للتحقق من هويتك عبر Firebase Authentication آمن.\n'
                  '• بيانات المتجر والمنتجات: المعروضات والمنتجات التي تقوم بنشرها بملء إرادتك.\n'
                  '• الصور المعروضة: الصور التي ترفعها لمنتجاتك وتُحفظ على خوادمنا الآمنة.\n'
                  '• بيانات الاستخدام: إحصائيات تقنية بسيطة لتحسين سرعة وأداء التطبيق.',
            ),
            const SizedBox(height: AppTheme.space12),

            _buildSectionCard(
              context,
              icon: Icons.tune_rounded,
              iconColor: Colors.amber.shade700,
              title: '٢. كيفية استخدام معلوماتك',
              content:
                  '• التحقق من الهوية وتوفير بيئة بيع وتشرّي مؤمّنة.\n'
                  '• تمكينك من إدارة منتجاتك واستقبال استفسارات المشترين.\n'
                  '• إرسال إشعارات تنبيهية حول حالات اعتماد منتجاتك أو البلاغات.',
            ),
            const SizedBox(height: AppTheme.space12),

            _buildSectionCard(
              context,
              icon: Icons.lock_outline_rounded,
              iconColor: Colors.teal,
              title: '٣. حماية البيانات وعدم المشاركة',
              content:
                  '✅ لا نبيع ولا نشارك بياناتك مع أي أطراف ثالثة لأغراض تسويقية أو تجارية.\n'
                  '• نعتمد على خدمات Google Firebase لتأمين تسجيل الدخول والإشعارات.\n'
                  '• كافة الاتصالات مشفرة ببروتوكول SSL/HTTPS عالي الأمان.',
            ),
            const SizedBox(height: AppTheme.space12),

            _buildSectionCard(
              context,
              icon: Icons.delete_sweep_outlined,
              iconColor: AppTheme.error,
              title: '٤. حقك في حذف البيانات والحساب',
              content:
                  'يحق لك في أي وقت طلب حذف حسابك نهائياً وكافة بياناتك المسجلة عبر إعدادات الملف الشخصي داخل التطبيق أو عبر الرابط المباشر للويب.',
            ),
            const SizedBox(height: AppTheme.space24),

            // External Link Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openWebPrivacyPolicy,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.open_in_browser_rounded),
                label: const Text(
                  'عرض صفحة الخصوصية على المتصفح (Web Policy)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.divider),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
