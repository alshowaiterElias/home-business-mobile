import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../controllers/data_controller.dart';

class ProductFilter {
  final String? categoryId;
  final String? governorateId;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  ProductFilter({
    this.categoryId,
    this.governorateId,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });
}

class SearchFilterSheet extends StatefulWidget {
  final ProductFilter initialFilter;
  final Function(ProductFilter filter) onApply;

  const SearchFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  String? _categoryId;
  String? _governorateId;
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  double? _minRating;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.initialFilter.categoryId;
    _governorateId = widget.initialFilter.governorateId;
    _minRating = widget.initialFilter.minRating;
    
    if (widget.initialFilter.minPrice != null) {
      _minPriceController.text = widget.initialFilter.minPrice.toString();
    }
    if (widget.initialFilter.maxPrice != null) {
      _maxPriceController.text = widget.initialFilter.maxPrice.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dataController = Get.find<DataController>();

    // Flatten governorates
    final List<dynamic> allGovernorates = [];
    for (var governorate in dataController.locations) {
      allGovernorates.add({
        'id': governorate['id'],
        'name': governorate['nameAr'],
      });
    }

    // Flatten categories
    final List<dynamic> allCategories = [];
    for (var category in dataController.categories) {
      allCategories.add(category);
      if (category['children'] != null) {
        for (var child in category['children']) {
          allCategories.add({
            'id': child['id'],
            'nameAr': '— ${child['nameAr']}'
          });
        }
      }
    }

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.space24,
        right: AppTheme.space24,
        top: AppTheme.space16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space24,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusXl)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text('تصفية المنتجات', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space24),

            // Category
            Text('القسم', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.space8),
            DropdownButtonFormField<String>(
              initialValue: _categoryId,
              hint: const Text('جميع الأقسام'),
              decoration: _dropdownDeco(),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع الأقسام')),
                ...allCategories.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['nameAr'] ?? ''),
                )),
              ],
              onChanged: (val) => setState(() => _categoryId = val),
            ),
            const SizedBox(height: AppTheme.space16),

            // Governorate
            Text('المحافظة', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.space8),
            DropdownButtonFormField<String>(
              initialValue: _governorateId,
              hint: const Text('جميع المحافظات'),
              decoration: _dropdownDeco(),
              items: [
                const DropdownMenuItem(value: null, child: Text('جميع المحافظات')),
                ...allGovernorates.map((g) => DropdownMenuItem(
                  value: g['id'].toString(),
                  child: Text(g['name'] ?? ''),
                )),
              ],
              onChanged: (val) => setState(() => _governorateId = val),
            ),
            const SizedBox(height: AppTheme.space16),

            // Price Range
            Text('نطاق السعر', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.space8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('من'),
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('إلى'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space16),

            // Rating
            Text('التقييم', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppTheme.space8),
            DropdownButtonFormField<double>(
              initialValue: _minRating,
              hint: const Text('جميع التقييمات'),
              decoration: _dropdownDeco(),
              items: const [
                DropdownMenuItem(value: null, child: Text('جميع التقييمات')),
                DropdownMenuItem(value: 4.0, child: Text('٤ نجوم فما فوق')),
                DropdownMenuItem(value: 3.0, child: Text('٣ نجوم فما فوق')),
                DropdownMenuItem(value: 2.0, child: Text('٢ نجوم فما فوق')),
              ],
              onChanged: (val) => setState(() => _minRating = val),
            ),
            const SizedBox(height: AppTheme.space32),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _categoryId = null;
                        _governorateId = null;
                        _minPriceController.clear();
                        _maxPriceController.clear();
                        _minRating = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('إعادة تعيين'),
                  ),
                ),
                const SizedBox(width: AppTheme.space16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(ProductFilter(
                        categoryId: _categoryId,
                        governorateId: _governorateId,
                        minPrice: double.tryParse(_minPriceController.text),
                        maxPrice: double.tryParse(_maxPriceController.text),
                        minRating: _minRating,
                      ));
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('تطبيق'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDeco() {
    return InputDecoration(
      filled: true,
      fillColor: context.colors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.colors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        borderSide: BorderSide.none,
      ),
    );
  }
}
