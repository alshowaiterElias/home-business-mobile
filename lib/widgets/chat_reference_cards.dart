import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chat_models.dart';
import '../models/dummy_data.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../core/network/data_service.dart';
import '../screens/product/product_details_screen.dart';
import 'verified_badge.dart';
import 'app_cached_image.dart';

/// Compact product card shown inline in chat messages.
class ProductReferenceCard extends StatelessWidget {
  final MessageReference reference;

  const ProductReferenceCard({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    final imageUrl = reference.snapshotImage != null
        ? ApiClient.getImageUrl(reference.snapshotImage!)
        : null;

    return GestureDetector(
      onTap: () async {
        try {
          Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
          final productData = await DataService.getProductById(reference.referenceId);
          Get.back(); // close dialog
          
          final product = Product.fromJson(productData);
          Get.to(() => ProductDetailsScreen(product: product));
        } catch (e) {
          if (Get.isDialogOpen ?? false) Get.back();
          Get.snackbar('خطأ', 'تعذر تحميل تفاصيل المنتج');
        }
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: context.colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Product Image
            if (imageUrl != null)
              AppCachedImage(
                imageUrl: imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusMd)),
              ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reference.snapshotTitle ?? 'منتج',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (reference.snapshotPrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${reference.snapshotPrice} ر.ي',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 14, color: context.colors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'عرض المنتج',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
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
}

/// Compact store card shown inline in chat messages.
class StoreReferenceCard extends StatelessWidget {
  final MessageReference reference;

  const StoreReferenceCard({super.key, required this.reference});

  @override
  Widget build(BuildContext context) {
    final logoUrl = reference.snapshotImage != null
        ? ApiClient.getImageUrl(reference.snapshotImage!)
        : null;

    return GestureDetector(
      onTap: () {
        final storeMap = {
          'id': reference.referenceId,
          'businessName': reference.snapshotTitle,
          'logoUrl': reference.snapshotImage,
          if (reference.snapshotMeta != null) ...reference.snapshotMeta!,
        };
        if (DataService.getCachedBusiness(reference.referenceId) == null) {
          DataService.cacheBusiness(reference.referenceId, storeMap);
        }
        Get.toNamed('/store', arguments: {
          'id': reference.referenceId,
          'businessName': reference.snapshotTitle,
          'store': DataService.getCachedBusiness(reference.referenceId) ?? storeMap,
        });
      },
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: context.colors.divider),
        ),
        child: Row(
          children: [
            AppCachedAvatar(
              imageUrl: logoUrl,
              radius: 22,
              backgroundColor: context.colors.primarySurface,
              fallbackIcon: Icons.storefront_rounded,
              iconColor: context.colors.primary,
              iconSize: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          reference.snapshotTitle ?? 'متجر',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (reference.snapshotMeta?['isVerified'] == true ||
                          reference.snapshotMeta?['is_verified'] == true) ...[
                        const SizedBox(width: 4),
                        const VerifiedBadge(size: 14),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 12, color: context.colors.primary),
                      const SizedBox(width: 3),
                      Text(
                        'عرض المتجر',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w600,
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
}
