import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../core/network/api_client.dart';
import '../search/widgets/store_filter_sheet.dart';

class AllStoresScreen extends StatefulWidget {
  const AllStoresScreen({super.key});

  @override
  State<AllStoresScreen> createState() => _AllStoresScreenState();
}

class _AllStoresScreenState extends State<AllStoresScreen> {
  final _searchController = TextEditingController();
  final _stores = <dynamic>[].obs;
  final _isLoading = false.obs;

  String? _selectedGovernorateId;

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    _isLoading.value = true;
    try {
      final data = await DataService.getBusinesses(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        governorateId: _selectedGovernorateId,
      );
      _stores.assignAll(data);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء جلب المتاجر',
          backgroundColor: AppTheme.error, colorText: Colors.white);
    } finally {
      _isLoading.value = false;
    }
  }

  void _openFilters() {
    Get.bottomSheet(
      StoreFilterSheet(
        initialGovernorateId: _selectedGovernorateId,
        onApply: (governorateId) {
          _selectedGovernorateId = governorateId;
          _fetchStores();
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع المتاجر'),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _fetchStores(),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن متجر...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: context.colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(color: context.colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: BorderSide(color: context.colors.divider),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                GestureDetector(
                  onTap: _openFilters,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (_selectedGovernorateId != null) ? AppTheme.primary : context.colors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: (_selectedGovernorateId != null) ? AppTheme.primary : context.colors.divider),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: (_selectedGovernorateId != null) ? Colors.white : context.colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Obx(() {
              if (_isLoading.value && _stores.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_stores.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.storefront_rounded, size: 64, color: context.colors.divider),
                      const SizedBox(height: 16),
                      Text('لا توجد متاجر تطابق بحثك', style: theme.textTheme.titleMedium?.copyWith(color: context.colors.textHint)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _fetchStores,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.space16),
                  itemCount: _stores.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppTheme.space16),
                  itemBuilder: (_, index) {
                    final store = _stores[index];
                    final id = store['id'];
                    final name = store['businessName'] ?? '';
                    final logoUrl = store['logoUrl'];
                    final city = store['city']?['name'] ?? '';

                    // Calculate store rating
                    double totalRating = 0;
                    int ratedCount = 0;
                    if (store['products'] != null) {
                      for (var p in store['products']) {
                        final rating = double.tryParse(p['averageRating']?.toString() ?? '0') ?? 0.0;
                        if (rating > 0) {
                          totalRating += rating;
                          ratedCount++;
                        }
                      }
                    }
                    final ratingStr = ratedCount > 0 ? (totalRating / ratedCount).toStringAsFixed(1) : '0.0';

                    return GestureDetector(
                      onTap: () => Get.toNamed('/store', arguments: {'id': id}),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space12),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: context.colors.shadowSm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: context.colors.background,
                              backgroundImage: logoUrl != null ? NetworkImage(ApiClient.getImageUrl(logoUrl)) : null,
                              child: logoUrl == null ? Icon(Icons.storefront_rounded, size: 28, color: context.colors.textHint) : null,
                            ),
                            const SizedBox(width: AppTheme.space16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: context.colors.textHint),
                                      const SizedBox(width: 4),
                                      Text(city, style: theme.textTheme.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 4),
                                Text(ratingStr, style: theme.textTheme.titleSmall),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
