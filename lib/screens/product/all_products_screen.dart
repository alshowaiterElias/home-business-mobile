import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../core/network/data_service.dart';
import '../search/widgets/search_filter_sheet.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key});

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  var products = <Product>[];
  var isLoading = true;
  ProductFilter _currentFilter = ProductFilter();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await DataService.getProducts(
        limit: 50,
        categoryId: _currentFilter.categoryId,
        governorateId: _currentFilter.governorateId,
        minPrice: _currentFilter.minPrice,
        maxPrice: _currentFilter.maxPrice,
        minRating: _currentFilter.minRating,
      );
      setState(() {
        products = data.map<Product>((json) => Product.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جميع المنتجات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              Get.bottomSheet(
                SearchFilterSheet(
                  initialFilter: _currentFilter,
                  onApply: (filter) {
                    setState(() {
                      _currentFilter = filter;
                      isLoading = true;
                    });
                    _fetchProducts();
                  },
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text('لا توجد منتجات'))
              : GridView.builder(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      heroTagPrefix: 'all-products-',
                    );
                  },
                ),
    );
  }
}
