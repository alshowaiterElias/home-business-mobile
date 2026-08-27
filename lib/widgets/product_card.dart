import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../models/dummy_data.dart';
import '../core/theme/app_theme.dart';
import '../screens/product/product_details_screen.dart';
import '../controllers/favorites_controller.dart';
import '../core/network/whatsapp_service.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String heroTagPrefix;

  const ProductCard({
    super.key,
    required this.product,
    this.heroTagPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => Get.to(
        () => ProductDetailsScreen(
          product: product,
          heroTagPrefix: heroTagPrefix,
        ),
        transition: Transition.cupertino,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Product image with shimmer loading
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusLg),
                    ),
                    child: Hero(
                      tag: '${heroTagPrefix}product-${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        memCacheWidth: 400,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[200]!,
                          highlightColor: Colors.grey[50]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppTheme.background,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: AppTheme.textHint,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Favourite badge — top start
                  Positioned(
                    top: AppTheme.space8,
                    right: AppTheme.space8,
                    child: _FavBadge(product: product),
                  ),

                  // Rating pill — bottom start
                  if (product.rating > 0)
                    Positioned(
                      bottom: AppTheme.space8,
                      right: AppTheme.space8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppTheme.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Details ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space12,
                AppTheme.space12,
                AppTheme.space12,
                AppTheme.space12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),

                  // Seller
                  Row(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        size: 13,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Price row + WhatsApp
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          '${_formatPrice(product.price)} ر.ي',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Small WhatsApp icon button
                      Material(
                        color: AppTheme.whatsapp.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          onTap: () {
                            if (product.sellerPhone.isEmpty) {
                              Get.snackbar(
                                'تنبيه',
                                'رقم هاتف المتجر غير متوفر',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                              return;
                            }
                            WhatsAppService.openWhatsAppForProduct(
                              phoneNumber: product.sellerPhone,
                              storeName: product.sellerName,
                              productName: product.title,
                              imageUrl: product.imageUrl,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: FaIcon(
                              FontAwesomeIcons.whatsapp,
                              size: 17,
                              color: AppTheme.whatsapp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(double price) {
    if (price >= 1000) {
      final formatted = price.toInt().toString();
      final buffer = StringBuffer();
      for (int i = 0; i < formatted.length; i++) {
        if (i > 0 && (formatted.length - i) % 3 == 0) buffer.write(',');
        buffer.write(formatted[i]);
      }
      return buffer.toString();
    }
    return price.toInt().toString();
  }
}

// ─── Favourite badge ─────────────────────────────────────────────
class _FavBadge extends StatelessWidget {
  final Product product;
  const _FavBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<FavoritesController>()) {
      return const SizedBox.shrink();
    }

    final favController = Get.find<FavoritesController>();

    return GestureDetector(
      onTap: () {
        favController.toggleFavorite(product);
      },
      child: Obx(() {
        final isFavorited = favController.isFavorited(product.id);

        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            isFavorited
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            size: 17,
            color: isFavorited ? AppTheme.error : AppTheme.textHint,
          ),
        );
      }),
    );
  }
}
