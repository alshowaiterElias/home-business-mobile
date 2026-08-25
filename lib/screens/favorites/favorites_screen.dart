import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();
    final favoritesController = Get.find<FavoritesController>();

    return Obx(() {
      if (!auth.isLoggedIn.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('المفضلة')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'قم بتسجيل الدخول لعرض المفضلة',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Get.toNamed('/auth'),
                  child: const Text('تسجيل الدخول'),
                ),
              ],
            ),
          ),
        );
      }

      if (favoritesController.isLoading.value) {
        return Scaffold(
          appBar: AppBar(title: const Text('المفضلة')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      final favorites = favoritesController.favorites;
      final hasFavorites = favorites.isNotEmpty;

      return Scaffold(
        appBar: AppBar(title: const Text('المفضلة')),
        body: hasFavorites
            ? CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Count header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space16,
                        AppTheme.space12,
                        AppTheme.space16,
                        AppTheme.space4,
                      ),
                      child: Text(
                        '${favorites.length} منتج محفوظ',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),

                  // Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space12,
                      AppTheme.space16,
                      AppTheme.space24,
                    ),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ProductCard(
                          product: favorites[index],
                          heroTagPrefix: 'fav-',
                        );
                      }, childCount: favorites.length),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                    ),
                  ),
                ],
              )
            : _EmptyState(theme: theme),
      );
    });
  }
}

// ─── Empty State ─────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_outline_rounded,
                size: 48,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text('لا توجد منتجات محفوظة', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTheme.space8),
            Text(
              'عند إعجابك بمنتج، اضغط على أيقونة القلب\nلحفظه هنا والعودة إليه لاحقاً',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
            const SizedBox(height: AppTheme.space32),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () {
                  Get.offAllNamed("/main");
                },
                child: const Text('تصفح المنتجات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
