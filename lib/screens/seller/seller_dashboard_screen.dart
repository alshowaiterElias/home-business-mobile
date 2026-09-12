import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../core/network/error_handler.dart';
import '../../core/utils/image_compressor.dart';
import '../../controllers/seller_dashboard_controller.dart';
import '../../controllers/add_product_controller.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/auth_controller.dart';
import 'my_product_detail_screen.dart';
import 'edit_product_screen.dart';
import 'suspended_account_screen.dart';
import 'seller_analytics_screen.dart';
import 'manage_collections_screen.dart';
import '../../widgets/verified_badge.dart';
import '../../widgets/shimmer_skeletons.dart';
import '../../widgets/app_cached_image.dart';

/// Seller's private dashboard to manage their business and products.
class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(SellerDashboardController());

    return Obx(() {
      if (controller.isBusinessSuspended) {
        return SuspendedAccountScreen(
          storeName: controller.businessData['businessName'],
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم البائع'),
          actions: [
            Obx(() => controller.isRefreshing.value
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'تحديث البيانات',
                    onPressed: () => controller.fetchDashboardData(forceRefresh: true),
                  )),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'إعدادات المتجر',
              onPressed: () => Get.to(
                () => EditBusinessScreen(
                  businessData: Map<String, dynamic>.from(
                    controller.businessData,
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const AddProductScreen()),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة منتج'),
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchDashboardData(forceRefresh: true),
          child: GetBuilder<SellerDashboardController>(
            builder: (cnt) {
              if (cnt.isLoading.value && cnt.myProducts.isEmpty) {
                return const SellerDashboardSkeleton();
              }

              final products = cnt.filteredProducts;

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.space16),
                children: [
                  // ── Business Header Card ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.85),
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      children: [
                        AppCachedAvatar(
                          imageUrl: controller.businessData['logoUrl'],
                          radius: 28,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          fallbackIcon: Icons.storefront_rounded,
                          iconColor: Colors.white,
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      controller.businessData['businessName'] ??
                                          'متجري',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (controller.businessData['isVerified'] == true ||
                                      controller.businessData['is_verified'] == true) ...[
                                    const SizedBox(width: 6),
                                    const VerifiedBadge(
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    controller.storeRating,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.white.withValues(alpha: 0.8),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    controller
                                            .businessData['city']?['nameAr'] ??
                                        'اليمن',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Get.to(
                            () => EditBusinessScreen(
                              businessData: Map<String, dynamic>.from(
                                controller.businessData,
                              ),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),

                  // ── Store Analytics Card ──
                  GestureDetector(
                    onTap: () => Get.to(() => const SellerAnalyticsScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.primaryDark,
                            AppTheme.primary,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.analytics_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تحليلات المتجر والتفاعل 📊',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'مشاهدات المنتجات، استفسارات واتساب، والمزيد',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space12),

                  // ── Store Collections & Lookbooks Card ──
                  GestureDetector(
                    onTap: () => Get.to(() => const ManageCollectionsScreen()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF5E35B1),
                            Color(0xFF7E57C2),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5E35B1).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            child: const Icon(
                              Icons.collections_bookmark_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'المجموعات والكتالوجات (Lookbook) 🎨',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'نظّم منتجاتك في مجموعات منسقة تجذب الزبائن',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.space20),

                  // ── Quick Stats Grid (Interactive Filter Buttons) ────
                  Text(
                    'إحصائيات المنتجات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    children: [
                      _QuickStat(
                        label: 'الكل',
                        value: '${controller.myProducts.length}',
                        icon: Icons.inventory_2_outlined,
                        color: AppTheme.primary,
                        isSelected: controller.selectedFilter.value == 'ALL',
                        onTap: () => controller.setFilter('ALL'),
                      ),
                      const SizedBox(width: 8),
                      _QuickStat(
                        label: 'نشطة',
                        value: '${controller.activeProductsCount}',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.teal,
                        isSelected:
                            controller.selectedFilter.value == 'APPROVED',
                        onTap: () => controller.setFilter('APPROVED'),
                      ),
                      const SizedBox(width: 8),
                      _QuickStat(
                        label: 'بالانتظار',
                        value: '${controller.pendingProductsCount}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppTheme.accent,
                        isSelected:
                            controller.selectedFilter.value == 'PENDING',
                        onTap: () => controller.setFilter('PENDING'),
                      ),
                      const SizedBox(width: 8),
                      _QuickStat(
                        label: 'تعديلات',
                        value: '${controller.revisionProductsCount}',
                        icon: Icons.edit_note_rounded,
                        color: Colors.amber.shade800,
                        isSelected:
                            controller.selectedFilter.value == 'NEEDS_REVISION',
                        onTap: () => controller.setFilter('NEEDS_REVISION'),
                      ),
                      const SizedBox(width: 8),
                      _QuickStat(
                        label: 'مرفوضة',
                        value: '${controller.rejectedProductsCount}',
                        icon: Icons.cancel_outlined,
                        color: AppTheme.error,
                        isSelected:
                            controller.selectedFilter.value == 'REJECTED',
                        onTap: () => controller.setFilter('REJECTED'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space24),

                  // ── Products Header & Filter Indicator ────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('منتجاتي', style: theme.textTheme.headlineSmall),
                      if (controller.selectedFilter.value != 'ALL')
                        TextButton.icon(
                          onPressed: () => controller.setFilter('ALL'),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('إلغاء التصفية'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space12),

                  if (products.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_rounded,
                              size: 56,
                              color: AppTheme.textHint.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              cnt.myProducts.isEmpty
                                  ? 'لم تقم بإضافة أي منتجات بعد'
                                  : 'لا توجد منتجات مطابقة لهذا الفلتر',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...products.map(
                      (p) => _ProductTile(product: p, theme: theme),
                    ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

// ─── Quick Stat Widget (Interactive Filter Button) ─────────────
class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint('🎯 QuickStat clicked: $label');
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.space12,
            horizontal: 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.12)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : AppTheme.shadowSm,
            border: Border.all(
              color: isSelected
                  ? color
                  : AppTheme.divider.withValues(alpha: 0.5),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isSelected ? color : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Product Tile ────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final dynamic product;
  final ThemeData theme;
  const _ProductTile({required this.product, required this.theme});

  Color _statusColor() {
    switch (product['status']) {
      case 'APPROVED':
        return AppTheme.primary;
      case 'PENDING':
        return AppTheme.accent;
      case 'NEEDS_REVISION':
        return Colors.amber.shade800;
      case 'REJECTED':
      case 'SUSPENDED':
        return AppTheme.error;
      default:
        return AppTheme.textHint;
    }
  }

  String _statusLabel() {
    switch (product['status']) {
      case 'APPROVED':
        return 'مقبول';
      case 'PENDING':
        return 'بالانتظار';
      case 'NEEDS_REVISION':
        return 'طلب تعديل 📝';
      case 'REJECTED':
        return 'مرفوض';
      case 'SUSPENDED':
        return 'موقوف 🚫';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SellerDashboardController>();
    final imageUrl = (product['images'] != null && product['images'].isNotEmpty)
        ? (product['images'][0]['imageUrl'] ?? '')
        : '';

    return InkWell(
      onTap: () => Get.to(
        () => MyProductDetailScreen(
          initialProduct: Map<String, dynamic>.from(product),
        ),
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowSm,
          border: product['status'] == 'REJECTED'
              ? Border.all(color: AppTheme.error.withValues(alpha: 0.3))
              : product['status'] == 'NEEDS_REVISION'
              ? Border.all(color: Colors.amber.withValues(alpha: 0.5))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                AppCachedImage(
                  imageUrl: imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  memCacheWidth: 150,
                  memCacheHeight: 150,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] ?? '',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product['price']} ${product['currency'] ?? 'YER'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor(),
                        ),
                      ),
                    ),
                    if (product['isBoosted'] == true) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'مروّج 🚀',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      product['isAvailable'] == false
                          ? Icons.visibility_off_outlined
                          : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: product['isAvailable'] == false
                          ? AppTheme.error
                          : AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product['isAvailable'] == false
                          ? 'غير متوفر (مخفي للعملاء)'
                          : 'متوفر للبيع في التطبيق',
                      style: TextStyle(
                        fontSize: 12,
                        color: product['isAvailable'] == false
                            ? AppTheme.error
                            : AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Obx(() {
                  final isToggling = controller.isToggling(product['id'] ?? '');
                  if (isToggling) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  }
                  return Switch.adaptive(
                    value: product['isAvailable'] != false,
                    activeTrackColor: AppTheme.primary,
                    activeThumbColor: Colors.white,
                    onChanged: (val) {
                      controller.toggleAvailability(product['id']);
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'عرض التفاصيل والتقييمات',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textHint,
                ),
              ],
            ),
            if (product['status'] == 'NEEDS_REVISION' &&
                product['revisionReason'] != null) ...[
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'ملاحظات التعديل: ${product['revisionReason']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.amber.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(
                          () => EditProductScreen(
                            product: Map<String, dynamic>.from(product),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('تعديل وإعادة تقديم'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (product['status'] == 'REJECTED' &&
                product['rejectionReason'] != null) ...[
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: AppTheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'سبب الرفض: ${product['rejectionReason']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Get.to(
                          () => EditProductScreen(
                            product: Map<String, dynamic>.from(product),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('تعديل وإعادة التقديم للمراجعة'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Add Product Screen
// ═══════════════════════════════════════════════════════════════════
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(AddProductController());
    final dataController = Get.find<DataController>();

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload area
              if (controller.images.isEmpty)
                GestureDetector(
                  onTap: () => controller.pickImages(),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: context.colors.divider, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 48,
                          color: context.colors.textHint,
                        ),
                        const SizedBox(height: AppTheme.space8),
                        Text(
                          'أضف صور المنتج (حتى 5 صور)',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.images.length < 5
                        ? controller.images.length + 1
                        : 5,
                    itemBuilder: (ctx, i) {
                      if (i == controller.images.length) {
                        return GestureDetector(
                          onTap: () => controller.pickImages(),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              border: Border.all(color: context.colors.divider),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: context.colors.textHint,
                                size: 32,
                              ),
                            ),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                              image: DecorationImage(
                                image: FileImage(controller.images[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppTheme.space24),

              _FormField(
                label: 'اسم المنتج *',
                hint: 'مثال: كيكة شوكولاتة فاخرة',
                controller: controller.titleController,
              ),
              const SizedBox(height: AppTheme.space16),
              _FormField(
                label: 'الوصف',
                hint: 'صف المنتج بالتفصيل...',
                maxLines: 4,
                controller: controller.descriptionController,
              ),
              const SizedBox(height: AppTheme.space16),

              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      label: 'السعر *',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      controller: controller.priceController,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وحدة البيع', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppTheme.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            border: Border.all(color: context.colors.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Obx(() {
                              final availableUnits = controller.units;
                              if (!availableUnits.contains(
                                    controller.selectedUnit.value,
                                  ) &&
                                  availableUnits.isNotEmpty) {
                                controller.selectedUnit.value =
                                    availableUnits.first;
                              }
                              return DropdownButton<String>(
                                dropdownColor: context.colors.surface,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: context.colors.textPrimary,
                                ),
                                isExpanded: true,
                                menuMaxHeight: 250,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                value: controller.selectedUnit.value,
                                items: availableUnits
                                    .map(
                                      (u) => DropdownMenuItem<String>(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.selectedUnit.value = val;
                                  }
                                },
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),

              Text('القسم الرئيسي *', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: context.colors.surface,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: controller.selectedCategoryId.value.isEmpty
                        ? null
                        : controller.selectedCategoryId.value,
                    hint: Text(
                      'اختر القسم',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textHint,
                      ),
                    ),
                    items: dataController.categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(
                              c['nameAr'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      controller.selectedCategoryId.value = val!;
                      controller.selectedSubCategoryId.value = '';
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              if (controller.selectedCategoryId.value.isNotEmpty) ...[
                Obx(() {
                  final parentCat = dataController.categories.firstWhere(
                    (c) => c['id'] == controller.selectedCategoryId.value,
                    orElse: () => null,
                  );
                  if (parentCat == null ||
                      parentCat['children'] == null ||
                      parentCat['children'].isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'القسم الفرعي (اختياري)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTheme.space8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                          border: Border.all(color: context.colors.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: context.colors.surface,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textPrimary,
                            ),
                            isExpanded: true,
                            menuMaxHeight: 250,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMd,
                            ),
                            value:
                                controller.selectedSubCategoryId.value.isEmpty
                                ? null
                                : controller.selectedSubCategoryId.value,
                            hint: Text(
                              'بدون قسم فرعي',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: context.colors.textHint,
                              ),
                            ),
                            items: (parentCat['children'] as List<dynamic>)
                                .map(
                                  (c) => DropdownMenuItem<String>(
                                    value: c['id'],
                                    child: Text(
                                      c['nameAr'],
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedSubCategoryId.value = val;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                    ],
                  );
                }),
              ],

              Text('العملة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: context.colors.surface,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: controller.selectedCurrency.value,
                    items: controller.currencies
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(
                              c,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        controller.selectedCurrency.value = val!,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => controller.submitProduct(),
                  child: const Text('إرسال للمراجعة'),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],
          ),
        );
      }),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  const _FormField({
    required this.label,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Edit Business Profile Screen
// ═══════════════════════════════════════════════════════════════════
class EditBusinessScreen extends StatefulWidget {
  final dynamic businessData;
  const EditBusinessScreen({super.key, this.businessData});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  final dataController = Get.find<DataController>();

  File? _newLogoFile;
  String? _currentLogoUrl;
  String _selectedGovId = '';
  String _selectedCityId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.businessData ?? {};
    nameController = TextEditingController(text: b['businessName'] ?? '');
    descController = TextEditingController(text: b['description'] ?? '');

    // Format phone: if it has +967, strip it, else use as is
    String phone = b['contactPhone'] ?? '';
    if (phone.startsWith('+967')) {
      phone = phone.substring(4);
    }
    phoneController = TextEditingController(text: phone);
    addressController = TextEditingController(text: b['addressDetails'] ?? '');
    _currentLogoUrl = b['logoUrl'];

    // Initialize governorate and city from existing data
    if (b['city'] != null) {
      _selectedCityId = b['city']['id'] ?? '';
      // Find the governorate that contains this city
      for (var gov in dataController.locations) {
        final cities = gov['cities'] as List<dynamic>? ?? [];
        for (var city in cities) {
          if (city['id'] == _selectedCityId) {
            _selectedGovId = gov['id'] ?? '';
            break;
          }
        }
        if (_selectedGovId.isNotEmpty) break;
      }
    }

    // Fetch locations if not already loaded
    if (dataController.locations.isEmpty) {
      dataController.fetchLocations();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (picked != null) {
      setState(() {
        _newLogoFile = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar(
        'خطأ',
        'يرجى تعبئة الحقول المطلوبة',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final formattedPhone = '+967${phoneController.text.trim()}';

      final formData = dio.FormData.fromMap({
        'businessName': nameController.text.trim(),
        'description': descController.text.trim(),
        'contactPhone': formattedPhone,
        'addressDetails': addressController.text.trim(),
        if (_selectedCityId.isNotEmpty) 'cityId': _selectedCityId,
      });

      if (_newLogoFile != null) {
        final compressedLogo = await ImageCompressor.compressFile(
          _newLogoFile!,
        );
        formData.files.add(
          MapEntry(
            'logo',
            await dio.MultipartFile.fromFile(
              compressedLogo.path,
              filename: 'logo.jpg',
            ),
          ),
        );
      }

      final response = await DataService.updateMyBusiness(formData);
      if (response['success'] == true) {
        // Refresh the seller dashboard
        if (Get.isRegistered<SellerDashboardController>()) {
          Get.find<SellerDashboardController>().fetchDashboardData();
        }
        // Refresh auth profile
        Get.find<AuthController>().fetchProfile();
        // Refresh stores list on home
        dataController.fetchTopStores();

        Get.back();
        Get.snackbar(
          'تم بنجاح',
          'تم تحديث بيانات المتجر',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar(
        'خطأ في التحديث',
        errorMsg,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    if (_newLogoFile != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primarySurface,
                        backgroundImage: FileImage(_newLogoFile!),
                      )
                    else
                      AppCachedAvatar(
                        imageUrl: _currentLogoUrl,
                        radius: 50,
                        backgroundColor: AppTheme.primarySurface,
                        fallbackIcon: Icons.storefront_rounded,
                        iconColor: AppTheme.primary,
                        iconSize: 40,
                      ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Center(
              child: Text(
                'اضغط لتغيير شعار المتجر',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textHint,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            _FormField(
              label: 'اسم المتجر',
              hint: 'مطبخ أم محمد',
              controller: nameController,
            ),
            const SizedBox(height: AppTheme.space16),
            _FormField(
              label: 'الوصف',
              hint: 'نبذة عن متجرك...',
              maxLines: 3,
              controller: descController,
            ),
            const SizedBox(height: AppTheme.space16),

            Text(
              'رقم التواصل (واتساب) *',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.space8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: '7XX XXX XXX',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(
                    '+967',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: 0,
                  minHeight: 0,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space16),

            _FormField(
              label: 'تفاصيل العنوان',
              hint: 'شارع، حي، بجانب...',
              maxLines: 2,
              controller: addressController,
            ),
            const SizedBox(height: AppTheme.space16),

            // Governorate dropdown
            Text('المحافظة', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.space8),
            Obx(() {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    dropdownColor: context.colors.surface,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: context.colors.textPrimary,
                    ),
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: _selectedGovId.isEmpty ? null : _selectedGovId,
                    hint: Text(
                      'اختر المحافظة',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textHint,
                      ),
                    ),
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.textHint,
                    ),
                    items: dataController.locations
                        .map<DropdownMenuItem<String>>((gov) {
                          return DropdownMenuItem<String>(
                            value: gov['id'],
                            child: Text(
                              gov['nameAr'],
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: context.colors.textPrimary,
                              ),
                            ),
                          );
                        })
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGovId = val;
                          _selectedCityId = ''; // reset city
                        });
                      }
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: AppTheme.space16),

            // City dropdown (only show when governorate is selected)
            if (_selectedGovId.isNotEmpty) ...[
              Text('المدينة / المديرية', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Obx(() {
                final gov = dataController.locations.firstWhere(
                  (g) => g['id'] == _selectedGovId,
                  orElse: () => null,
                );
                final cities =
                    (gov != null ? gov['cities'] as List<dynamic>? : null) ??
                    [];

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space16,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      dropdownColor: context.colors.surface,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: context.colors.textPrimary,
                      ),
                      isExpanded: true,
                      menuMaxHeight: 250,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      value: _selectedCityId.isEmpty ? null : _selectedCityId,
                      hint: Text(
                        'اختر المدينة',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: context.colors.textHint,
                        ),
                      ),
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.colors.textHint,
                      ),
                      items: cities.map<DropdownMenuItem<String>>((city) {
                        return DropdownMenuItem<String>(
                          value: city['id'],
                          child: Text(
                            city['nameAr'],
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCityId = val;
                          });
                        }
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppTheme.space16),
            ],

            const SizedBox(height: AppTheme.space16),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('حفظ التغييرات'),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }
}
