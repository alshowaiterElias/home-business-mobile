import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/data_service.dart';
import '../models/dummy_data.dart';
import 'auth_controller.dart';

class FavoritesController extends GetxController {
  var favorites = <Product>[].obs;
  var followedStores = <dynamic>[].obs;
  var followedStoreIds = <String>{}.obs;
  var isLoading = false.obs;
  var isLoadingStores = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to fetch favorites & followed stores when user logs in
    final auth = Get.find<AuthController>();
    ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchFavorites();
        fetchFollowedStores();
      } else {
        favorites.clear();
        followedStores.clear();
        followedStoreIds.clear();
        DataService.clearFollowedStores();
      }
    });
    
    if (auth.isLoggedIn.value) {
      fetchFavorites();
      fetchFollowedStores();
    }
  }

  bool isStoreFollowed(String storeId) {
    return followedStoreIds.contains(storeId);
  }

  Future<void> fetchFollowedStores() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return;

    isLoadingStores.value = true;
    try {
      final stores = await DataService.getFollowedStores();
      followedStores.assignAll(stores);
      followedStoreIds.assignAll(stores.map((s) => s['id'].toString()));
    } catch (e) {
      debugPrint('Error fetching followed stores: $e');
    } finally {
      isLoadingStores.value = false;
    }
  }

  void setStoreFollowed(String storeId, bool followed, [Map<String, dynamic>? storeData]) {
    if (followed) {
      followedStoreIds.add(storeId);
      if (storeData != null && !followedStores.any((s) => s['id'] == storeId)) {
        followedStores.insert(0, storeData);
      }
    } else {
      followedStoreIds.remove(storeId);
      followedStores.removeWhere((s) => s['id'] == storeId);
    }
    DataService.setStoreFollowed(storeId, followed);
  }

  Future<void> fetchFavorites() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return;

    isLoading.value = true;
    try {
      final data = await DataService.getFavorites();
      final List<Product> parsed = data
          .where((item) =>
              item['product'] != null &&
              item['product']['isAvailable'] != false &&
              (item['product']['status'] == null ||
                  item['product']['status'] == 'APPROVED'))
          .map((item) {
        final productJson = item['product'];
        final p = Product.fromJson(productJson);
        return Product(
          id: p.id,
          title: p.title,
          description: p.description,
          price: p.price,
          imageUrl: p.imageUrl,
          sellerName: p.sellerName,
          location: p.location,
          rating: p.rating,
          reviewCount: p.reviewCount,
          categoryName: p.categoryName,
          businessId: p.businessId,
          isFavorited: true,
        );
      }).toList();
      favorites.assignAll(parsed);
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(Product product) async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) {
      Get.toNamed('/auth');
      return;
    }

    try {
      final currentlyFavorited = isFavorited(product.id);
      
      // Optimistic update
      if (currentlyFavorited) {
        favorites.removeWhere((p) => p.id == product.id);
      } else {
        favorites.add(Product(
          id: product.id,
          title: product.title,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          sellerName: product.sellerName,
          location: product.location,
          rating: product.rating,
          reviewCount: product.reviewCount,
          categoryName: product.categoryName,
          businessId: product.businessId,
          isFavorited: true,
        ));
      }
      
      await DataService.toggleFavorite(product.id);
      
      Get.snackbar(
        'المفضلة',
        currentlyFavorited ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      // Revert on error
      await fetchFavorites();
    }
  }

  bool isFavorited(String productId) {
    return favorites.any((p) => p.id == productId);
  }
}
