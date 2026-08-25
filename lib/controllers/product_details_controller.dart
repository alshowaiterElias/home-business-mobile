import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'auth_controller.dart';
import '../models/dummy_data.dart';
import '../core/network/data_service.dart';
import '../core/network/error_handler.dart';
import 'favorites_controller.dart';

class ReviewModel {
  String id;
  String userId;
  String name;
  int rating;
  String? text;
  String date;

  ReviewModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.rating,
    this.text,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['user']?['phoneNumber'] ?? 'مستخدم', // Using phone number as mock name
      rating: json['rating'] ?? 5,
      text: json['comment'],
      date: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toString().substring(0, 10) 
          : 'الآن',
    );
  }
}

class ProductDetailsController extends GetxController {
  final String productId;
  
  // Mock data for existing reviews
  var reviews = <ReviewModel>[].obs;
  
  // The current user's review (if they have one)
  var myReview = Rx<ReviewModel?>(null);
  
  // Flag if the product belongs to the current user
  var isMyProduct = false.obs;

  // Form state
  var isEditing = false.obs;
  var currentRating = 0.obs;
  final commentController = TextEditingController();

  // Real-time product metrics
  var currentProductRating = 0.0.obs;
  var currentProductReviewCount = 0.obs;

  ProductDetailsController({required this.productId});

  @override
  void onInit() {
    super.onInit();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      final productData = await DataService.getProductById(productId);
      
      currentProductRating.value = double.tryParse(productData['averageRating']?.toString() ?? '0') ?? 0;
      currentProductReviewCount.value = productData['reviewsCount'] ?? 0;

      final backendReviews = (productData['reviews'] as List<dynamic>?) ?? [];
      
      final auth = Get.find<AuthController>();
      final currentUserPhone = auth.currentUser['phoneNumber'];
      final currentUserId = auth.currentUser['id'];

      final parsedReviews = backendReviews.map((r) => ReviewModel.fromJson(r)).toList();
      reviews.assignAll(parsedReviews);

      // Check if product belongs to current user
      if (auth.isLoggedIn.value && auth.currentUser['business'] != null) {
        if (productData['businessId'] == auth.currentUser['business']['id']) {
          isMyProduct.value = true;
        }
      }

      // Find my review
      if (auth.isLoggedIn.value) {
        try {
          final mine = parsedReviews.firstWhere(
            (r) => r.userId == currentUserId || r.name == currentUserPhone
          );
          myReview.value = mine;
        } catch (e) {
          myReview.value = null;
        }
      }
      // Update favorite state if user is logged in
      if (auth.isLoggedIn.value) {
        // Quick check: fetch favorites to see if this is favorited
        // In a real production app, backend getProductById should return whether current user favorited it
        // Or we just rely on the initial passed product model, but here we can try to find it
      }
    } catch (e) {
      debugPrint('Error fetching product details: $e');
    }
  }

  bool get isFavorited {
    if (Get.isRegistered<FavoritesController>()) {
      return Get.find<FavoritesController>().isFavorited(productId);
    }
    return false;
  }

  Future<void> toggleFavorite(Product product) async {
    if (Get.isRegistered<FavoritesController>()) {
      await Get.find<FavoritesController>().toggleFavorite(product);
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }

  void startEditing() {
    if (myReview.value != null) {
      currentRating.value = myReview.value!.rating;
      commentController.text = myReview.value!.text ?? '';
    } else {
      currentRating.value = 0;
      commentController.clear();
    }
    isEditing.value = true;
  }

  void cancelEditing() {
    isEditing.value = false;
  }

  Future<void> submitReview() async {
    final auth = Get.find<AuthController>();
    if (!auth.isLoggedIn.value) return;

    if (currentRating.value == 0) {
      Get.snackbar(
        'تنبيه',
        'الرجاء اختيار تقييم',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isEditing.value = false;
      await DataService.addReview(
        productId,
        currentRating.value,
        commentController.text.trim(),
      );

      Get.snackbar(
        'تم بنجاح',
        'تم حفظ التقييم',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Re-fetch to get updated reviews list
      await fetchProductDetails();
    } catch (e) {
      isEditing.value = true;
      Get.snackbar(
        'خطأ',
        ApiErrorHandler.handle(e),
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }
}
