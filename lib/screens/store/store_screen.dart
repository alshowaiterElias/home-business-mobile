import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/report_sheet.dart';
import '../../core/network/data_service.dart';
import '../../core/network/whatsapp_service.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _businessData;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchBusinessData();
  }

  Future<void> _fetchBusinessData() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final businessId = args?['id'] as String? ?? '';

    if (businessId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await DataService.getBusinessById(businessId);
      final productsData = data['products'] as List<dynamic>? ?? [];

      if (mounted) {
        setState(() {
          _businessData = data;
          _products = productsData.map((p) {
            final productMap = Map<String, dynamic>.from(p);
            productMap['business'] = data;
            return Product.fromJson(productMap);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final businessName = _businessData?['businessName'] ?? 'متجر غير معروف';
    final location = _businessData?['city']?['nameAr'] ?? 'غير محدد';
    final activeSince = _businessData?['createdAt'] != null
        ? DateTime.parse(_businessData!['createdAt']).year.toString()
        : '٢٠٢٤';

    double totalRating = 0;
    int ratedCount = 0;
    for (var p in _products) {
      if (p.rating > 0) {
        totalRating += p.rating;
        ratedCount++;
      }
    }
    final storeRating = ratedCount > 0
        ? (totalRating / ratedCount).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchBusinessData,
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppTheme.surface,
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: Colors.white),
                  onPressed: () {
                    if (_businessData != null) {
                      WhatsAppService.shareStore(_businessData!, _products.length);
                    }
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.primary],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.storefront_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          businessName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Stats
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.space16),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'المنتجات', value: '${_products.length}'),
                    Container(width: 1, height: 30, color: AppTheme.divider),
                    _Stat(label: 'التقييم', value: storeRating),
                    Container(width: 1, height: 30, color: AppTheme.divider),
                    _Stat(label: 'منذ', value: activeSince),
                  ],
                ),
              ),
            ),
            // Contact
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final phone = _businessData?['contactPhone'] ?? '';
                          if (phone.isEmpty) {
                            Get.snackbar('تنبيه', 'رقم هاتف المتجر غير متوفر',
                                backgroundColor: Colors.orange, colorText: Colors.white);
                            return;
                          }
                          WhatsAppService.openWhatsAppForStore(
                            phoneNumber: phone,
                            storeName: businessName,
                          );
                        },
                        icon: const Icon(Icons.chat_rounded, size: 18),
                        label: const Text('تواصل واتساب'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.whatsapp,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        showReportSheet(
                          context,
                          targetType: 'BUSINESS',
                          targetId:
                              (Get.arguments as Map<String, dynamic>?)?['id'] ??
                              '',
                          targetName: businessName,
                        );
                      },
                      icon: const Icon(Icons.flag_outlined, size: 18),
                      label: const Text('إبلاغ'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.divider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Products header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  AppTheme.space20,
                  AppTheme.space16,
                  0,
                ),
                child: Text(
                  'منتجات المتجر',
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            // Products grid
            _products.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(child: Text('لا يوجد منتجات حاليا')),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => ProductCard(
                          product: _products[i],
                          heroTagPrefix: 'store-',
                        ),
                        childCount: _products.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
        ),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
