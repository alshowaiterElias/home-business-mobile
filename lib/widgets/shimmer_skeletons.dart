import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme/app_theme.dart';

/// Base shimmer wrapper that automatically uses theme-tailored base & highlight colors.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.colors.shimmerBase,
      highlightColor: context.colors.shimmerHighlight,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(AppTheme.radiusSm)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. PRODUCT SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton for an individual Product Card (matches ProductCard aspect ratio and structure).
class ProductCardSkeleton extends StatelessWidget {
  final double? width;

  const ProductCardSkeleton({super.key, this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Expanded(
            flex: 3,
            child: ShimmerBox(
              width: double.infinity,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
          // Info skeleton
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.space8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const ShimmerBox(width: double.infinity, height: 13),
                  const ShimmerBox(width: 80, height: 11),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      ShimmerBox(width: 50, height: 14),
                      ShimmerBox(width: 35, height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2-column Product Grid Skeleton (Widget or Sliver).
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final bool isSliver;
  final ScrollPhysics? physics;

  const ProductGridSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppTheme.space16),
    this.isSliver = false,
    this.physics = const NeverScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    final delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.60,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
    );

    if (isSliver) {
      return SliverPadding(
        padding: padding,
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const ProductCardSkeleton(),
            childCount: itemCount,
          ),
          gridDelegate: delegate,
        ),
      );
    }

    return GridView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: true,
      gridDelegate: delegate,
      itemCount: itemCount,
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}

/// Horizontal scroll skeleton for featured products.
class HorizontalProductListSkeleton extends StatelessWidget {
  final int itemCount;
  final double height;

  const HorizontalProductListSkeleton({
    super.key,
    this.itemCount = 3,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space16),
        itemBuilder: (_, __) => const SizedBox(
          width: 170,
          child: ProductCardSkeleton(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. CATEGORY SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal scroll skeleton for categories on HomeScreen.
class HorizontalCategoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const HorizontalCategoryListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space12),
        itemBuilder: (_, __) => Column(
          children: [
            ShimmerBox(
              width: 58,
              height: 58,
              shape: BoxShape.circle,
            ),
            const SizedBox(height: 8),
            const ShimmerBox(width: 50, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Category list skeleton for CategoriesScreen.
class CategoryListSkeleton extends StatelessWidget {
  final int itemCount;

  const CategoryListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space12,
        AppTheme.space16,
        AppTheme.space32,
      ),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const ShimmerBox(
              width: 44,
              height: 44,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14),
                  SizedBox(height: 6),
                  ShimmerBox(width: 180, height: 11),
                ],
              ),
            ),
            const ShimmerBox(width: 20, height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. STORE SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal scroll skeleton for featured stores on HomeScreen.
class HorizontalStoreListSkeleton extends StatelessWidget {
  final int itemCount;

  const HorizontalStoreListSkeleton({super.key, this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 165,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.space12),
        itemBuilder: (_, __) => Container(
          width: 140,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              ShimmerBox(width: 68, height: 68, shape: BoxShape.circle),
              SizedBox(height: AppTheme.space8),
              ShimmerBox(width: 80, height: 13),
              SizedBox(height: 6),
              ShimmerBox(width: 45, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Store list item card skeleton (matches AllStoresScreen & FollowedStores tab).
class StoreCardSkeleton extends StatelessWidget {
  const StoreCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Row(
        children: [
          const ShimmerBox(
            width: 56,
            height: 56,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 130, height: 15),
                SizedBox(height: 8),
                ShimmerBox(width: 90, height: 11),
                SizedBox(height: 6),
                ShimmerBox(width: 60, height: 10),
              ],
            ),
          ),
          const ShimmerBox(width: 24, height: 24),
        ],
      ),
    );
  }
}

/// List of store skeletons.
class StoreListSkeleton extends StatelessWidget {
  final int itemCount;

  const StoreListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space16),
      itemBuilder: (_, __) => const StoreCardSkeleton(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. NOTIFICATION SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton list for NotificationsScreen.
class NotificationListSkeleton extends StatelessWidget {
  final int itemCount;

  const NotificationListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 72, endIndent: 16),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: 44,
              height: 44,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 140, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 12),
                  SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. CHAT & CONVERSATION SKELETONS
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton list for ConversationsScreen.
class ConversationListSkeleton extends StatelessWidget {
  final int itemCount;

  const ConversationListSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, indent: 76, endIndent: 16),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            const ShimmerBox(
              width: 52,
              height: 52,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 120, height: 14),
                  SizedBox(height: 8),
                  ShimmerBox(width: 200, height: 12),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                ShimmerBox(width: 40, height: 10),
                SizedBox(height: 8),
                ShimmerBox(width: 18, height: 18, shape: BoxShape.circle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chat messages list skeleton with alternating natural message bubbles.
class ChatMessageListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatMessageListSkeleton({super.key, this.itemCount = 7});

  @override
  Widget build(BuildContext context) {
    // Alternating widths and alignments to simulate natural chat
    final bubbleConfigs = [
      {'isMe': false, 'width': 190.0, 'height': 48.0},
      {'isMe': true, 'width': 140.0, 'height': 38.0},
      {'isMe': false, 'width': 240.0, 'height': 64.0},
      {'isMe': true, 'width': 210.0, 'height': 52.0},
      {'isMe': false, 'width': 120.0, 'height': 36.0},
      {'isMe': true, 'width': 160.0, 'height': 42.0},
      {'isMe': false, 'width': 220.0, 'height': 56.0},
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space16,
      ),
      itemCount: itemCount.clamp(1, bubbleConfigs.length),
      itemBuilder: (_, index) {
        final config = bubbleConfigs[index];
        final isMe = config['isMe'] as bool;
        final width = config['width'] as double;
        final height = config['height'] as double;

        return Align(
          alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ShimmerBox(
              width: width,
              height: height,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppTheme.radiusMd),
                topRight: const Radius.circular(AppTheme.radiusMd),
                bottomLeft: Radius.circular(isMe ? 2 : AppTheme.radiusMd),
                bottomRight: Radius.circular(isMe ? AppTheme.radiusMd : 2),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. SELLER DASHBOARD SKELETON
// ─────────────────────────────────────────────────────────────────────────────

/// Full skeleton for SellerDashboardScreen (header, metrics, filters, product items).
class SellerDashboardSkeleton extends StatelessWidget {
  const SellerDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space16),
      children: [
        // Business Header Card Skeleton
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const ShimmerBox(width: 56, height: 56, shape: BoxShape.circle),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 140, height: 16),
                    SizedBox(height: 6),
                    ShimmerBox(width: 90, height: 11),
                  ],
                ),
              ),
              const ShimmerBox(width: 32, height: 32, shape: BoxShape.circle),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space16),

        // Metrics Row Skeleton (4 metric boxes)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 50, height: 10),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 50, height: 10),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(width: 50, height: 10),
                    SizedBox(height: 8),
                    ShimmerBox(width: 40, height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),

        // Status Filter Chips Skeleton
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, __) => const ShimmerBox(
              width: 75,
              height: 34,
              borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusFull)),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space16),

        // Products List Skeleton
        ...List.generate(
          3,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: AppTheme.space12),
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: context.colors.divider.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const ShimmerBox(
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.all(Radius.circular(AppTheme.radiusSm)),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(width: 140, height: 14),
                      SizedBox(height: 6),
                      ShimmerBox(width: 70, height: 12),
                      SizedBox(height: 6),
                      ShimmerBox(width: 50, height: 10),
                    ],
                  ),
                ),
                const ShimmerBox(width: 28, height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
