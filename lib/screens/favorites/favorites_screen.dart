import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../core/network/data_service.dart';
import '../../core/network/api_client.dart';

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
          appBar: AppBar(title: const Text('المفضلة والمتابعة')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'قم بتسجيل الدخول لعرض المفضلة والمتاجر المتابعة',
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

      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('المفضلة والمتابعة'),
            bottom: TabBar(
              indicatorColor: context.colors.primary,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.textHint,
              tabs: const [
                Tab(
                  icon: Icon(Icons.favorite_rounded, size: 20),
                  text: 'المنتجات المفضلة',
                ),
                Tab(
                  icon: Icon(Icons.storefront_rounded, size: 20),
                  text: 'المتاجر المتابعة',
                ),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // Tab 1: Favorite Products
              _FavoriteProductsTab(favoritesController: favoritesController, theme: theme),
              // Tab 2: Followed Stores
              const _FollowedStoresView(),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Tab 1: Favorite Products ──────────────────────────────────
class _FavoriteProductsTab extends StatelessWidget {
  final FavoritesController favoritesController;
  final ThemeData theme;

  const _FavoriteProductsTab({
    required this.favoritesController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (favoritesController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final favorites = favoritesController.favorites;
      if (favorites.isEmpty) {
        return _EmptyState(theme: theme);
      }

      return CustomScrollView(
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
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Tab 2: Followed Stores View ──────────────────────────────
class _FollowedStoresView extends StatefulWidget {
  const _FollowedStoresView();

  @override
  State<_FollowedStoresView> createState() => _FollowedStoresViewState();
}

class _FollowedStoresViewState extends State<_FollowedStoresView> {
  bool _isLoading = true;
  List<dynamic> _stores = [];

  @override
  void initState() {
    super.initState();
    _fetchFollowedStores();
  }

  Future<void> _fetchFollowedStores() async {
    try {
      final stores = await DataService.getFollowedStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_stores.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: context.colors.primarySurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 44,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Text('لا توجد متاجر متابعة حالياً', style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppTheme.space8),
              Text(
                'يمكنك متابعة المتاجر المفضلة لديك من صفحة المتجر\nلتصلك جديد منتجاتهم بسرعة',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFollowedStores,
      color: context.colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.space16),
        itemCount: _stores.length,
        itemBuilder: (context, index) {
          final store = _stores[index];
          final logoUrl = store['logoUrl'] as String?;
          final fullLogoUrl = (logoUrl != null && logoUrl.isNotEmpty)
              ? ApiClient.getImageUrl(logoUrl)
              : null;
          final storeName = store['businessName'] ?? 'متجر غير معروف';
          final location = store['city']?['nameAr'] ?? 'اليمن';
          final followersCount = store['followersCount'] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            color: context.colors.surface,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: () {
                Get.toNamed('/store', arguments: {'id': store['id']})?.then((_) {
                  _fetchFollowedStores();
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryDark,
                      backgroundImage: fullLogoUrl != null ? NetworkImage(fullLogoUrl) : null,
                      child: fullLogoUrl == null
                          ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: context.colors.textHint),
                              const SizedBox(width: 2),
                              Text(location, style: theme.textTheme.bodySmall),
                              const SizedBox(width: 12),
                              Icon(Icons.people_outline_rounded, size: 14, color: context.colors.primary),
                              const SizedBox(width: 2),
                              Text(
                                '$followersCount متابع',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: context.colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.colors.textHint),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Empty State for Products ─────────────────────────────────
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
                color: context.colors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 48,
                color: context.colors.primary,
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
