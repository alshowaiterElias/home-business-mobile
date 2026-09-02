import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/main_controller.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../categories/categories_screen.dart';
import '../favorites/favorites_screen.dart';
import '../chat/conversations_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatelessWidget {
  MainScreen({super.key});

  final MainController controller = Get.put(MainController());

  final List<Widget> pages = [
    const HomeScreen(),
    const CategoriesScreen(),
    const FavoritesScreen(),
    const ConversationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Adapt status bar icons based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return Obx(() {
      final index = controller.currentIndex.value;

      return Scaffold(
        body: IndexedStack(index: index, children: pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            boxShadow: context.colors.shadowSm,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space8,
                vertical: AppTheme.space4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'الرئيسية',
                    isActive: index == 0,
                    onTap: () => controller.changeTab(0),
                  ),
                  _NavItem(
                    icon: Icons.category_outlined,
                    activeIcon: Icons.category_rounded,
                    label: 'الأقسام',
                    isActive: index == 1,
                    onTap: () => controller.changeTab(1),
                  ),
                  _NavItem(
                    icon: Icons.favorite_outline_rounded,
                    activeIcon: Icons.favorite_rounded,
                    label: 'المفضلة',
                    isActive: index == 2,
                    onTap: () => controller.changeTab(2),
                  ),
                  Obx(() {
                    final auth = Get.find<AuthController>();
                    int badge = 0;
                    if (auth.isLoggedIn.value && Get.isRegistered<ChatController>()) {
                      badge = Get.find<ChatController>().unreadCount.value;
                    }
                    return _NavItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      activeIcon: Icons.chat_bubble_rounded,
                      label: 'المحادثات',
                      isActive: index == 3,
                      onTap: () => controller.changeTab(3),
                      badge: badge,
                    );
                  }),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'حسابي',
                    isActive: index == 4,
                    onTap: () => controller.changeTab(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ─── Custom Navigation Item ──────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space12,
          vertical: AppTheme.space8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  size: 22,
                  color: isActive ? AppTheme.primary : context.colors.textHint,
                ),
                if (badge > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
