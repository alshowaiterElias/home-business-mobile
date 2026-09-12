import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/collection_service.dart';
import '../../controllers/seller_dashboard_controller.dart';
import '../../widgets/app_cached_image.dart';

class EditCollectionItemsScreen extends StatefulWidget {
  final String collectionId;
  final String collectionTitle;

  const EditCollectionItemsScreen({
    super.key,
    required this.collectionId,
    required this.collectionTitle,
  });

  @override
  State<EditCollectionItemsScreen> createState() => _EditCollectionItemsScreenState();
}

class _EditCollectionItemsScreenState extends State<EditCollectionItemsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _items = [];
  final Set<String> _removingProductIds = {};

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    try {
      final detail = await CollectionService.getCollectionById(widget.collectionId);
      if (mounted) {
        final rawItems = (detail['items'] as List<dynamic>?) ?? [];
        setState(() {
          _items = rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeItem(String productId) async {
    setState(() => _removingProductIds.add(productId));
    try {
      await CollectionService.removeItem(widget.collectionId, productId);
      if (mounted) {
        setState(() {
          _removingProductIds.remove(productId);
          _items.removeWhere((item) => item['productId'] == productId || item['product']?['id'] == productId);
        });
      }
      Get.snackbar(
        'تم',
        'تمت إزالة المنتج من المجموعة',
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _removingProductIds.remove(productId));
      }
      Get.snackbar(
        'خطأ',
        'تعذر إزالة المنتج: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    final orderedIds = _items
        .map((e) => (e['productId'] ?? e['product']?['id'])?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    try {
      await CollectionService.reorderItems(widget.collectionId, orderedIds);
    } catch (e) {
      // Revert on failure
      _fetchItems();
    }
  }

  void _showAddProductsSheet() {
    final sellerCtrl = Get.isRegistered<SellerDashboardController>()
        ? Get.find<SellerDashboardController>()
        : null;

    final allProducts = sellerCtrl?.myProducts ?? [];
    // Only approved products that are not already in the collection
    final existingIds = _items
        .map((e) => (e['productId'] ?? e['product']?['id'])?.toString())
        .toSet();

    final availableProducts = allProducts.where((p) {
      final id = p['id']?.toString();
      final status = p['status']?.toString();
      return status == 'APPROVED' && id != null && !existingIds.contains(id);
    }).toList();

    final addingProductIds = <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'إضافة منتجات للمجموعة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Get.back(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (availableProducts.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Text(
                              'جميع منتجاتك المعتمدة مضافة بالفعل أو لا توجد منتجات معتمدة بعد.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            controller: scrollController,
                            itemCount: availableProducts.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final prod = availableProducts[index];
                              final pId = prod['id']?.toString() ?? '';
                              final isAdding = addingProductIds.contains(pId);
                              final images = prod['images'] as List<dynamic>?;
                              final cover = images != null && images.isNotEmpty
                                  ? ApiClient.getImageUrl(images[0]['imageUrl'] ?? '')
                                  : '';

                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  child: SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: cover.isNotEmpty
                                        ? AppCachedImage(imageUrl: cover)
                                        : Container(color: Colors.grey.shade200),
                                  ),
                                ),
                                title: Text(
                                  prod['title'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                subtitle: Text(
                                  '${prod['price'] ?? 0} ر.ي',
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    minimumSize: Size.zero,
                                  ),
                                  onPressed: isAdding
                                      ? null
                                      : () async {
                                          setSheetState(() {
                                            addingProductIds.add(pId);
                                          });
                                          try {
                                            await CollectionService.addItem(widget.collectionId, pId);
                                            Get.back();
                                            _fetchItems();
                                            Get.snackbar(
                                              'تم',
                                              'تمت إضافة المنتج للمجموعة',
                                              backgroundColor: Colors.green,
                                              colorText: Colors.white,
                                            );
                                          } catch (e) {
                                            setSheetState(() {
                                              addingProductIds.remove(pId);
                                            });
                                            Get.snackbar(
                                              'خطأ',
                                              'تعذر الإضافة: $e',
                                              backgroundColor: Colors.red,
                                              colorText: Colors.white,
                                            );
                                          }
                                        },
                                  child: isAdding
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('إضافة', style: TextStyle(fontSize: 12)),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Text(
          widget.collectionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: const Text(
              'إضافة منتجات للمجموعة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: _showAddProductsSheet,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: AppTheme.textHint,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'لا توجد منتجات في هذه المجموعة حتى الآن',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'اضغط على الزر أدناه لإضافة منتجاتك المعتمدة إلى هذه التشكيلة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textHint),
                        ),
                      ],
                    ),
                  ),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  itemCount: _items.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final product = item['product'] as Map<String, dynamic>? ?? {};
                    final images = product['images'] as List<dynamic>?;
                    final cover = images != null && images.isNotEmpty
                        ? ApiClient.getImageUrl(images[0]['imageUrl'] ?? '')
                        : '';
                    final pId = (item['productId'] ?? product['id'])?.toString() ?? '';

                    return Container(
                      key: ValueKey(pId),
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: context.colors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.drag_indicator_rounded, color: AppTheme.textHint),
                          const SizedBox(width: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: cover.isNotEmpty
                                  ? AppCachedImage(imageUrl: cover)
                                  : Container(color: Colors.grey.shade200),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['title'] ?? 'منتج',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${product['price'] ?? 0} ر.ي',
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          if (_removingProductIds.contains(pId))
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.error,
                                ),
                              ),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: AppTheme.error, size: 18),
                              onPressed: _removingProductIds.isNotEmpty ? null : () => _removeItem(pId),
                              tooltip: 'إزالة من المجموعة',
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
