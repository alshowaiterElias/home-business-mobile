import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/network/storage_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();
    final themeCtrl = Get.find<ThemeController>();
    final isPushEnabled = StorageService.isNotificationsEnabled().obs;

    return Obx(() {
      final isLoggedIn = auth.isLoggedIn.value;
      final user = auth.currentUser;
      final phone = user['phoneNumber'] ?? '';

      final hasStore = auth.hasStore.value;
      final business = user['business'] is Map ? user['business'] as Map : null;
      final businessName = business?['businessName'] as String?;
      final logoUrl = business?['logoUrl'] as String?;

      String headerTitle;
      if (!isLoggedIn) {
        headerTitle = 'زائر';
      } else if (hasStore) {
        headerTitle = (businessName != null && businessName.trim().isNotEmpty)
            ? businessName.trim()
            : 'صاحب متجر';
      } else {
        headerTitle = 'عميل';
      }

      return Scaffold(
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Profile Header ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + AppTheme.space24,
                  bottom: AppTheme.space24,
                  right: AppTheme.space20,
                  left: AppTheme.space20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.primary],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Column(
                  children: [
                    // Top row: settings
                    const SizedBox(height: AppTheme.space16),

                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 2.5,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            (isLoggedIn &&
                                hasStore &&
                                logoUrl != null &&
                                logoUrl.trim().isNotEmpty)
                            ? Image.network(
                                logoUrl.trim(),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.storefront_rounded,
                                  color: Colors.white,
                                  size: 42,
                                ),
                              )
                            : Icon(
                                !isLoggedIn
                                    ? Icons.person_outline_rounded
                                    : (hasStore
                                          ? Icons.storefront_rounded
                                          : Icons.person_rounded),
                                color: Colors.white,
                                size: 42,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),

                    Text(
                      headerTitle,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoggedIn ? phone : 'الرجاء تسجيل الدخول',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),
                  ],
                ),
              ),
            ),

            // ── My Store CTA ───────────────────────────────────────
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final isSuspended =
                      user['business'] != null &&
                      user['business']['isActive'] == false;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space20,
                      AppTheme.space16,
                      AppTheme.space4,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        if (auth.hasStore.value) {
                          Get.toNamed('/seller-dashboard');
                        } else if (isLoggedIn) {
                          Get.toNamed('/create-store');
                        } else {
                          Get.toNamed('/auth');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: AppTheme.shadowSm,
                          border: Border.all(
                            color: isSuspended
                                ? AppTheme.error.withValues(alpha: 0.5)
                                : AppTheme.primaryLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSuspended
                                    ? AppTheme.error.withValues(alpha: 0.1)
                                    : AppTheme.primarySurface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Icon(
                                isSuspended
                                    ? Icons.no_accounts_rounded
                                    : Icons.storefront_rounded,
                                color: isSuspended
                                    ? AppTheme.error
                                    : AppTheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auth.hasStore.value
                                        ? 'متجري'
                                        : 'إنشاء متجر',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  Text(
                                    isSuspended
                                        ? 'حساب المتجر معطل 🚫 - اضغط للتفاصيل'
                                        : (auth.hasStore.value
                                              ? 'إدارة المنتجات والطلبات'
                                              : 'ابدأ مشروعك المنزلي الآن'),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSuspended
                                          ? AppTheme.error
                                          : AppTheme.textSecondary,
                                      fontWeight: isSuspended
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSuspended
                                    ? AppTheme.error
                                    : AppTheme.primary,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusFull,
                                ),
                              ),
                              child: Text(
                                isSuspended ? 'معطل' : 'فتح',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Menu Items ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space20,
                  AppTheme.space16,
                  AppTheme.space24,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      _MenuItem(
                        icon: Icons.notifications_outlined,
                        iconBg: AppTheme.accentSurface,
                        iconColor: AppTheme.accent,
                        title: 'الإشعارات',
                        trailing: Obx(() {
                          final notifCtrl =
                              Get.isRegistered<NotificationController>()
                              ? Get.find<NotificationController>()
                              : Get.put(NotificationController());

                          final count = notifCtrl.unreadCount;
                          if (count == 0) return const SizedBox.shrink();

                          return Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppTheme.error,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : count.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          );
                        }),
                        onTap: () => Get.toNamed('/notifications'),
                      ),
                      const Divider(indent: 68, endIndent: 16, height: 1),
                      _MenuItem(
                        icon: Icons.notifications_active_outlined,
                        iconBg: AppTheme.primarySurface,
                        iconColor: AppTheme.primary,
                        title: 'إشعارات التطبيق',
                        showArrow: false,
                        trailing: Obx(
                          () => Switch.adaptive(
                            value: isPushEnabled.value,
                            activeColor: AppTheme.primary,
                            onChanged: (val) async {
                              isPushEnabled.value = val;
                              await StorageService.setNotificationsEnabled(val);
                              Get.snackbar(
                                'إعدادات الإشعارات',
                                val
                                    ? 'تم تفعيل التنبيهات على هذا الجهاز'
                                    : 'تم حظر كافة التنبيهات على هذا الجهاز',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: val
                                    ? AppTheme.primary
                                    : Colors.grey.shade800,
                                colorText: Colors.white,
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ),
                        onTap: () async {
                          final newVal = !isPushEnabled.value;
                          isPushEnabled.value = newVal;
                          await StorageService.setNotificationsEnabled(newVal);
                          Get.snackbar(
                            'إعدادات الإشعارات',
                            newVal
                                ? 'تم تفعيل التنبيهات على هذا الجهاز'
                                : 'تم حظر كافة التنبيهات على هذا الجهاز',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: newVal
                                ? AppTheme.primary
                                : Colors.grey.shade800,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        },
                      ),
                      const Divider(indent: 68, endIndent: 16, height: 1),
                      _MenuItem(
                        icon: themeCtrl.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        iconBg: context.colors.iconBgSubtle,
                        iconColor: context.colors.textPrimary,
                        title: 'المظهر الداكن',
                        showArrow: false,
                        trailing: Obx(() => Switch.adaptive(
                          value: themeCtrl.themeMode.value == ThemeMode.dark ||
                                (themeCtrl.themeMode.value == ThemeMode.system && Get.isDarkMode),
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            themeCtrl.setTheme(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        )),
                        onTap: () {
                          final isDark = themeCtrl.themeMode.value == ThemeMode.dark ||
                                        (themeCtrl.themeMode.value == ThemeMode.system && Get.isDarkMode);
                          themeCtrl.setTheme(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                      ),
                      const Divider(indent: 68, endIndent: 16, height: 1),
                      _MenuItem(
                        icon: Icons.help_outline_rounded,
                        iconBg: context.colors.isDark ? const Color(0xFF282A3A) : const Color(0xFFE8EAF6),
                        iconColor: const Color(0xFF5C6BC0),
                        title: 'المساعدة والدعم',
                        onTap: () => Get.toNamed('/support'),
                      ),
                      const Divider(indent: 68, endIndent: 16, height: 1),
                      _MenuItem(
                        icon: Icons.shield_outlined,
                        iconBg: context.colors.isDark ? const Color(0xFF203223) : const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        title: 'سياسة الخصوصية وحماية البيانات',
                        onTap: () => Get.toNamed('/privacy-policy'),
                      ),
                      const Divider(indent: 68, endIndent: 16, height: 1),
                      _MenuItem(
                        icon: Icons.info_outline_rounded,
                        iconBg: context.colors.isDark ? const Color(0xFF20302E) : const Color(0xFFE0F2F1),
                        iconColor: const Color(0xFF26A69A),
                        title: 'عن التطبيق',
                        onTap: () => Get.toNamed('/about'),
                      ),
                      if (isLoggedIn) ...[
                        const Divider(indent: 68, endIndent: 16, height: 1),
                        _MenuItem(
                          icon: Icons.delete_forever_rounded,
                          iconBg: context.colors.isDark ? const Color(0xFF3D2326) : const Color(0xFFFFEBEE),
                          iconColor: AppTheme.error,
                          title: 'حذف الحساب والبيانات',
                          titleColor: AppTheme.error,
                          onTap: () => _showDeleteAccountDialog(context, auth),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Logout Button ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  0,
                  AppTheme.space16,
                  AppTheme.space48,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: _MenuItem(
                    icon: Icons.logout_rounded,
                    iconBg: context.colors.iconBgSubtle,
                    iconColor: context.colors.textSecondary,
                    title: isLoggedIn ? 'تسجيل الخروج' : 'تسجيل الدخول',
                    titleColor: isLoggedIn
                        ? AppTheme.textPrimary
                        : AppTheme.primary,
                    showArrow: false,
                    onTap: () {
                      if (isLoggedIn) {
                        auth.logout();
                      } else {
                        Get.toNamed('/auth');
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showDeleteAccountDialog(BuildContext context, AuthController auth) {
    String selectedReason = 'عدم الحاجة للحساب حالياً';
    final reasonController = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(AppTheme.space24),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: Text(
                      'تأكيد طلب حذف الحساب',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'تنبيه هام وفق سياسات حماية البيانات:\n'
                '• سيتم حذف ملفك الشخصي وكافة بياناتك بشكل نهائي.\n'
                '• إذا كنت تمتلك متجراً، سيتم إيقاف المتجر وإخفاء كافة المنتجات.\n'
                '• لا يمكن استعادة البيانات بعد تأكيد عملية الحذف.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              const Text(
                'سبب طلب الحذف (اختياري):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'يرجى كتابة سبب طلب الحذف...',
                  fillColor: context.colors.surfaceVariant,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        Get.back();
                        final reason = reasonController.text.trim().isEmpty
                            ? selectedReason
                            : reasonController.text.trim();
                        await auth.deleteAccount(reason);
                      },
                      child: const Text(
                        'تأكيد الحذف النهائي',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}

// ─── Menu Item ───────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final bool showArrow;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.trailing,
    this.showArrow = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: titleColor),
                ),
              ),
              if (trailing != null) trailing!,
              if (showArrow && trailing == null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textHint,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
