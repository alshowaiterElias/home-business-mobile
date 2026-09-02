import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../core/network/data_service.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({super.key});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  late Category _category;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _category = Get.arguments as Category? ?? Category(id: '', nameAr: 'المنتجات', icon: Icons.category, color: Colors.blue);
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final data = await DataService.getProducts(categoryId: _category.id);
      if (mounted) {
        setState(() {
          _products = data.map((json) => Product.fromJson(json)).toList();
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_category.nameAr),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: context.colors.background,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.inventory_2_outlined,
                            size: 44, color: context.colors.textHint),
                      ),
                      const SizedBox(height: AppTheme.space24),
                      Text('لا توجد منتجات',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: AppTheme.space8),
                      Text('لم يتم إضافة منتجات في هذا القسم بعد',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.space16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.60,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: _products[index],
                    heroTagPrefix: 'cat_prod_',
                  ),
                ),
    );
  }
}
