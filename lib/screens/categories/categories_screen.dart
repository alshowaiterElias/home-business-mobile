import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../controllers/data_controller.dart';


class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأقسام والتصنيفات'),
        centerTitle: true,
      ),
      body: Obx(() {
        final dataController = Get.find<DataController>();
        if (dataController.isLoadingCategories.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final categories = dataController.categories;
        if (categories.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.category_outlined, size: 64, color: AppTheme.textHint.withValues(alpha: 0.5)),
                const SizedBox(height: AppTheme.space16),
                Text('لا توجد أقسام متاحة حالياً', style: theme.textTheme.titleMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16,
            AppTheme.space12,
            AppTheme.space16,
            AppTheme.space32,
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

// ─── Category Card with Expandable Submenu ───────────────────────
class _CategoryCard extends StatefulWidget {
  final Category category;
  const _CategoryCard({required this.category});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = widget.category;
    final hasChildren = category.children.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _isExpanded
              ? category.color.withValues(alpha: 0.3)
              : AppTheme.divider.withValues(alpha: 0.5),
          width: _isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          // Main Category Header Tile
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              onTap: () {
                if (hasChildren) {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                } else {
                  Get.toNamed('/category-products', arguments: category);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space16),
                child: Row(
                  children: [
                    // Icon Container with Soft Glow
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            category.color.withValues(alpha: 0.18),
                            category.color.withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: category.color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space16),

                    // Category Name & Product Count
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.nameAr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                ),
                                child: Text(
                                  '${category.productCount} منتج',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              if (hasChildren) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '• ${category.children.length} أقسام فرعية',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: category.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Chevron / Arrow
                    if (hasChildren)
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isExpanded
                                ? category.color.withValues(alpha: 0.12)
                                : AppTheme.background,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 22,
                            color: _isExpanded ? category.color : AppTheme.textHint,
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: AppTheme.textHint,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Subcategories Collapsible Submenu
          if (hasChildren)
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space16,
                      AppTheme.space12,
                      AppTheme.space16,
                      AppTheme.space16,
                    ),
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.02),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // View All Category Products Banner Button
                        InkWell(
                          onTap: () {
                            Get.toNamed('/category-products', arguments: category);
                          },
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            margin: const EdgeInsets.only(bottom: AppTheme.space12),
                            decoration: BoxDecoration(
                              color: category.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: category.color.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.grid_view_rounded, size: 16, color: category.color),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'عرض جميع منتجات ${category.nameAr}',
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: category.color,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: category.color),
                              ],
                            ),
                          ),
                        ),

                        // Subcategory Chips
                        Wrap(
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
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                  border: Border.all(
                                    color: sub.color.withValues(alpha: 0.3),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: sub.color.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(sub.icon, size: 15, color: sub.color),
                                    const SizedBox(width: 6),
                                    Text(
                                      sub.productCount > 0 ? '${sub.nameAr} (${sub.productCount})' : sub.nameAr,
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: sub.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
        ],
      ),
    );
  }
}
