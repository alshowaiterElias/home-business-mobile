import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/product_details_controller.dart';
import '../../controllers/auth_controller.dart';
import 'product_details_screen.dart'; // To reuse _ReviewCard

class ProductReviewsScreen extends StatelessWidget {
  final String productId;
  final ThemeData theme;

  const ProductReviewsScreen({super.key, required this.productId, required this.theme});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProductDetailsController>(tag: productId);
    final auth = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييمات والآراء'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Obx(() {
          final isLoggedIn = auth.isLoggedIn.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add / Edit Review UI (Same as in ProductDetailsScreen)
              if (isLoggedIn && !controller.isMyProduct.value) ...[
                if (controller.isEditing.value) ...[
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
                          children: List.generate(5, (i) => GestureDetector(
                            onTap: () => controller.currentRating.value = i + 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i < controller.currentRating.value ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 32,
                                color: i < controller.currentRating.value ? AppTheme.accent : AppTheme.textHint,
                              ),
                            ),
                          )),
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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => controller.startEditing(),
                      icon: Icon(controller.myReview.value == null ? Icons.star_outline_rounded : Icons.edit_rounded, size: 20),
                      label: Text(controller.myReview.value == null ? 'أضف تقييماً' : 'تعديل تقييمك'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: const BorderSide(color: AppTheme.primary),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.space24),
              ] else if (!isLoggedIn) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Column(
                    children: [
                      Text('قم بتسجيل الدخول لإضافة تقييم', style: theme.textTheme.bodyMedium),
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

              // All reviews list
              ...controller.reviews.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.space12),
                child: ReviewCard(
                  theme: theme,
                  name: r.name,
                  rating: r.rating,
                  text: r.text ?? '',
                  date: r.date,
                  isMine: r.id == controller.myReview.value?.id,
                  onEdit: r.id == controller.myReview.value?.id ? () => controller.startEditing() : null,
                ),
              )),
              
              if (controller.reviews.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text('لا توجد تقييمات بعد', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textHint)),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
