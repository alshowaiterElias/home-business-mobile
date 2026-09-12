import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/collection_service.dart';
import 'create_collection_screen.dart';
import 'edit_collection_items_screen.dart';
import '../../widgets/app_cached_image.dart';

class ManageCollectionsScreen extends StatefulWidget {
  const ManageCollectionsScreen({super.key});

  @override
  State<ManageCollectionsScreen> createState() =>
      _ManageCollectionsScreenState();
}

class _ManageCollectionsScreenState extends State<ManageCollectionsScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  List<dynamic> _collections = [];

  @override
  void initState() {
    super.initState();
    final cached = CollectionService.cachedMyCollections;
    if (cached != null && cached.isNotEmpty) {
      _collections = cached;
      _isLoading = false;
      // Stale data is shown immediately without full-screen loading
    } else {
      _fetchCollections();
    }
  }

  Future<void> _fetchCollections({bool forceRefresh = false}) async {
    if (_collections.isEmpty) {
      setState(() => _isLoading = true);
    } else {
      setState(() => _isRefreshing = true);
    }
    try {
      final list = await CollectionService.getMyCollections(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _collections = list;
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _deleteCollection(String id) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          'حذف المجموعة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف هذه المجموعة؟ لن يتم حذف المنتجات الأصلية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Get.back(result: true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await CollectionService.deleteCollection(id);
        Get.snackbar(
          'تم',
          'تم حذف المجموعة بنجاح',
          backgroundColor: Colors.black87,
          colorText: Colors.white,
        );
        _fetchCollections(forceRefresh: true);
      } catch (e) {
        Get.snackbar(
          'خطأ',
          'تعذر حذف المجموعة: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: const Text(
          'مجموعات المنتجات 🎨',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_isRefreshing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
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
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _fetchCollections(forceRefresh: true),
              tooltip: 'تحديث البيانات',
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'إنشاء مجموعة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final created = await Get.to(() => const CreateCollectionScreen());
          if (created == true) _fetchCollections(forceRefresh: true);
        },
      ),
      body: (_isLoading && _collections.isEmpty)
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: () => _fetchCollections(forceRefresh: true),
              color: AppTheme.primary,
              child: _collections.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.collections_bookmark_rounded,
                                size: 54,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'لا توجد مجموعات بعد',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'المجموعات تتيح لك تنسيق تشكيلات مميزة (كتالوج) مثل: تشكيلة العيد، هدايا التخرج، أو عروض نهاية الأسبوع.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('أنشئ أول مجموعة لك'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final created = await Get.to(
                                  () => const CreateCollectionScreen(),
                                );
                                if (created == true) _fetchCollections();
                              },
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      itemCount: _collections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final c = _collections[index] as Map<String, dynamic>;
                        return _buildCollectionSellerCard(context, c, theme);
                      },
                    ),
            ),
    );
  }

  Widget _buildCollectionSellerCard(
    BuildContext context,
    Map<String, dynamic> c,
    ThemeData theme,
  ) {
    final title = c['title']?.toString() ?? 'مجموعة';
    final desc = c['description']?.toString() ?? '';
    final cover = c['coverUrl']?.toString() ?? '';
    final fullCover = cover.isNotEmpty ? ApiClient.getImageUrl(cover) : '';
    final itemsCount =
        c['_count']?['items'] as int? ??
        (c['items'] as List<dynamic>?)?.length ??
        0;
    final isActive = c['isActive'] == true;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover Banner ──
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusLg),
            ),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fullCover.isNotEmpty)
                    AppCachedImage(imageUrl: fullCover)
                  else
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.collections_bookmark_rounded,
                          color: Colors.white24,
                          size: 40,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        '$itemsCount منتجات',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Details & Actions ──
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (!isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'مخفية',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      onPressed: () => _deleteCollection(c['id']),
                      tooltip: 'حذف',
                    ),
                  ],
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          side: BorderSide(color: context.colors.divider),
                        ),
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'تعديل المجموعة',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final result = await Get.to(
                            () => CreateCollectionScreen(initialCollection: c),
                          );
                          if (result == true) {
                            _fetchCollections(forceRefresh: true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        icon: const Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'إدارة المنتجات',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          await Get.to(
                            () => EditCollectionItemsScreen(
                              collectionId: c['id'],
                              collectionTitle: title,
                            ),
                          );
                          _fetchCollections(forceRefresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
