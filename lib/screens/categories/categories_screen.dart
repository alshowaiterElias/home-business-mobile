import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/data_controller.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الأقسام')),
      body: Obx(() {
        final dataController = Get.find<DataController>();
        if (dataController.isLoadingCategories.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = dataController.categories;
        if (categories.isEmpty) {
          return const Center(child: Text('لا توجد أقسام'));
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16, AppTheme.space8,
            AppTheme.space16, AppTheme.space24,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final catData = categories[index];
            final cat = Category.fromJson(catData);
            return _CategoryCard(category: cat);
          },
        );
      }),
    );
  }
}

// ─── Category Card ───────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = category.children.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space12),
      child: Material(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          onTap: () {
            Get.toNamed('/category-products', arguments: category);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                // Main category row
                Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Row(
                    children: [
                      // Icon container
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Icon(category.icon,
                            color: category.color, size: 26),
                      ),
                      const SizedBox(width: AppTheme.space16),

                      // Name + count
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.nameAr,
                                style: theme.textTheme.titleLarge),
                            const SizedBox(height: 2),
                            Text(
                              '${category.productCount} منتج',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),

                      // Arrow or expand
                      Icon(
                        hasChildren
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.arrow_forward_ios_rounded,
                        size: hasChildren ? 24 : 16,
                        color: AppTheme.textHint,
                      ),
                    ],
                  ),
                ),

                // Subcategories — if present
                if (hasChildren) ...[
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16, AppTheme.space12,
                      AppTheme.space16, AppTheme.space16,
                    ),
                    child: Wrap(
                      spacing: AppTheme.space8,
                      runSpacing: AppTheme.space8,
                      children: category.children.map((sub) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          onTap: () {
                            Get.toNamed('/category-products', arguments: sub);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sub.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                              border: Border.all(
                                color: sub.color.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(sub.icon,
                                    size: 15, color: sub.color),
                                const SizedBox(width: 6),
                                Text(
                                  sub.nameAr,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: sub.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
