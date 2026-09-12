import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
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
import '../../controllers/data_controller.dart';
import '../../controllers/ai_assistant_controller.dart';
import '../../controllers/favorites_controller.dart';
import '../../models/chat_models.dart';
import '../../widgets/verified_badge.dart';
import '../../widgets/shimmer_skeletons.dart';
import '../../widgets/app_cached_image.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _isLoading = true;
  bool _isFetchingProducts = true;
  Map<String, dynamic>? _businessData;
  List<Product> _products = [];
  bool? _isFollowed;
  int _followersCount = 0;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _initFromCacheOrArgs();
    _fetchBusinessData();
  }

  void _initFromCacheOrArgs() {
    final args = Get.arguments as Map<String, dynamic>?;
    final businessId = args?['id'] as String? ?? '';
    final passedStore = args?['store'] as Map<String, dynamic>?;
    final fallbackName = args?['businessName'] as String?;

    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    final isLoggedIn = auth?.isLoggedIn.value == true;

    // Resolve follow status accurately and synchronously
    bool? resolvedFollow;
    if (!isLoggedIn) {
      resolvedFollow = false;
    } else if (businessId.isNotEmpty) {
      // 1. Check DataService global followed stores
      final fromDataService = DataService.isStoreFollowed(businessId);
      if (fromDataService != null) {
        resolvedFollow = fromDataService;
      }

      // 2. Check FavoritesController
      if (resolvedFollow == null && Get.isRegistered<FavoritesController>()) {
        final favCtrl = Get.find<FavoritesController>();
        if (favCtrl.followedStoreIds.isNotEmpty) {
          resolvedFollow = favCtrl.isStoreFollowed(businessId);
        }
      }

      // 3. Check DataService cached business
      final cached = DataService.getCachedBusiness(businessId);
      if (resolvedFollow == null && cached != null && cached['isFollowed'] is bool) {
        resolvedFollow = cached['isFollowed'] as bool;
      }

      // 4. Check passedStore arguments
      if (resolvedFollow == null && passedStore != null && passedStore['isFollowed'] is bool) {
        resolvedFollow = passedStore['isFollowed'] as bool;
      }
    }
    _isFollowed = resolvedFollow;

    // 1. Start with explicitly passed store object if available
    Map<String, dynamic>? sourceData = passedStore != null
        ? Map<String, dynamic>.from(passedStore)
        : null;

    // 2. Overlay or populate from DataService synchronous in-memory cache
    final cached = businessId.isNotEmpty ? DataService.getCachedBusiness(businessId) : null;
    if (cached != null) {
      if (sourceData == null) {
        sourceData = Map<String, dynamic>.from(cached);
      } else {
        if (cached['followersCount'] != null) {
          sourceData['followersCount'] = cached['followersCount'];
        }
        if (sourceData['products'] == null && cached['products'] != null) {
          sourceData['products'] = cached['products'];
        }
      }
    }

    // 3. Populate from DataController topStores if still empty
    if (sourceData == null && businessId.isNotEmpty && Get.isRegistered<DataController>()) {
      final dataCtrl = Get.find<DataController>();
      for (final s in dataCtrl.topStores) {
        if (s is Map && s['id'] == businessId) {
          sourceData = Map<String, dynamic>.from(s);
          break;
        }
      }
    }

    // 4. Populate from AiAssistantController known stores if still empty
    if (sourceData == null && businessId.isNotEmpty && Get.isRegistered<AiAssistantController>()) {
      sourceData = Get.find<AiAssistantController>().getKnownStoreObject(businessId);
    }

    // 5. Fallback lookup by store name in AiAssistantController
    if (sourceData == null && fallbackName != null && fallbackName.isNotEmpty && Get.isRegistered<AiAssistantController>()) {
      sourceData = Get.find<AiAssistantController>().getKnownStoreObject(fallbackName);
    }

    if (_isFollowed == null && sourceData != null && sourceData['isFollowed'] is bool) {
      _isFollowed = sourceData['isFollowed'] as bool;
    }

    if (sourceData != null) {
      _applyBusinessData(sourceData);
      _isLoading = false;
      if (_products.isNotEmpty) {
        _isFetchingProducts = false;
      }
    } else if (fallbackName != null && fallbackName.isNotEmpty) {
      // Partial initialization: show header immediately while data fetches
      _businessData = {
        'id': businessId,
        'businessName': fallbackName,
      };
      _isLoading = false;
    }
  }

  void _applyBusinessData(Map<String, dynamic> data) {
    _businessData = data;

    // Only update _isFollowed if the incoming data has an explicit boolean
    if (data['isFollowed'] is bool) {
      final newFollow = data['isFollowed'] as bool;
      _isFollowed = newFollow;
      final bizId = (data['id'] ?? _businessData?['id'])?.toString();
      if (bizId != null && bizId.isNotEmpty) {
        DataService.setStoreFollowed(bizId, newFollow);
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().setStoreFollowed(bizId, newFollow, data);
        }
      }
    }

    _followersCount = data['followersCount'] as int? ??
        (data['_count']?['followers'] as int? ?? _followersCount);

    final productsData = data['products'] as List<dynamic>? ?? [];
    if (productsData.isNotEmpty) {
      _products = productsData.map((p) {
        if (p is Product) return p;
        final productMap = Map<String, dynamic>.from(p as Map);
        productMap['business'] = data;
        return Product.fromJson(productMap);
      }).toList();
    }
  }

  Future<void> _fetchBusinessData() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final businessId = args?['id'] as String? ?? _businessData?['id'] as String? ?? '';

    if (businessId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isFetchingProducts = false;
        });
      }
      return;
    }

    try {
      final data = await DataService.getBusinessById(businessId, forceRefresh: true);
      if (mounted) {
        setState(() {
          _applyBusinessData(data);
          _isLoading = false;
          _isFetchingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_businessData == null) _isLoading = false;
          _isFetchingProducts = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    final businessId = _businessData?['id'] as String? ??
        (Get.arguments as Map<String, dynamic>?)?['id'] as String? ??
        '';
    if (businessId.isEmpty) return;

    final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
    if (auth?.isLoggedIn.value != true) {
      Get.snackbar(
        'تنبيه',
        'يرجى تسجيل الدخول أولاً لمتابعة هذا المتجر',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _followLoading = true);
    try {
      final result = await DataService.toggleFollowStore(businessId);
      if (mounted) {
        final newFollowState = result['isFollowed'] == true;
        final currentCount = _followersCount;
        final newFollowersCount = result['followersCount'] as int? ??
            (_isFollowed == true
                ? (currentCount > 0 ? currentCount - 1 : 0)
                : currentCount + 1);

        setState(() {
          _isFollowed = newFollowState;
          _followersCount = newFollowersCount;
          if (_businessData != null) {
            _businessData!['isFollowed'] = newFollowState;
            _businessData!['followersCount'] = newFollowersCount;
          }
        });

        // Keep DataService & FavoritesController synchronized
        DataService.cacheBusiness(businessId, {
          if (_businessData != null) ..._businessData!,
          'id': businessId,
          'isFollowed': newFollowState,
          'followersCount': newFollowersCount,
        });
        DataService.setStoreFollowed(businessId, newFollowState);

        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().setStoreFollowed(
            businessId,
            newFollowState,
            _businessData,
          );
        }

        // Keep DataController topStores synchronized if present
        if (Get.isRegistered<DataController>()) {
          final dataCtrl = Get.find<DataController>();
          for (var s in dataCtrl.topStores) {
            if (s is Map && s['id'] == businessId) {
              s['isFollowed'] = newFollowState;
              s['followersCount'] = newFollowersCount;
            }
          }
          for (var s in dataCtrl.featuredStores) {
            if (s is Map && s['id'] == businessId) {
              s['isFollowed'] = newFollowState;
              s['followersCount'] = newFollowersCount;
            }
          }
        }

        Get.snackbar(
          'تحديث',
          newFollowState ? 'تمت متابعة المتجر بنجاح 🌟' : 'تم إلغاء متابعة المتجر',
          backgroundColor: AppTheme.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تحديث المتابعة، يرجى المحاولة لاحقاً',
        backgroundColor: Colors.red,
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
                          child: AppCachedImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.contain,
                            memCacheWidth: 1200,
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
      return _buildStoreSkeleton(context);
    }

    if (_businessData == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('تعذر تحميل بيانات المتجر'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _isFetchingProducts = true;
                  });
                  _fetchBusinessData();
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final businessName = _businessData?['businessName'] ?? 'متجر غير معروف';
    final location = _businessData?['city']?['nameAr'] ?? 'غير محدد';
    final isFollowKnown = _isFollowed != null;
    final isFollowing = _isFollowed == true;
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
                        child: AppCachedImage(
                          imageUrl: fullLogoUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 800,
                          errorWidget: Container(
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
                                  child: AppCachedAvatar(
                                    imageUrl: fullLogoUrl,
                                    radius: 36,
                                    backgroundColor: AppTheme.primaryDark,
                                    fallbackIcon: Icons.storefront_rounded,
                                    iconColor: Colors.white,
                                    iconSize: 36,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
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
                              ),
                              if (_businessData?['isVerified'] == true ||
                                  _businessData?['is_verified'] == true) ...[
                                const SizedBox(width: 6),
                                const VerifiedBadge(size: 20),
                              ],
                            ],
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
                          // Subtle Animated Follow Button with immediate true-state rendering
                          GestureDetector(
                            onTap: (_followLoading || !isFollowKnown) ? null : _toggleFollow,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeInOut,
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: !isFollowKnown
                                    ? Colors.black.withValues(alpha: 0.35)
                                    : isFollowing
                                        ? Colors.teal.shade700.withValues(alpha: 0.95)
                                        : Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: !isFollowKnown
                                      ? Colors.white24
                                      : isFollowing
                                          ? Colors.teal.shade300
                                          : Colors.white54,
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
                                  : !isFollowKnown
                                      ? const SizedBox(
                                          width: 60,
                                          height: 16,
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
                                            key: ValueKey<bool>(isFollowing),
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isFollowing
                                                    ? Icons.check_circle_rounded
                                                    : Icons.person_add_alt_1_rounded,
                                                size: 15,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                isFollowing ? 'مُتابَع' : 'متابعة المتجر',
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
            if (_products.isEmpty && _isFetchingProducts)
              _buildProductGridSkeleton(context)
            else if (_products.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(child: Text('لا يوجد منتجات حاليا')),
                ),
              )
            else
              SliverPadding(
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

  Widget _buildProductGridSkeleton(BuildContext context) {
    return const ProductGridSkeleton(isSliver: true, itemCount: 4);
  }

  Widget _buildStoreSkeleton(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: context.colors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Shimmer.fromColors(
                baseColor: context.colors.shimmerBase,
                highlightColor: context.colors.shimmerHighlight,
                child: Container(
                  color: context.colors.surface,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 140,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Shimmer.fromColors(
              baseColor: context.colors.shimmerBase,
              highlightColor: context.colors.shimmerHighlight,
              child: Container(
                margin: const EdgeInsets.all(AppTheme.space16),
                height: 70,
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            ),
          ),
          _buildProductGridSkeleton(context),
        ],
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
