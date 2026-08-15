import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dummy_data.dart';
import '../../widgets/product_card.dart';
import '../../core/network/data_service.dart';
import '../../core/network/storage_service.dart';
import '../../controllers/data_controller.dart';
import 'widgets/search_filter_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  var _results = <Product>[];
  bool _hasSearched = false;
  bool _isLoading = false;
  ProductFilter _currentFilter = ProductFilter();

  var _recentSearches = <String>[];

  @override
  void initState() {
    super.initState();
    _recentSearches = StorageService.getRecentSearches();
  }

  Future<void> _search(String query) async {
    setState(() {
      _hasSearched = true;
      _isLoading = true;
    });

    if (query.isNotEmpty) {
      await StorageService.saveRecentSearch(query);
      _recentSearches = StorageService.getRecentSearches();
    }

    try {
      final data = await DataService.getProducts(
        search: query.isNotEmpty ? query : null,
        categoryId: _currentFilter.categoryId,
        governorateId: _currentFilter.governorateId,
        minPrice: _currentFilter.minPrice,
        maxPrice: _currentFilter.maxPrice,
        minRating: _currentFilter.minRating,
      );
      setState(() {
        _results = data.map<Product>((json) => Product.fromJson(json)).toList();
      });
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ أثناء البحث',
          backgroundColor: AppTheme.error, colorText: Colors.white);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openFilters() {
    Get.bottomSheet(
      SearchFilterSheet(
        initialFilter: _currentFilter,
        onApply: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _search(_searchController.text);
        },
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onSubmitted: _search,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'ابحث عن منتج، متجر أو قسم...',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _hasSearched = false;
                        _results.clear();
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  onPressed: _openFilters,
                ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
      body: _hasSearched ? _buildResults(theme) : _buildSuggestions(theme),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    final dataController = Get.find<DataController>();
    final categories = dataController.categories;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.space16),
      children: [
        if (_recentSearches.isNotEmpty) ...[
          // Recent Searches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('عمليات البحث الأخيرة', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  StorageService.clearRecentSearches();
                  setState(() => _recentSearches.clear());
                },
                child: Text('مسح الكل', style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.error)),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space8),
          Wrap(
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: _recentSearches.map((query) => ActionChip(
              label: Text(query, style: theme.textTheme.bodyMedium),
              backgroundColor: AppTheme.background,
              side: const BorderSide(color: AppTheme.divider),
              onPressed: () {
                _searchController.text = query;
                _search(query);
              },
            )).toList(),
          ),
          const SizedBox(height: AppTheme.space32),
        ],

        // Popular Categories
        if (categories.isNotEmpty) ...[
          Text('استكشف الأقسام', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.space16),
          Wrap(
            spacing: AppTheme.space12,
            runSpacing: AppTheme.space12,
            children: categories.take(6).map((cat) {
              final name = cat['nameAr'] ?? '';
              final id = cat['id'].toString();
              return ActionChip(
                label: Text(name),
                backgroundColor: AppTheme.primarySurface.withOpacity(0.3),
                side: BorderSide.none,
                labelStyle: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.primary),
                onPressed: () {
                  _currentFilter = ProductFilter(categoryId: id);
                  _searchController.clear();
                  _search('');
                },
              );
            }).toList(),
          ),
        ]
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 44, color: AppTheme.textHint),
            ),
            const SizedBox(height: AppTheme.space24),
            Text('لا توجد نتائج', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTheme.space8),
            Text('جرّب البحث بكلمات مختلفة',
                style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space16, AppTheme.space12,
            AppTheme.space16, AppTheme.space4,
          ),
          child: Text('${_results.length} نتيجة',
              style: theme.textTheme.bodyMedium),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.space16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.60,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _results.length,
            itemBuilder: (_, i) => ProductCard(
              product: _results[i],
              heroTagPrefix: 'search-',
            ),
          ),
        ),
      ],
    );
  }
}
