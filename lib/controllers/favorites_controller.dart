import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/network/data_service.dart';
import '../models/dummy_data.dart';
import 'auth_controller.dart';

class FavoritesController extends GetxController {
  var favorites = <Product>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth changes to fetch favorites when user logs in
    final auth = Get.find<AuthController>();
    ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchFavorites();
      } else {
        favorites.clear();
      }
    });
    
    if (auth.isLoggedIn.value) {
      fetchFavorites();
    }
  }

  Future<void> fetchFavorites() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return;

    isLoading.value = true;
    try {
      final data = await DataService.getFavorites();
      final List<Product> parsed = data.map((item) {
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
