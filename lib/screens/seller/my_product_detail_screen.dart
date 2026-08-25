import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../core/network/data_service.dart';
import '../../controllers/seller_dashboard_controller.dart';
import 'suspended_product_screen.dart';

class MyProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> initialProduct;

  const MyProductDetailScreen({super.key, required this.initialProduct});

  @override
  State<MyProductDetailScreen> createState() => _MyProductDetailScreenState();
}

class _MyProductDetailScreenState extends State<MyProductDetailScreen> {
  late Map<String, dynamic> product;
  bool isLoading = true;
  int _activeImageIndex = 0;

  @override
  void initState() {
    super.initState();
    product = widget.initialProduct;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    final productId = product['id'];
    if (productId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final fullData = await DataService.getProductById(productId);
      if (fullData.isNotEmpty && mounted) {
        setState(() {
          product = fullData;
          isLoading = false;
        });
      } else if (mounted) {
        setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Color _getStatusColor() {
    switch (product['status']) {
      case 'APPROVED':
        return AppTheme.primary;
      case 'PENDING':
        return AppTheme.accent;
      case 'REJECTED':
        return AppTheme.error;
      default:
        return AppTheme.textHint;
    }
  }

  String _getStatusText() {
    switch (product['status']) {
      case 'APPROVED':
        return 'مقبول ومعروض للسوق';
      case 'PENDING':
        return 'قيد مراجعة الإدارة';
      case 'REJECTED':
        return 'مرفوض من الإدارة';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (product['status'] == 'SUSPENDED') {
      return SuspendedProductScreen(
        productTitle: product['title'] ?? '',
        storeName: product['business']?['businessName'],
      );
    }

    final List<dynamic> images = product['images'] ?? [];
    final List<dynamic> reviews = product['reviews'] ?? [];

    // Rating stats
    final double avgRating =
        double.tryParse(
          '${product['ratingAverage'] ?? product['averageRating'] ?? 0.0}',
        ) ??
        0.0;
    final int reviewsCount = reviews.length > 0
        ? reviews.length
        : (product['reviewsCount'] ?? product['_count']?['reviews'] ?? 0);

    // Calculate star breakdown (5 star to 1 star)
    Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in reviews) {
      int score = ((r['rating'] as num?) ?? 5).toInt();
      if (score >= 1 && score <= 5) {
        starCounts[score] = (starCounts[score] ?? 0) + 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج والتقييمات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchFullDetails();
            },
            tooltip: 'تحديث البيانات',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    color: _getStatusColor().withOpacity(0.12),
                    child: Row(
                      children: [
                        Icon(
                          product['status'] == 'APPROVED'
                              ? Icons.check_circle_rounded
                              : (product['status'] == 'PENDING'
                                    ? Icons.hourglass_top_rounded
                                    : Icons.cancel_rounded),
                          color: _getStatusColor(),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'حالة المنتج: ${_getStatusText()}',
                            style: TextStyle(
                              color: _getStatusColor(),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Rejection Alert if rejected
                  if (product['status'] == 'REJECTED' &&
                      product['rejectionReason'] != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(AppTheme.space16),
                      padding: const EdgeInsets.all(AppTheme.space16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.error,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'سبب الرفض من الإدارة:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product['rejectionReason']}',
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Image Slider Carousel
                  if (images.isNotEmpty) ...[
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (idx) =>
                            setState(() => _activeImageIndex = idx),
                        itemBuilder: (context, index) {
                          final imgUrl = images[index]['imageUrl'] ?? '';
                          return CachedNetworkImage(
                            imageUrl: ApiClient.getImageUrl(imgUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (idx) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _activeImageIndex == idx
                                    ? AppTheme.primary
                                    : Colors.grey.shade300,
                              ),
                            );
                          }),
                        ),
                      ),
                  ],

                  // Product Header Info Card
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['title'] ?? '',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${product['price']} ${product['currency'] ?? 'YER'}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (product['unit'] != null) ...[
                              Text(
                                ' / ${product['unit']}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stats Summary Row
                        Row(
                          children: [
                            _buildStatChip(
                              icon: Icons.star_rounded,
                              iconColor: Colors.amber.shade700,
                              label:
                                  '${avgRating.toStringAsFixed(1)} ★ (${reviewsCount})',
                            ),
                            const SizedBox(width: 8),
                            if (product['category'] != null)
                              _buildStatChip(
                                icon: Icons.category_outlined,
                                iconColor: AppTheme.primary,
                                label:
                                    product['category']['nameAr'] ?? 'قسم عام',
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // AI Marketing Ad Generator Button (Only for APPROVED products)
                        if (product['status'] == 'APPROVED')
                          InkWell(
                            onTap: () => _showAiAdModal(context),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                ),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'صياغة إعلان تسويقي بالذكاء الاصطناعي 🪄',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Description Card
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'وصف المنتج',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['description'] != null &&
                                  (product['description'] as String).isNotEmpty
                              ? product['description']
                              : 'لا يوجد وصف مضاف لهذا المنتج.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Rating Breakdown Graph Section
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'إحصائيات وتقييمات العملاء',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Graph Card
                        Container(
                          padding: const EdgeInsets.all(AppTheme.space16),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(color: AppTheme.divider),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Row(
                            children: [
                              // Left: Big Rating Number
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < avgRating.floor()
                                            ? Icons.star_rounded
                                            : (index < avgRating
                                                  ? Icons.star_half_rounded
                                                  : Icons.star_border_rounded),
                                        color: Colors.amber.shade700,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'إجمالي $reviewsCount تقييم',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              const VerticalDivider(width: 1),
                              const SizedBox(width: 16),

                              // Right: Bar Graph Distribution
                              Expanded(
                                child: Column(
                                  children: [5, 4, 3, 2, 1].map((star) {
                                    final count = starCounts[star] ?? 0;
                                    final double percent = reviewsCount > 0
                                        ? (count / reviewsCount)
                                        : 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2.5,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '$star',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 12,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value: percent,
                                                minHeight: 8,
                                                backgroundColor:
                                                    Colors.grey.shade200,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      star >= 4
                                                          ? Colors.green
                                                          : (star == 3
                                                                ? Colors.amber
                                                                : Colors
                                                                      .redAccent),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Customer Reviews List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'آراء المراجِعين (${reviews.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (reviews.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'لا توجد تعليقات أو تقييمات مكتوبة حتى الآن.',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ...reviews.map((rev) {
                            final userPhone =
                                rev['user']?['phoneNumber'] ?? 'مستخدم';
                            final rating =
                                (rev['rating'] as num?)?.toInt() ?? 5;
                            final comment = rev['comment'] ?? '';
                            final createdAt = rev['createdAt'] != null
                                ? DateTime.tryParse(
                                        rev['createdAt'].toString(),
                                      )?.toLocal().toString().split(' ')[0] ??
                                      ''
                                : '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(AppTheme.space16),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(color: AppTheme.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor:
                                                AppTheme.primarySurface,
                                            child: const Icon(
                                              Icons.person,
                                              size: 18,
                                              color: AppTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            userPhone,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: List.generate(5, (starIdx) {
                                          return Icon(
                                            starIdx < rating
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: Colors.amber.shade700,
                                            size: 14,
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                  if (comment.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      comment,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  if (createdAt.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      createdAt,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textHint,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAiAdModal(BuildContext context) {
    if (product['status'] != 'APPROVED') {
      Get.snackbar(
        'تنبيه',
        'توليد إعلانات الذكاء الاصطناعي متاح فقط للمنتجات المعتمدة من الإدارة.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        List<String> ads = [];
        bool isGenerating = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setModalState) {
            void generateAds() async {
              setModalState(() {
                isGenerating = true;
                errorMessage = null;
              });
              try {
                final result = await DataService.generateAiAd(product['id']);
                setModalState(() {
                  ads = result;
                  isGenerating = false;
                });
              } catch (e) {
                setModalState(() {
                  errorMessage = 'تعذر توليد الإعلان. يرجى التأكد من الاتصال بالإنترنت والمحاولة مجدداً.';
                  isGenerating = false;
                });
              }
            }

            // Start initial generation
            if (isGenerating && ads.isEmpty && errorMessage == null) {
              generateAds();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Top Drag Indicator & Header
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF7C3AED),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'إعلانات الذكاء الاصطناعي ✨',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'إعلانات تسويقية جاهزة للنسخ والمشاركة على الواتساب',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Content Body
                  Expanded(
                    child: isGenerating
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                CircularProgressIndicator(color: Color(0xFF7C3AED)),
                                SizedBox(height: 16),
                                Text(
                                  'جاري صياغة الإعلانات التسويقية بواسطة الذكاء الاصطناعي... 🪄',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : (errorMessage != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 48),
                                    const SizedBox(height: 12),
                                    Text(
                                      errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppTheme.error, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: generateAds,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('إعادة المحاولة'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: ads.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final adText = ads[index];
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'النموذج ${index + 1} 📌',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF7C3AED),
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.copy_rounded, size: 20),
                                                  color: AppTheme.primary,
                                                  tooltip: 'نسخ الإعلان',
                                                  onPressed: () {
                                                    Clipboard.setData(ClipboardData(text: adText));
                                                    Get.snackbar(
                                                      'تم النسخ! 📋',
                                                      'تم نسخ الإعلان التسويقي إلى الحافظة.',
                                                      snackPosition: SnackPosition.BOTTOM,
                                                      backgroundColor: AppTheme.primary,
                                                      colorText: Colors.white,
                                                      duration: const Duration(seconds: 2),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          adText,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: adText));
                                              Get.snackbar(
                                                'تم النسخ بنجاح! 📋',
                                                'يمكنك الآن لصق الإعلان في الواتساب أو إنستغرام.',
                                                snackPosition: SnackPosition.BOTTOM,
                                                backgroundColor: AppTheme.primary,
                                                colorText: Colors.white,
                                              );
                                            },
                                            icon: const Icon(Icons.content_copy_rounded, size: 18),
                                            label: const Text('نسخ هذا الإعلان 📋'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primary,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              )),
                  ),

                  // Modal Bottom Actions
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: isGenerating ? null : () => generateAds(),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('إعادة صياغة إعلانات جديدة 🔄'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
