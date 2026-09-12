import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme/app_theme.dart';
import '../core/network/data_service.dart';
import 'auth_controller.dart';
import 'data_controller.dart';
import 'favorites_controller.dart';

class SellerDashboardController extends GetxController {
  static Map<String, dynamic>? _cachedDashboardData;
  static List<dynamic>? _cachedMyProducts;

  var isLoading = false.obs;
  var isRefreshing = false.obs;
  var businessData = {}.obs;
  var myProducts = <dynamic>[].obs;
  var selectedFilter = 'ALL'.obs; // ALL, APPROVED, PENDING, REJECTED, SUSPENDED
  var togglingProductIds = <String>{}.obs;

  bool isToggling(String productId) => togglingProductIds.contains(productId);

  @override
  void onInit() {
    super.onInit();
    // 1. Instant hydration with cached stale data (0ms delay)
    if (_cachedDashboardData != null) {
      businessData.value = _cachedDashboardData!;
      if (_cachedMyProducts != null) {
        myProducts.assignAll(_cachedMyProducts!);
      }
    } else {
      final auth = Get.isRegistered<AuthController>() ? Get.find<AuthController>() : null;
      final bus = auth?.currentUser['business'];
      if (bus != null) {
        businessData.value = Map<String, dynamic>.from(bus);
      }
    }

    // 2. Fetch fresh data only if cache is completely empty
    if (_cachedDashboardData == null) {
      fetchDashboardData(forceRefresh: true);
    }
  }

  Future<void> fetchDashboardData({bool forceRefresh = true}) async {
    final auth = Get.find<AuthController>();
    final businessInfo = auth.currentUser['business'];
    if (businessInfo == null) return;

    if (_cachedDashboardData == null && myProducts.isEmpty) {
      isLoading.value = true;
    } else {
      isRefreshing.value = true;
    }

    try {
      final data = await DataService.getMyBusinessDashboard(forceRefresh: forceRefresh);
      _cachedDashboardData = data;
      businessData.value = data;
      
      if (data['products'] != null) {
        final prods = List<dynamic>.from(data['products']);
        _cachedMyProducts = prods;
        myProducts.assignAll(prods);
      }
      update();
    } catch (e) {
      debugPrint('Error fetching seller dashboard: $e');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Invalidate static cache when products or store details are updated
  static void invalidateCache() {
    _cachedDashboardData = null;
    _cachedMyProducts = null;
    DataService.invalidateMyBusinessDashboard();
  }

  List<dynamic> get filteredProducts {
    final filter = selectedFilter.value.toUpperCase();
    if (filter == 'ALL') return myProducts;
    
    final list = myProducts.where((p) {
      final status = (p['status'] ?? '').toString().trim().toUpperCase();
      if (filter == 'REJECTED') {
        return status == 'REJECTED' || status == 'SUSPENDED';
      }
      return status == filter;
    }).toList();

    debugPrint('🔍 [filteredProducts] Filter "$filter" matched ${list.length} / ${myProducts.length} items');
    return list;
  }

  Future<bool> toggleAvailability(String productId) async {
    togglingProductIds.add(productId);
    try {
      final res = await DataService.toggleProductAvailability(productId);
      if (res['success'] == true && res['data'] != null) {
        final updated = res['data'];
        final index = myProducts.indexWhere((p) => p['id'] == productId);
        if (index != -1) {
          myProducts[index] = updated;
          myProducts.refresh();
          if (_cachedMyProducts != null) {
            final cIndex = _cachedMyProducts!.indexWhere((p) => p['id'] == productId);
            if (cIndex != -1) _cachedMyProducts![cIndex] = updated;
          }
          update();
        }
        if (Get.isRegistered<DataController>()) {
          final dataCtrl = Get.find<DataController>();
          dataCtrl.fetchLatestProducts();
          dataCtrl.fetchFeaturedProducts();
        }
        if (Get.isRegistered<FavoritesController>()) {
          Get.find<FavoritesController>().fetchFavorites();
        }
        final bool notificationSent = res['notificationSent'] ?? true;
        final Color snackColor = updated['isAvailable'] == true
            ? (notificationSent ? AppTheme.primary : Colors.amber.shade900)
            : Colors.grey.shade800;

        Get.snackbar(
          'تحديث توفر المنتج',
          res['message'] ?? 'تم تغيير حالة التوفر بنجاح',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: snackColor,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return true;
      }
      return false;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل في تغيير حالة توفر المنتج: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      togglingProductIds.remove(productId);
    }
  }

  void setFilter(String filter) {
    debugPrint('🎯 Setting filter to: $filter (myProducts total: ${myProducts.length})');
    for (var p in myProducts) {
      debugPrint('   -> Product "${p['title']}": status = "${p['status']}"');
    }
    selectedFilter.value = filter;
    update();
  }

  int get activeProductsCount {
    return myProducts.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'APPROVED').length;
  }

  int get pendingProductsCount {
    return myProducts.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
  }

  int get rejectedProductsCount {
    return myProducts.where((p) {
      final status = (p['status'] ?? '').toString().toUpperCase();
      return status == 'REJECTED' || status == 'SUSPENDED';
    }).length;
  }

  int get revisionProductsCount {
    return myProducts.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'NEEDS_REVISION').length;
  }

  bool get isBusinessSuspended {
    final auth = Get.find<AuthController>();
    final userBus = auth.currentUser['business'];
    if (userBus != null && userBus['isActive'] == false) return true;
    if (businessData['isActive'] == false) return true;
    return false;
  }

  String get storeRating {
    double totalRating = 0;
    int ratedCount = 0;
    for (var p in myProducts) {
      final rating = double.tryParse(p['averageRating']?.toString() ?? '0') ?? 0.0;
      if (rating > 0) {
        totalRating += rating;
        ratedCount++;
      }
    }
    return ratedCount > 0 ? (totalRating / ratedCount).toStringAsFixed(1) : '0.0';
  }
}
