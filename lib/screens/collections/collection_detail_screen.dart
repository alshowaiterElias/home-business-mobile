import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/collection_service.dart';
import '../../models/dummy_data.dart';
import '../../widgets/product_card.dart';
import '../../widgets/app_cached_image.dart';
import '../../widgets/verified_badge.dart';

class CollectionDetailScreen extends StatefulWidget {
  final String collectionId;

  const CollectionDetailScreen({super.key, required this.collectionId});

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _collection;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await CollectionService.getCollectionById(widget.collectionId);
      if (mounted) {
        final items = (data['items'] as List<dynamic>?) ?? [];
        final parsed = items.map((item) {
          final pMap = Map<String, dynamic>.from(item['product'] as Map);
          if (data['business'] != null) {
            pMap['business'] = data['business'];
          }
          return Product.fromJson(pMap);
        }).toList();

        setState(() {
          _collection = data;
          _products = parsed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _collection == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.collections_bookmark_outlined,
                        size: 64,
                        color: AppTheme.textHint,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل المجموعة',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchDetail();
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDetail,
                  color: AppTheme.primary,
                  child: CustomScrollView(
                    slivers: [
                      // ── Sliver App Bar with Cover ──
                      _buildSliverAppBar(context),

                      // ── Header Information ──
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                _collection!['title'] ?? 'مجموعة مميزة',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              // Description if available
                              if (_collection!['description'] != null &&
                                  _collection!['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _collection!['description'].toString(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.colors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),

                              // Store info chip
                              if (_collection!['business'] != null)
                                _buildStoreBar(context, _collection!['business']),

                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'منتجات المجموعة (${_products.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Products Grid ──
                      if (_products.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'لا توجد منتجات مضافة لهذه المجموعة حالياً.',
                                style: TextStyle(color: AppTheme.textHint),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                            vertical: 8,
                          ),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                return ProductCard(product: _products[index]);
                              },
                              childCount: _products.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final coverUrl = _collection?['coverUrl']?.toString() ?? '';
    final fullCover = coverUrl.isNotEmpty ? ApiClient.getImageUrl(coverUrl) : '';

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppTheme.primaryDark,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (fullCover.isNotEmpty)
              AppCachedImage(imageUrl: fullCover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.collections_bookmark_rounded,
                    size: 64,
                    color: Colors.white24,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreBar(BuildContext context, Map<String, dynamic> business) {
    final logo = business['logoUrl']?.toString() ?? '';
    final fullLogo = logo.isNotEmpty ? ApiClient.getImageUrl(logo) : '';
    final name = business['businessName']?.toString() ?? 'متجر';
    final isVerified = business['isVerified'] == true;

    return GestureDetector(
      onTap: () {
        Get.toNamed('/store', arguments: {
          'id': business['id'],
          'businessName': name,
          'store': business,
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: context.colors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              child: SizedBox(
                width: 32,
                height: 32,
                child: fullLogo.isNotEmpty
                    ? AppCachedImage(imageUrl: fullLogo)
                    : Container(
                        color: AppTheme.primarySurface,
                        child: const Icon(Icons.store, size: 16, color: AppTheme.primary),
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (isVerified) ...[
                    const SizedBox(width: 4),
                    const VerifiedBadge(size: 14),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppTheme.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
