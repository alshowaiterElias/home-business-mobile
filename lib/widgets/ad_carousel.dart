import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../core/network/data_service.dart';
import '../screens/product/all_products_screen.dart';
import '../screens/store/store_screen.dart';

class AdItem {
  final String id;
  final String imagePath;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final String actionText;
  final String? storeId;

  const AdItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    this.actionText = 'استكشف العرض',
    this.storeId,
  });
}

class AdCarousel extends StatefulWidget {
  final List<AdItem>? customAds;
  final Duration autoScrollDuration;

  const AdCarousel({
    super.key,
    this.customAds,
    this.autoScrollDuration = const Duration(seconds: 4),
  });

  @override
  State<AdCarousel> createState() => _AdCarouselState();
}

class _AdCarouselState extends State<AdCarousel> {
  late final PageController _pageController;
  List<AdItem> _ads = [];
  Timer? _timer;
  int _currentIndex = 0;
  bool _isUserInteracting = false;
  bool _isLoading = true;

  static const List<AdItem> _defaultAds = [
    AdItem(
      id: 'ad_1',
      imagePath: 'assets/ads/ad1.png',
      title: 'عروض الحلويات الشرقية والمنزلية 🍩',
      subtitle:
          'احصل على خصم 25% على كافة أطباق الحلويات والمخبوزات المصنوعة منزلياً بكل حب.',
      badgeText: 'خصم 25%',
      badgeColor: Color(0xFFFF9800),
      actionText: 'تصفح الحلويات',
    ),
    AdItem(
      id: 'ad_2',
      imagePath: 'assets/ads/ad2.png',
      title: 'تشكيلة الحرف اليدوية والهدايا 🎨',
      subtitle:
          'قطع فخارية ومطرزات يدوية فريدة مصممة بدقة عالية لجميع المناسبات.',
      badgeText: 'تشكيلة جديدة',
      badgeColor: Color(0xFF8E24AA),
      actionText: 'استكشف المنتجات',
    ),
    AdItem(
      id: 'ad_3',
      imagePath: 'assets/ads/ad3.png',
      title: 'وجبات منزلية طازجة يومياً 🍲',
      subtitle:
          'استمتع بأشهى الأكلات الشعبية والغربية المحضرة طازجة من طهاة الأسر المنتجة.',
      badgeText: 'الأكثر طلباً',
      badgeColor: Color(0xFFE53935),
      actionText: 'اطلب الآن',
    ),
    AdItem(
      id: 'ad_4',
      imagePath: 'assets/ads/ad4.png',
      title: 'عرض التوصيل المجاني 🚚',
      subtitle:
          'استفد من التوصيل المجاني الفوري لجميع الطلبات في نهاية هذا الأسبوع!',
      badgeText: 'توصيل مجاني',
      badgeColor: Color(0xFF4CAF50),
      actionText: 'تسوق الآن',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.93, initialPage: 0);

    if (widget.customAds != null) {
      _ads = widget.customAds!;
      _isLoading = false;
      _startTimer();
    } else {
      _fetchBackendAds();
    }
  }

  Future<void> _fetchBackendAds() async {
    try {
      final backendAds = await DataService.getAds();
      if (backendAds.isNotEmpty) {
        final mappedAds = backendAds.map((ad) {
          final rawUrl = ad['imageUrl'] as String? ?? '';
          final fullUrl = ApiClient.getImageUrl(rawUrl);
          final store = ad['store'] as Map<String, dynamic>?;
          final storeId = ad['storeId'] as String?;
          final storeName = store?['businessName'] as String?;

          return AdItem(
            id: ad['id'] as String? ?? UniqueKey().toString(),
            imagePath: fullUrl,
            title: storeName != null
                ? 'إعلان متجر $storeName'
                : 'إعلان ترويجي مميز 🌟',
            subtitle: storeName != null
                ? 'انقر لزيارة متجر $storeName وتصفح أحدث منتجاتهم'
                : 'انقر لمشاهدة تفاصيل العرض الترويجي',
            badgeText: storeName ?? 'إعلان مميز',
            badgeColor: const Color(0xFF009688),
            actionText: storeId != null ? 'زيارة المتجر' : 'استكشف المنتجات',
            storeId: storeId,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _ads = mappedAds;
            _isLoading = false;
          });
          _startTimer();
        }
      } else {
        if (mounted) {
          setState(() {
            _ads = _defaultAds;
            _isLoading = false;
          });
          _startTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ads = _defaultAds;
          _isLoading = false;
        });
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_ads.length <= 1) return;

    _timer = Timer.periodic(widget.autoScrollDuration, (timer) {
      if (_isUserInteracting || !mounted) return;

      final nextIndex = (_currentIndex + 1) % _ads.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _showAdOverlay(BuildContext context, AdItem ad) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق الإعلان',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: _AdOverlayDialog(ad: ad),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
      );
    }
    return Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.primaryDark,
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 48, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: 165,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (_ads.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 165,
          child: Listener(
            onPointerDown: (_) {
              setState(() => _isUserInteracting = true);
            },
            onPointerUp: (_) {
              setState(() => _isUserInteracting = false);
              _resetTimer();
            },
            onPointerCancel: (_) {
              setState(() => _isUserInteracting = false);
              _resetTimer();
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _ads.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: GestureDetector(
                    onTap: () => _showAdOverlay(context, ad),
                    child: Hero(
                      tag: 'ad-banner-${ad.id}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLg,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Image (Asset or Network)
                              _buildAdImage(ad.imagePath),

                              // Gradient overlay for text readability
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withValues(alpha: 0.75),
                                      Colors.black.withValues(alpha: 0.3),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.bottomRight,
                                    end: Alignment.topLeft,
                                    stops: const [0.0, 0.6, 1.0],
                                  ),
                                ),
                              ),

                              // Badge tag
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ad.badgeColor,
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
                                  child: Text(
                                    ad.badgeText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              // Content Text & Action Button
                              Positioned(
                                bottom: 12,
                                right: 14,
                                left: 14,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            ad.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  color: Color(0x73000000),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            ad.subtitle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusFull,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'التفاصيل',
                                            style: TextStyle(
                                              color: AppTheme.primaryDark,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 10,
                                            color: AppTheme.primaryDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: AppTheme.space8),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_ads.length, (index) {
            final isSelected = _currentIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: isSelected ? 22 : 6,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Enlarged Overlay Dialog Widget ────────────────────────────────
class _AdOverlayDialog extends StatelessWidget {
  final AdItem ad;

  const _AdOverlayDialog({required this.ad});

  Widget _buildAdImage(String path) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return Image.network(
      path,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.primaryDark,
      child: const Center(
        child: Icon(Icons.campaign_rounded, size: 64, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.78;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Enlarged Image Header with Close Button
              Flexible(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'ad-banner-${ad.id}',
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _buildAdImage(ad.imagePath),
                      ),
                    ),

                    // Badge
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: ad.badgeColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          ad.badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Close Button
                    Positioned(
                      top: 14,
                      left: 14,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detailed Ad Info Section
              Padding(
                padding: const EdgeInsets.all(AppTheme.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ad.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space12),
                    Text(
                      ad.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.5,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space20),

                    // Action Button (Navigates to Store if storeId exists, otherwise All Products)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (ad.storeId != null && ad.storeId!.isNotEmpty) {
                            Get.to(
                              () => const StoreScreen(),
                              arguments: {'id': ad.storeId},
                            );
                          } else {
                            Get.to(() => const AllProductsScreen());
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              ad.actionText,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.storefront_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
