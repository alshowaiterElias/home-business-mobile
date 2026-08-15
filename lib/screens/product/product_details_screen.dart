import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/report_sheet.dart';
import '../../controllers/product_details_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../core/network/whatsapp_service.dart';
import 'product_reviews_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final String heroTagPrefix;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.heroTagPrefix = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    // Initialize controller for this specific product
    final controller = Get.put(
      ProductDetailsController(productId: product.id),
      tag: product.id,
    );
    // Set initial values from the feed until backend response arrives
    if (controller.currentProductRating.value == 0.0) {
      controller.currentProductRating.value = product.rating;
      controller.currentProductReviewCount.value = product.reviewCount;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // ── Scrollable Content ──────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Image Gallery ───────────────────────────────────
              SliverAppBar(
                expandedHeight: 380,
                pinned: true,
                backgroundColor: AppTheme.surface,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _CircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Get.back(),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleButton(
                      icon: Icons.flag_outlined,
                      color: AppTheme.error,
                      onTap: () {
                        showReportSheet(
                          context,
                          targetType: 'PRODUCT',
                          targetId: product.id,
                          targetName: product.title,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _CircleButton(
                      icon: Icons.share_outlined,
                      onTap: () {
                        WhatsAppService.shareProduct(product);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Obx(
                      () => _CircleButton(
                        icon: controller.isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_outline_rounded,
                        color: controller.isFavorited ? AppTheme.error : null,
                        onTap: () => controller.toggleFavorite(product),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: '${heroTagPrefix}product-${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Shimmer.fromColors(
                        baseColor: Colors.grey[200]!,
                        highlightColor: Colors.grey[50]!,
                        child: Container(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppTheme.background,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 50,
                          color: AppTheme.textHint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Product Info ────────────────────────────────────
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusXl),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.space20,
                        AppTheme.space24,
                        AppTheme.space20,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category chip + Rating
                          Row(
                            children: [
                              if (product.categoryName.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySurface,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    product.categoryName,
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryDark,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                  ),
                                ),
                              const Spacer(),
                              const Icon(
                                Icons.star_rounded,
                                size: 18,
                                color: AppTheme.accent,
                              ),
                              const SizedBox(width: 4),
                              Obx(
                                () => Text(
                                  controller.currentProductRating.value
                                      .toStringAsFixed(1),
                                  style: theme.textTheme.titleMedium,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Obx(
                                () => Text(
                                  '(${controller.currentProductReviewCount.value})',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppTheme.space16),

                          // Title
                          Text(
                            product.title,
                            style: theme.textTheme.headlineMedium,
                          ),
                          const SizedBox(height: AppTheme.space8),

                          // Price
                          Text(
                            '${_formatPrice(product.price)} ر.ي',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // ── Seller Card ─────────────────────────
                          Container(
                            padding: const EdgeInsets.all(AppTheme.space16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLg,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primary.withOpacity(0.15),
                                        AppTheme.primaryLight.withOpacity(0.1),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.sellerName,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 13,
                                            color: AppTheme.textHint,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            product.location,
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => Get.toNamed(
                                    '/store',
                                    arguments: {'id': product.businessId},
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'زيارة المتجر',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // ── Description ─────────────────────────
                          Text(
                            'تفاصيل المنتج',
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            product.description,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppTheme.space24),

                          // ── Reviews Section ─────────────────────
                          _ReviewsSection(productId: product.id, theme: theme),

                          // Bottom spacing for CTA bar
                          SizedBox(height: 100 + bottomPad),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed Bottom CTA ────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                AppTheme.space16,
                AppTheme.space12,
                AppTheme.space16,
                AppTheme.space12 + bottomPad,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price summary (compact)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('السعر', style: theme.textTheme.bodySmall),
                        Text(
                          '${_formatPrice(product.price)} ر.ي',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppTheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // WhatsApp CTA
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (product.sellerPhone.isEmpty) {
                          Get.snackbar('تنبيه', 'رقم هاتف المتجر غير متوفر',
                              backgroundColor: Colors.orange, colorText: Colors.white);
                          return;
                        }
                        WhatsAppService.openWhatsAppForProduct(
                          phoneNumber: product.sellerPhone,
                          storeName: product.sellerName,
                          productName: product.title,
                          imageUrl: product.imageUrl,
                        );
                      },
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 20),
                      label: const Text('تواصل عبر واتساب'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.whatsapp,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

// ─── Circle Button ───────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: color ?? AppTheme.textPrimary),
      ),
    );
  }
}

// ─── Review Card ─────────────────────────────────────────────────
class ReviewCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final int rating;
  final String text;
  final String date;
  final bool isMine;
  final VoidCallback? onEdit;

  const ReviewCard({
    required this.theme,
    required this.name,
    required this.rating,
    this.text = '',
    required this.date,
    this.isMine = false,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: isMine ? AppTheme.primarySurface : AppTheme.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: isMine
            ? Border.all(color: AppTheme.primary.withOpacity(0.2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isMine ? AppTheme.primary : AppTheme.divider,
                child: Text(
                  name.isNotEmpty ? name.characters.first : '؟',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isMine ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: theme.textTheme.titleMedium),
                        if (isMine) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'تقييمك',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              // Stars
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: i < rating ? AppTheme.accent : AppTheme.textHint,
                  ),
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  final String productId;
  final ThemeData theme;

  const _ReviewsSection({required this.productId, required this.theme});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductDetailsController>(tag: productId);
    final auth = Get.find<AuthController>();

    return Obx(() {
      final isLoggedIn = auth.isLoggedIn.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('التقييمات والآراء', style: theme.textTheme.headlineSmall),
              if (controller.reviews.length > 1)
                GestureDetector(
                  onTap: () => Get.to(
                    () => ProductReviewsScreen(
                      productId: productId,
                      theme: theme,
                    ),
                  ),
                  child: Text(
                    'عرض الكل',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Add / Edit Review UI
          if (isLoggedIn && !controller.isMyProduct.value) ...[
            if (controller.isEditing.value) ...[
              // The Form
              Container(
                padding: const EdgeInsets.all(AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تقييمك', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (i) => GestureDetector(
                          onTap: () => controller.currentRating.value = i + 1,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              i < controller.currentRating.value
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 32,
                              color: i < controller.currentRating.value
                                  ? AppTheme.accent
                                  : AppTheme.textHint,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller.commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'أضف تعليقاً (اختياري)...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => controller.cancelEditing(),
                            child: const Text('إلغاء'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => controller.submitReview(),
                            child: const Text('حفظ التقييم'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Button to trigger editing
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => controller.startEditing(),
                  icon: Icon(
                    controller.myReview.value == null
                        ? Icons.star_outline_rounded
                        : Icons.edit_rounded,
                    size: 20,
                  ),
                  label: Text(
                    controller.myReview.value == null
                        ? 'أضف تقييماً'
                        : 'تعديل تقييمك',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.space24),
          ] else if (!isLoggedIn) ...[
            // Not logged in
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  Text(
                    'قم بتسجيل الدخول لإضافة تقييم',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Get.toNamed('/auth'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: const Text('تسجيل الدخول'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space24),
          ],

          // List of reviews
          ...controller.reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space12),
              child: ReviewCard(
                theme: theme,
                name: r.name,
                rating: r.rating,
                text: r.text ?? '',
                date: r.date,
                isMine: r.id == controller.myReview.value?.id,
                onEdit: r.id == controller.myReview.value?.id
                    ? () => controller.startEditing()
                    : null,
              ),
            ),
          ),
        ],
      );
    });
  }
}
