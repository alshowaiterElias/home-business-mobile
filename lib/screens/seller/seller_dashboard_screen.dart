import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/data_service.dart';
import '../../core/network/error_handler.dart';
import '../../core/utils/image_compressor.dart';
import '../../controllers/seller_dashboard_controller.dart';
import '../../controllers/add_product_controller.dart';
import '../../controllers/data_controller.dart';
import '../../controllers/auth_controller.dart';
import 'my_product_detail_screen.dart';
import 'suspended_account_screen.dart';

/// Seller's private dashboard to manage their business and products.
class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(SellerDashboardController());

    return Obx(() {
      if (controller.isBusinessSuspended) {
        return SuspendedAccountScreen(
          storeName: controller.businessData['businessName'],
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم البائع'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Get.to(() => EditBusinessScreen(businessData: Map<String, dynamic>.from(controller.businessData))),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const AddProductScreen()),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة منتج'),
        ),
        body: RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          child: Builder(builder: (context) {
            if (controller.isLoading.value && controller.myProducts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.space16),
              children: [
                // ── Business Header Card ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary,
                        AppTheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: controller.businessData['logoUrl'] != null
                            ? CachedNetworkImageProvider(
                                ApiClient.getImageUrl(controller.businessData['logoUrl']),
                              )
                            : null,
                        child: controller.businessData['logoUrl'] == null
                            ? const Icon(Icons.storefront_rounded, color: Colors.white, size: 28)
                            : null,
                      ),
                      const SizedBox(width: AppTheme.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.businessData['businessName'] ?? 'متجري',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  controller.storeRating,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.location_on_outlined, color: Colors.white.withValues(alpha: 0.8), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  controller.businessData['city']?['nameAr'] ?? 'اليمن',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.to(() => EditBusinessScreen(
                              businessData: Map<String, dynamic>.from(controller.businessData),
                            )),
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 26),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space20),

                // ── Quick Stats Grid (Interactive Filter Buttons) ────
                Text('إحصائيات المنتجات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppTheme.space12),
                Row(
                  children: [
                    _QuickStat(
                      label: 'الكل',
                      value: '${controller.myProducts.length}',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.primary,
                      isSelected: controller.selectedFilter.value == 'ALL',
                      onTap: () => controller.setFilter('ALL'),
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'نشطة',
                      value: '${controller.activeProductsCount}',
                      icon: Icons.check_circle_outline_rounded,
                      color: Colors.teal,
                      isSelected: controller.selectedFilter.value == 'APPROVED',
                      onTap: () => controller.setFilter('APPROVED'),
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'بالانتظار',
                      value: '${controller.pendingProductsCount}',
                      icon: Icons.hourglass_top_rounded,
                      color: AppTheme.accent,
                      isSelected: controller.selectedFilter.value == 'PENDING',
                      onTap: () => controller.setFilter('PENDING'),
                    ),
                    const SizedBox(width: 8),
                    _QuickStat(
                      label: 'مرفوضة',
                      value: '${controller.rejectedProductsCount}',
                      icon: Icons.cancel_outlined,
                      color: AppTheme.error,
                      isSelected: controller.selectedFilter.value == 'REJECTED',
                      onTap: () => controller.setFilter('REJECTED'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // ── Products Header & Filter Indicator ────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('منتجاتي', style: theme.textTheme.headlineSmall),
                    if (controller.selectedFilter.value != 'ALL')
                      TextButton.icon(
                        onPressed: () => controller.setFilter('ALL'),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('إلغاء التصفية'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                if (controller.filteredProducts.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_rounded, size: 56, color: AppTheme.textHint.withValues(alpha: 0.4)),
                          const SizedBox(height: 12),
                          Text(
                            controller.myProducts.isEmpty
                                ? 'لم تقم بإضافة أي منتجات بعد'
                                : 'لا توجد منتجات مطابقة لهذا الفلتر',
                            style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...controller.filteredProducts.map((p) => _ProductTile(product: p, theme: theme)),
              ],
            );
          }),
        ),
      );
    });
  }
}

// ─── Quick Stat Widget (Interactive Filter Button) ─────────────
class _QuickStat extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : AppTheme.shadowSm,
            border: Border.all(
              color: isSelected ? color : AppTheme.divider.withValues(alpha: 0.5),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Product Tile ────────────────────────────────────────────────
class _ProductTile extends StatelessWidget {
  final dynamic product;
  final ThemeData theme;
  const _ProductTile({required this.product, required this.theme});

  Color _statusColor() {
    switch (product['status']) {
      case 'APPROVED': return AppTheme.primary;
      case 'PENDING': return AppTheme.accent;
      case 'REJECTED': 
      case 'SUSPENDED': return AppTheme.error;
      default: return AppTheme.textHint;
    }
  }

  String _statusLabel() {
    switch (product['status']) {
      case 'APPROVED': return 'مقبول';
      case 'PENDING': return 'بالانتظار';
      case 'REJECTED': return 'مرفوض';
      case 'SUSPENDED': return 'موقوف 🚫';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = (product['images'] != null && product['images'].isNotEmpty) 
        ? (product['images'][0]['imageUrl'] ?? '') 
        : '';
        
    return InkWell(
      onTap: () => Get.to(() => MyProductDetailScreen(initialProduct: Map<String, dynamic>.from(product))),
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.space12),
        padding: const EdgeInsets.all(AppTheme.space12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.shadowSm,
          border: product['status'] == 'REJECTED'
              ? Border.all(color: AppTheme.error.withValues(alpha: 0.3))
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  child: CachedNetworkImage(
                    imageUrl: ApiClient.getImageUrl(imageUrl),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 60,
                      height: 60,
                      color: AppTheme.background,
                      child: const Icon(Icons.image_not_supported_outlined,
                          size: 20, color: AppTheme.textHint),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product['title'] ?? '', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${product['price']} ${product['currency'] ?? 'YER'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(_statusLabel(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: _statusColor())),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 16, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'عرض التفاصيل والتقييمات',
                      style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textHint),
              ],
            ),
            if (product['status'] == 'REJECTED' && product['rejectionReason'] != null) ...[
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('سبب الرفض: ${product['rejectionReason']}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.error)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Add Product Screen
// ═══════════════════════════════════════════════════════════════════
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(AddProductController());
    final dataController = Get.find<DataController>();

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منتج جديد')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload area
              if (controller.images.isEmpty)
                GestureDetector(
                  onTap: () => controller.pickImages(),
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.divider, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined,
                            size: 48, color: AppTheme.textHint),
                        const SizedBox(height: AppTheme.space8),
                        Text('أضف صور المنتج (حتى 5 صور)',
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.images.length < 5 ? controller.images.length + 1 : 5,
                    itemBuilder: (ctx, i) {
                      if (i == controller.images.length) {
                        return GestureDetector(
                          onTap: () => controller.pickImages(),
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: const Center(child: Icon(Icons.add, color: AppTheme.textHint, size: 32)),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            margin: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              image: DecorationImage(
                                image: FileImage(controller.images[i]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => controller.removeImage(i),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              const SizedBox(height: AppTheme.space24),

              _FormField(label: 'اسم المنتج *', hint: 'مثال: كيكة شوكولاتة فاخرة', controller: controller.titleController),
              const SizedBox(height: AppTheme.space16),
              _FormField(label: 'الوصف', hint: 'صف المنتج بالتفصيل...', maxLines: 4, controller: controller.descriptionController),
              const SizedBox(height: AppTheme.space16),

              Row(
                children: [
                  Expanded(child: _FormField(label: 'السعر *', hint: '0', keyboardType: TextInputType.number, controller: controller.priceController)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وحدة البيع', style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppTheme.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: Obx(() {
                              final availableUnits = controller.units;
                              if (!availableUnits.contains(controller.selectedUnit.value) && availableUnits.isNotEmpty) {
                                controller.selectedUnit.value = availableUnits.first;
                              }
                              return DropdownButton<String>(
                                isExpanded: true,
                                menuMaxHeight: 250,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                value: controller.selectedUnit.value,
                                items: availableUnits.map((u) => DropdownMenuItem<String>(value: u, child: Text(u))).toList(),
                                onChanged: (val) {
                                  if (val != null) controller.selectedUnit.value = val;
                                },
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space16),

              Text('القسم الرئيسي *', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: controller.selectedCategoryId.value.isEmpty ? null : controller.selectedCategoryId.value,
                    hint: const Text('اختر القسم'),
                    items: dataController.categories.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['nameAr']))).toList(),
                    onChanged: (val) {
                      controller.selectedCategoryId.value = val!;
                      controller.selectedSubCategoryId.value = '';
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space16),

              if (controller.selectedCategoryId.value.isNotEmpty) ...[
                Obx(() {
                  final parentCat = dataController.categories.firstWhere((c) => c['id'] == controller.selectedCategoryId.value, orElse: () => null);
                  if (parentCat == null || parentCat['children'] == null || parentCat['children'].isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('القسم الفرعي (اختياري)', style: theme.textTheme.titleMedium),
                      const SizedBox(height: AppTheme.space8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            menuMaxHeight: 250,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            value: controller.selectedSubCategoryId.value.isEmpty ? null : controller.selectedSubCategoryId.value,
                            hint: const Text('بدون قسم فرعي'),
                            items: (parentCat['children'] as List<dynamic>).map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['nameAr']))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.selectedSubCategoryId.value = val;
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.space16),
                    ],
                  );
                }),
              ],

              Text('العملة', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: controller.selectedCurrency.value,
                    items: controller.currencies.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                    onChanged: (val) => controller.selectedCurrency.value = val!,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space32),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => controller.submitProduct(),
                  child: const Text('إرسال للمراجعة'),
                ),
              ),
              const SizedBox(height: AppTheme.space24),
            ],
          ),
        );
      }),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label, hint;
  final int maxLines;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  const _FormField({required this.label, required this.hint,
      this.maxLines = 1, this.keyboardType = TextInputType.text, this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTheme.space8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Edit Business Profile Screen
// ═══════════════════════════════════════════════════════════════════
class EditBusinessScreen extends StatefulWidget {
  final dynamic businessData;
  const EditBusinessScreen({super.key, this.businessData});

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  final dataController = Get.find<DataController>();
  
  File? _newLogoFile;
  String? _currentLogoUrl;
  String _selectedGovId = '';
  String _selectedCityId = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.businessData ?? {};
    nameController = TextEditingController(text: b['businessName'] ?? '');
    descController = TextEditingController(text: b['description'] ?? '');
    
    // Format phone: if it has +967, strip it, else use as is
    String phone = b['contactPhone'] ?? '';
    if (phone.startsWith('+967')) {
      phone = phone.substring(4);
    }
    phoneController = TextEditingController(text: phone);
    addressController = TextEditingController(text: b['addressDetails'] ?? '');
    _currentLogoUrl = b['logoUrl'];
    
    // Initialize governorate and city from existing data
    if (b['city'] != null) {
      _selectedCityId = b['city']['id'] ?? '';
      // Find the governorate that contains this city
      for (var gov in dataController.locations) {
        final cities = gov['cities'] as List<dynamic>? ?? [];
        for (var city in cities) {
          if (city['id'] == _selectedCityId) {
            _selectedGovId = gov['id'] ?? '';
            break;
          }
        }
        if (_selectedGovId.isNotEmpty) break;
      }
    }
    
    // Fetch locations if not already loaded
    if (dataController.locations.isEmpty) {
      dataController.fetchLocations();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newLogoFile = File(picked.path);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة الحقول المطلوبة',
          backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final formattedPhone = '+967${phoneController.text.trim()}';

      final formData = dio.FormData.fromMap({
        'businessName': nameController.text.trim(),
        'description': descController.text.trim(),
        'contactPhone': formattedPhone,
        'addressDetails': addressController.text.trim(),
        if (_selectedCityId.isNotEmpty) 'cityId': _selectedCityId,
      });

      if (_newLogoFile != null) {
        final compressedLogo = await ImageCompressor.compressFile(_newLogoFile!);
        formData.files.add(MapEntry(
          'logo',
          await dio.MultipartFile.fromFile(compressedLogo.path, filename: 'logo.jpg'),
        ));
      }

      final response = await DataService.updateMyBusiness(formData);
      if (response['success'] == true) {
        // Refresh the seller dashboard
        if (Get.isRegistered<SellerDashboardController>()) {
          Get.find<SellerDashboardController>().fetchDashboardData();
        }
        // Refresh auth profile
        Get.find<AuthController>().fetchProfile();
        // Refresh stores list on home
        dataController.fetchTopStores();
        
        Get.back();
        Get.snackbar('تم بنجاح', 'تم تحديث بيانات المتجر',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      }
    } catch (e) {
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ في التحديث', errorMsg,
          backgroundColor: Colors.redAccent, colorText: Colors.white,
          duration: const Duration(seconds: 4));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات المتجر')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Center(
              child: GestureDetector(
                onTap: _pickLogo,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.primarySurface,
                      backgroundImage: _newLogoFile != null
                          ? FileImage(_newLogoFile!)
                          : (_currentLogoUrl != null
                              ? NetworkImage(ApiClient.getImageUrl(_currentLogoUrl!))
                              : null) as ImageProvider?,
                      child: (_newLogoFile == null && _currentLogoUrl == null)
                          ? const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(
                          color: AppTheme.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt_rounded,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space8),
            Center(
              child: Text(
                'اضغط لتغيير شعار المتجر',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: AppTheme.space24),

            _FormField(label: 'اسم المتجر', hint: 'مطبخ أم محمد', controller: nameController),
            const SizedBox(height: AppTheme.space16),
            _FormField(label: 'الوصف', hint: 'نبذة عن متجرك...', maxLines: 3, controller: descController),
            const SizedBox(height: AppTheme.space16),
            
            Text('رقم التواصل (واتساب) *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.space8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: '7XX XXX XXX',
                prefixIcon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text('+967', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textDirection: TextDirection.ltr),
                ),
                prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            
            _FormField(label: 'تفاصيل العنوان', hint: 'شارع، حي، بجانب...', maxLines: 2, controller: addressController),
            const SizedBox(height: AppTheme.space16),

            // Governorate dropdown
            Text('المحافظة', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.space8),
            Obx(() {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 250,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    value: _selectedGovId.isEmpty ? null : _selectedGovId,
                    hint: Text(
                      'اختر المحافظة',
                      style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textHint),
                    ),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint),
                    items: dataController.locations.map<DropdownMenuItem<String>>((gov) {
                      return DropdownMenuItem<String>(
                        value: gov['id'],
                        child: Text(gov['nameAr']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGovId = val;
                          _selectedCityId = ''; // reset city
                        });
                      }
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: AppTheme.space16),

            // City dropdown (only show when governorate is selected)
            if (_selectedGovId.isNotEmpty) ...[
              Text('المدينة / المديرية', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppTheme.space8),
              Obx(() {
                final gov = dataController.locations.firstWhere(
                  (g) => g['id'] == _selectedGovId,
                  orElse: () => null,
                );
                final cities = (gov != null ? gov['cities'] as List<dynamic>? : null) ?? [];
                
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      menuMaxHeight: 250,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      value: _selectedCityId.isEmpty ? null : _selectedCityId,
                      hint: Text(
                        'اختر المدينة',
                        style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textHint),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textHint),
                      items: cities.map<DropdownMenuItem<String>>((city) {
                        return DropdownMenuItem<String>(
                          value: city['id'],
                          child: Text(city['nameAr']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCityId = val;
                          });
                        }
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppTheme.space16),
            ],

            const SizedBox(height: AppTheme.space16),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ التغييرات'),
              ),
            ),
            const SizedBox(height: AppTheme.space24),
          ],
        ),
      ),
    );
  }
}
