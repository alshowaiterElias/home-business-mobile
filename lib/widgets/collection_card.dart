import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../core/network/api_client.dart';
import '../screens/collections/collection_detail_screen.dart';
import 'app_cached_image.dart';

class CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final double width;
  final double height;

  const CollectionCard({
    super.key,
    required this.collection,
    this.width = 240,
    this.height = 155,
  });

  @override
  Widget build(BuildContext context) {
    final title = collection['title']?.toString() ?? 'مجموعة';
    final coverUrl = collection['coverUrl']?.toString() ?? '';
    final businessName = collection['business']?['businessName']?.toString() ?? '';
    final itemsCount = collection['_count']?['items'] as int? ??
        (collection['items'] as List<dynamic>?)?.length ??
        0;

    final fullCoverUrl = coverUrl.isNotEmpty ? ApiClient.getImageUrl(coverUrl) : '';
    final items = (collection['items'] as List<dynamic>?) ?? [];

    return GestureDetector(
      onTap: () {
        Get.to(() => CollectionDetailScreen(collectionId: collection['id']));
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background Image / Collage ──
              if (fullCoverUrl.isNotEmpty)
                AppCachedImage(imageUrl: fullCoverUrl)
              else if (items.isNotEmpty)
                _buildCollage(items)
              else
                _buildDefaultGradient(title),

              // ── Gradient Overlay for Readability ──
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.2, 0.55, 1.0],
                  ),
                ),
              ),

              // ── Product Count Badge (Top Right) ──
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_mosaic_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$itemsCount منتجات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content (Bottom) ──
              Positioned(
                bottom: 12,
                right: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    if (businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              businessName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollage(List<dynamic> items) {
    final previewUrls = <String>[];
    for (final item in items) {
      final p = item['product'] as Map<String, dynamic>?;
      final imgs = p?['images'] as List<dynamic>?;
      if (imgs != null && imgs.isNotEmpty) {
        final raw = imgs[0]['imageUrl']?.toString() ?? '';
        if (raw.isNotEmpty) previewUrls.add(ApiClient.getImageUrl(raw));
      }
      if (previewUrls.length >= 4) break;
    }

    if (previewUrls.isEmpty) return _buildDefaultGradient('');

    if (previewUrls.length == 1) {
      return AppCachedImage(imageUrl: previewUrls.first);
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1.5,
        mainAxisSpacing: 1.5,
      ),
      itemCount: previewUrls.length.clamp(1, 4),
      itemBuilder: (context, index) {
        return AppCachedImage(imageUrl: previewUrls[index]);
      },
    );
  }

  Widget _buildDefaultGradient(String title) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.collections_bookmark_rounded,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }
}
