import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/ad_carousel.dart';
import '../../core/network/api_client.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/data_controller.dart';
import '../product/all_products_screen.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/main_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ── Custom App Bar ─────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            toolbarHeight: 64,
            backgroundColor: context.colors.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryLight],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.store_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السوق المنزلي',
                      style: theme.textTheme.titleLarge?.copyWith(fontSize: 17),
                    ),
                    Text(
                      'اكتشف أفضل المنتجات المحلية',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              _AppBarAction(
                icon: Icons.search_rounded,
                onTap: () => Get.toNamed('/search'),
              ),
              const SizedBox(width: 4),
              Obx(() {
                final notifController = Get.put(NotificationController());
                final count = notifController.unreadCount;
                return _AppBarAction(
                  icon: Icons.notifications_none_rounded,
                  onTap: () => Get.toNamed('/notifications'),
                  badge: count,
                );
              }),
              const SizedBox(width: AppTheme.space12),
            ],
          ),

          // ── Search Bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space8,
                AppTheme.space16,
                AppTheme.space4,
              ),
              child: GestureDetector(
                onTap: () => Get.toNamed('/search'),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppTheme.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Text(
                        'ابحث عن منتج أو متجر...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Advertisement Carousel ─────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: AppTheme.space12),
              child: AdCarousel(),
            ),
          ),

          // ── Categories Horizontal Scroll ───────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space20),
              child: Column(
                children: [
                  _SectionHeader(
                    title: 'الأقسام',
                    onSeeAll: () {
                      Get.find<MainController>().changeTab(1);
                    },
                  ),
                  const SizedBox(height: AppTheme.space12),
                  SizedBox(
                    height: 96,
                    child: Obx(() {
                      final dataController = Get.find<DataController>();
                      if (dataController.isLoadingCategories.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final categories = dataController.categories;
                      if (categories.isEmpty) {
                        return const Center(child: Text('لا توجد أقسام'));
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        itemCount: categories.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.space12),
                        itemBuilder: (_, index) {
                          final catData = categories[index];
                          final cat = Category.fromJson(catData);
                          return _CategoryChip(category: cat);
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured Products Spotlight ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                    title: '⭐ منتجات مختارة',
                    onSeeAll: () {
                      Get.to(() => const AllProductsScreen());
                    },
                  ),
                  const SizedBox(height: AppTheme.space12),
                  SizedBox(
                    height: 240,
                    child: Obx(() {
                      final dataController = Get.find<DataController>();
                      if (dataController.isLoadingFeaturedProducts.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = dataController.featuredProducts;
                      if (products.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.space16),
                        itemBuilder: (_, index) {
                          final pData = products[index];
                          final product = Product.fromJson(pData);
                          return SizedBox(
                            width: 170,
                            child: Stack(
                              children: [
                                ProductCard(
                                  product: product,
                                  heroTagPrefix: 'featured-',
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          AppTheme.accent,
                                          Color(0xFFFFB300),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: 2),
                                        Text(
                                          'مميز',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured Stores Horizontal Scroll ───────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space24),
              child: Column(
                children: [
                  _SectionHeader(
                    title: '🌟 متاجر متميزة',
                    onSeeAll: () {
                      Get.toNamed('/all-stores');
                    },
                  ),
                  const SizedBox(height: AppTheme.space12),
                  SizedBox(
                    height: 165,
                    child: Obx(() {
                      final dataController = Get.find<DataController>();
                      if (dataController.isLoadingFeaturedStores.value) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final stores = dataController.featuredStores.isNotEmpty
                          ? dataController.featuredStores
                          : dataController.topStores;

                      if (stores.isEmpty) {
                        return const Center(child: Text('لا توجد متاجر'));
                      }
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        itemCount: stores.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: AppTheme.space12),
                        itemBuilder: (_, index) {
                          final store = stores[index];
                          final id = store['id'];
                          final name = store['businessName'] ?? '';
                          final logoUrl = store['logoUrl'];
                          final isFeatured = store['isFeatured'] == true;

                          // Calculate store rating
                          double totalRating = 0;
                          int ratedCount = 0;
                          if (store['products'] != null) {
                            for (var p in store['products']) {
                              final rating =
                                  double.tryParse(
                                    p['averageRating']?.toString() ?? '0',
                                  ) ??
                                  0.0;
                              if (rating > 0) {
                                totalRating += rating;
                                ratedCount++;
                              }
                            }
                          }
                          final ratingStr = ratedCount > 0
                              ? (totalRating / ratedCount).toStringAsFixed(1)
                              : '0.0';

                          return GestureDetector(
                            onTap: () {
                              Get.toNamed('/store', arguments: {'id': id});
                            },
                            child: Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: context.colors.surface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: isFeatured
                                    ? Border.all(
                                        color: AppTheme.accent,
                                        width: 1.5,
                                      )
                                    : null,
                                boxShadow: AppTheme.shadowSm,
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isFeatured
                                                  ? AppTheme.accent
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 34,
                                            backgroundColor:
                                                context.colors.background,
                                            backgroundImage: logoUrl != null
                                                ? NetworkImage(
                                                    ApiClient.getImageUrl(
                                                      logoUrl,
                                                    ),
                                                  )
                                                : null,
                                            child: logoUrl == null
                                                ? const Icon(
                                                    Icons.storefront_rounded,
                                                    size: 34,
                                                    color: AppTheme.textHint,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: AppTheme.space8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                          ),
                                          child: Text(
                                            name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color: AppTheme.accent,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              ratingStr,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isFeatured)
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: AppTheme.accent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.star_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured Banner ────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space24,
                AppTheme.space16,
                AppTheme.space4,
              ),
              child: Obx(() {
                final auth = Get.find<AuthController>();
                final hasStore = auth.hasStore.value;

                return GestureDetector(
                  onTap: () {
                    if (hasStore) {
                      Get.toNamed('/seller-dashboard');
                    } else {
                      if (!auth.isLoggedIn.value) {
                        Get.snackbar(
                          'تنبيه',
                          'يجب تسجيل الدخول أولاً لإنشاء متجرك',
                          backgroundColor: AppTheme.error,
                          colorText: Colors.white,
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                        Get.toNamed('/auth');
                      } else {
                        Get.toNamed('/create-store');
                      }
                    }
                  },
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: hasStore
                            ? [AppTheme.accent, const Color(0xFFFFC107)]
                            : [AppTheme.primaryDark, AppTheme.primary],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    ),
                    padding: const EdgeInsets.all(AppTheme.space20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                hasStore
                                    ? 'متجرك جاهز!'
                                    : 'ابدأ مشروعك من البيت!',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: hasStore
                                      ? AppTheme.textPrimary
                                      : Colors.white,
                                  fontSize: 17,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space8),
                              Text(
                                hasStore
                                    ? 'انتقل إلى لوحة التحكم لإدارة منتجاتك وطلباتك.'
                                    : 'أنشئ متجرك مجاناً وابدأ البيع الآن',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hasStore
                                      ? AppTheme.textSecondary
                                      : Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: AppTheme.space12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: hasStore
                                      ? AppTheme.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusFull,
                                  ),
                                ),
                                child: Text(
                                  hasStore ? 'لوحة التحكم' : 'أنشئ متجرك',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: hasStore
                                        ? Colors.white
                                        : AppTheme.primaryDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: hasStore
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                          ),
                          child: Icon(
                            hasStore
                                ? Icons.dashboard_customize_rounded
                                : Icons.storefront_rounded,
                            color: hasStore
                                ? AppTheme.textPrimary
                                : Colors.white,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Products Grid Header ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppTheme.space24),
              child: _SectionHeader(
                title: 'أحدث المنتجات',
                onSeeAll: () {
                  Get.to(() => const AllProductsScreen());
                },
              ),
            ),
          ),

          // ── Products Grid ──────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space12,
              AppTheme.space16,
              AppTheme.space24,
            ),
            sliver: Obx(() {
              final dataController = Get.find<DataController>();
              if (dataController.isLoadingProducts.value) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final products = dataController.latestProducts;
              if (products.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('لا توجد منتجات')),
                );
              }
              return SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final productData = products[index];
                  final product = Product.fromJson(productData);
                  return ProductCard(product: product, heroTagPrefix: 'home-');
                }, childCount: products.length),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'عرض الكل',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppTheme.primary),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category Chip ───────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final Category category;
  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed('/category-products', arguments: category);
      },
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(category.icon, color: category.color, size: 26),
            ),
            const SizedBox(height: AppTheme.space8),
            Text(
              category.nameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 11,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar Action Icon ─────────────────────────────────────────
class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final int badge;

  const _AppBarAction({
    required this.icon,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.colors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: context.colors.divider),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 20, color: context.colors.textPrimary),
            if (badge > 0)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
