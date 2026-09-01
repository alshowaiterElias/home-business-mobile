import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/report_sheet.dart';
import '../../core/network/data_service.dart';
import '../../core/network/api_client.dart';
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

  void _showEnlargedImage(BuildContext context, String imageUrl, String storeName) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'إغلاق الصورة',
      barrierColor: Colors.black.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final scaleAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeIn,
        );

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ScaleTransition(
            scale: scaleAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Zoomable Image
                        InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              padding: const EdgeInsets.all(32),
                              color: AppTheme.surface,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_rounded,
                                    size: 64,
                                    color: Colors.white54,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'تعذر تحميل الصورة',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Store name header tag
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Text(
                              storeName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Close Button
                        Positioned(
                          top: 14,
                          left: 14,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white30,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
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

    final logoUrl = _businessData?['logoUrl'] as String?;
    final fullLogoUrl = (logoUrl != null && logoUrl.isNotEmpty)
        ? ApiClient.getImageUrl(logoUrl)
        : null;

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
              expandedHeight: 220,
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
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Store image banner or default gradient background
                    if (fullLogoUrl != null)
                      GestureDetector(
                        onTap: () => _showEnlargedImage(context, fullLogoUrl, businessName),
                        child: Image.network(
                          fullLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryDark, AppTheme.primary],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryDark, AppTheme.primary],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                        ),
                      ),

                    // Dark gradient overlay for clear contrast and readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),

                    // Centered Store Logo & Info
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              if (fullLogoUrl != null) {
                                _showEnlargedImage(context, fullLogoUrl, businessName);
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: AppTheme.primaryDark,
                                    backgroundImage: fullLogoUrl != null
                                        ? NetworkImage(fullLogoUrl)
                                        : null,
                                    child: fullLogoUrl == null
                                        ? const Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.white,
                                            size: 38,
                                          )
                                        : null,
                                  ),
                                ),
                                if (fullLogoUrl != null)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.space8),
                          Text(
                            businessName,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                const Shadow(
                                  color: Colors.black45,
                                  blurRadius: 6,
                                ),
                              ],
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
                  ],
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
