import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_business_mobile/core/network/data_service.dart';
import 'package:home_business_mobile/models/ai_models.dart';
import 'package:home_business_mobile/models/dummy_data.dart';
import 'package:home_business_mobile/widgets/product_card.dart';
import 'package:home_business_mobile/widgets/verified_badge.dart';

class AiBlockRenderer extends StatelessWidget {
  final AiBlock block;

  const AiBlockRenderer({Key? key, required this.block}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (block.type == 'product' && block.productId != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: CachedProductBlockCard(
            key: ValueKey('ai-product-${block.productId}'),
            productId: block.productId!,
            initialProductData: block.productData,
          ),
        ),
      );
    } else if (block.type == 'store' && block.storeId != null) {
      return CachedStoreBlockCard(
        key: ValueKey('ai-store-${block.storeId}'),
        storeId: block.storeId!,
      );
    } else if (block.type == 'comparison' && block.productIds != null && block.productIds!.isNotEmpty) {
      return _buildComparisonBlock(block.productIds!);
    }
    return const SizedBox.shrink();
  }

  Widget _buildComparisonBlock(List<String> productIds) {
    return SizedBox(
      height: 245,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: productIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => CachedProductBlockCard(
          key: ValueKey('ai-comparison-${productIds[index]}'),
          productId: productIds[index],
        ),
      ),
    );
  }
}

/// Dedicated Stateful Product Card with AutomaticKeepAlive & synchronous preloaded data
/// to eliminate network requests, rebuild loops, and image flickering.
class CachedProductBlockCard extends StatefulWidget {
  final String productId;
  final Map<String, dynamic>? initialProductData;

  const CachedProductBlockCard({
    Key? key,
    required this.productId,
    this.initialProductData,
  }) : super(key: key);

  @override
  State<CachedProductBlockCard> createState() => _CachedProductBlockCardState();
}

class _CachedProductBlockCardState extends State<CachedProductBlockCard>
    with AutomaticKeepAliveClientMixin {
  Product? _cachedProduct;
  Future<Map<String, dynamic>>? _productFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initProduct();
  }

  void _initProduct() {
    if (widget.initialProductData != null) {
      try {
        _cachedProduct = Product.fromJson(widget.initialProductData!);
      } catch (e) {
        _cachedProduct = null;
      }
    }
    if (_cachedProduct == null) {
      _productFuture = DataService.getProductById(widget.productId);
    }
  }

  @override
  void didUpdateWidget(covariant CachedProductBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId ||
        oldWidget.initialProductData != widget.initialProductData) {
      _initProduct();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 1. If we have preloaded synchronous product data, render immediately with 0 delay!
    if (_cachedProduct != null) {
      return SizedBox(
        width: 175,
        height: 240,
        child: ProductCard(
          product: _cachedProduct!,
          heroTagPrefix: 'ai-${_cachedProduct!.id}-',
        ),
      );
    }

    // 2. Fallback to asynchronous fetch if not preloaded in block
    return FutureBuilder<Map<String, dynamic>>(
      future: _productFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 175,
            height: 240,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            width: 175,
            height: 100,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Center(
                  child: Text(
                    'هذا المنتج غير متاح حالياً',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }

        try {
          final product = Product.fromJson(snapshot.data!);
          return SizedBox(
            width: 175,
            height: 240,
            child: ProductCard(
              product: product,
              heroTagPrefix: 'ai-${product.id}-',
            ),
          );
        } catch (e) {
          return const SizedBox(
            width: 175,
            height: 100,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    'عذرًا، حدث خطأ في عرض المنتج',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }
}

/// Dedicated Stateful Store Block with AutomaticKeepAlive
class CachedStoreBlockCard extends StatefulWidget {
  final String storeId;

  const CachedStoreBlockCard({
    Key? key,
    required this.storeId,
  }) : super(key: key);

  @override
  State<CachedStoreBlockCard> createState() => _CachedStoreBlockCardState();
}

class _CachedStoreBlockCardState extends State<CachedStoreBlockCard>
    with AutomaticKeepAliveClientMixin {
  late Future<Map<String, dynamic>> _storeFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _storeFuture = DataService.getBusinessById(widget.storeId);
  }

  @override
  void didUpdateWidget(covariant CachedStoreBlockCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storeId != widget.storeId) {
      _storeFuture = DataService.getBusinessById(widget.storeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: _storeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('هذا المتجر غير متاح حالياً', style: TextStyle(color: Colors.red)),
            ),
          );
        }

        final store = snapshot.data!;
        final isVerified = store['isVerified'] == true || store['is_verified'] == true;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.storefront, color: Colors.blue),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    store['businessName'] ?? 'متجر',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 4),
                  const VerifiedBadge(size: 16),
                ],
              ],
            ),
            subtitle: Text(store['city']?['nameAr'] ?? ''),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              DataService.cacheBusiness(widget.storeId, store);
              Get.toNamed('/store', arguments: {
                'id': widget.storeId,
                'store': store,
                'businessName': store['businessName'],
              });
            },
          ),
        );
      },
    );
  }
}
