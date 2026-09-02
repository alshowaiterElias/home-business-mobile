import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/dummy_data.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/product_card.dart';
import '../../widgets/report_sheet.dart';
import '../../core/network/data_service.dart';
import '../../core/network/api_client.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/network/whatsapp_service.dart';
import '../../core/network/chat_service.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/conversation_controller.dart';
import '../../models/chat_models.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _businessData;
  List<Product> _products = [];
  bool _isFollowed = false;
  int _followersCount = 0;
  bool _followLoading = false;

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
          _isFollowed = data['isFollowed'] == true;
          _followersCount = data['followersCount'] as int? ?? 0;
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

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    final businessId = (Get.arguments as Map<String, dynamic>?)?['id'] as String? ?? _businessData?['id'] ?? '';
    if (businessId.isEmpty) return;

    setState(() => _followLoading = true);
    try {
      final result = await DataService.toggleFollowStore(businessId);
      if (mounted) {
        setState(() {
          _isFollowed = result['isFollowed'] == true;
          _followersCount = result['followersCount'] as int? ?? _followersCount;
        });
        Get.snackbar(
          'تحديث',
          _isFollowed ? 'تمت متابعة المتجر بنجاح 🌟' : 'تم إلغاء متابعة المتجر',
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'تنبيه',
        'يرجى تسجيل الدخول أولاً لمتابعة هذا المتجر',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _followLoading = false);
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
                    color: context.colors.surface,
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
                              color: context.colors.surface,
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
              expandedHeight: 230,
              pinned: true,
              backgroundColor: context.colors.surface,
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
                    SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
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
                                    radius: 36,
                                    backgroundColor: AppTheme.primaryDark,
                                    backgroundImage: fullLogoUrl != null
                                        ? NetworkImage(fullLogoUrl)
                                        : null,
                                    child: fullLogoUrl == null
                                        ? const Icon(
                                            Icons.storefront_rounded,
                                            color: Colors.white,
                                            size: 36,
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
                          // Subtle Animated Follow Button overlaying the background image
                          GestureDetector(
                            onTap: _followLoading ? null : _toggleFollow,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isFollowed
                                    ? Colors.teal.shade700.withValues(alpha: 0.95)
                                    : Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _isFollowed ? Colors.teal.shade300 : Colors.white54,
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: _followLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 250),
                                      transitionBuilder: (child, animation) {
                                        return ScaleTransition(
                                          scale: animation,
                                          child: FadeTransition(opacity: animation, child: child),
                                        );
                                      },
                                      child: Row(
                                        key: ValueKey<bool>(_isFollowed),
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _isFollowed
                                                ? Icons.check_circle_rounded
                                                : Icons.person_add_alt_1_rounded,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isFollowed ? 'مُتابَع' : 'متابعة المتجر',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats with clear Followers Count
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.space16),
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space16),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  boxShadow: context.colors.shadowSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _Stat(label: 'المنتجات', value: '${_products.length}'),
                    Container(width: 1, height: 30, color: context.colors.divider),
                    _Stat(label: 'التقييم', value: storeRating),
                    Container(width: 1, height: 30, color: context.colors.divider),
                    _Stat(label: 'المتابعين', value: '$_followersCount'),
                    Container(width: 1, height: 30, color: context.colors.divider),
                    _Stat(label: 'منذ', value: activeSince),
                  ],
                ),
              ),
            ),

            // Action Buttons: WhatsApp & Report
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                ),
                child: Row(
                  children: [
                    // WhatsApp Button
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.whatsapp.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(color: AppTheme.whatsapp.withValues(alpha: 0.3)),
                      ),
                      child: IconButton(
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, color: AppTheme.whatsapp, size: 20),
                        onPressed: () {
                          final phone = _businessData?['contactPhone'] ?? '';
                          if (phone.isEmpty) {
                            Get.snackbar(
                              'تنبيه',
                              'رقم هاتف المتجر غير متوفر',
                              backgroundColor: Colors.orange,
                              colorText: Colors.white,
                            );
                            return;
                          }
                          WhatsAppService.openWhatsAppForStore(
                            phoneNumber: phone,
                            storeName: businessName,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // In-app Chat Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final auth = Get.find<AuthController>();
                            if (!auth.isLoggedIn.value) {
                              Get.toNamed('/auth');
                              return;
                            }

                            final sellerUserId = _businessData?['userId'] as String?;
                            if (sellerUserId == null || sellerUserId.isEmpty) return;

                            if (auth.userId.value == sellerUserId) {
                               Get.snackbar('تنبيه', 'لا يمكنك محادثة متجرك الخاص');
                               return;
                            }

                            try {
                              Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                              final convData = await ChatApiService.getOrCreateConversation(sellerUserId);
                              Get.back();

                              final conv = Conversation.fromJson(convData);
                              Get.toNamed('/chat/${conv.id}', arguments: {'conversation': conv});

                              // Send store reference message
                              final chatCtrl = Get.put(ConversationController(conversationId: conv.id, currentUserId: auth.userId.value), tag: conv.id);
                              chatCtrl.sendReferenceMessage(
                                type: 'STORE_REFERENCE',
                                referenceType: 'STORE',
                                referenceId: _businessData!['id'],
                                snapshotTitle: businessName,
                                snapshotImage: logoUrl,
                              );
                            } catch (e) {
                              if (Get.isDialogOpen ?? false) Get.back();
                              Get.snackbar('خطأ', 'تعذر بدء المحادثة');
                            }
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                          label: const Text('محادثة'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Report Button
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
                        foregroundColor: context.colors.textSecondary,
                        side: BorderSide(color: context.colors.divider),
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
