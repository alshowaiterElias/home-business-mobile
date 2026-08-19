import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_client.dart';
import '../core/network/error_handler.dart';
import 'seller_dashboard_controller.dart';
import 'package:dio/dio.dart' as dio;

class AddProductController extends GetxController {
  var isLoading = false.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();

  var selectedUnit = 'حبة'.obs;
  var selectedCurrency = 'YER'.obs;
  var selectedCategoryId = ''.obs;
  var selectedSubCategoryId = ''.obs;

  var images = <File>[].obs;

  final units = ['حبة', 'كيلو', 'درزن', 'لتر', 'جرام', 'مجموعة'];
  final currencies = ['YER', 'SAR', 'USD'];

  Future<void> pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    
    if (picked.isNotEmpty) {
      if (images.length + picked.length > 5) {
        Get.snackbar('تنبيه', 'يمكنك إضافة 5 صور كحد أقصى', backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      images.addAll(picked.map((x) => File(x.path)));
    }
  }

  void removeImage(int index) {
    images.removeAt(index);
  }

  Future<void> submitProduct() async {
    if (titleController.text.isEmpty || priceController.text.isEmpty || selectedCategoryId.value.isEmpty || images.isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة الحقول المطلوبة وإضافة صورة واحدة على الأقل', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final categoryId = selectedSubCategoryId.value.isNotEmpty ? selectedSubCategoryId.value : selectedCategoryId.value;

      final formData = dio.FormData.fromMap({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'price': priceController.text.trim(),
        'categoryId': categoryId,
        'unitOfSale': selectedUnit.value,
        'currency': selectedCurrency.value,
      });

      for (var file in images) {
        formData.files.add(MapEntry(
          'productImages',
          await dio.MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
        ));
      }

      final response = await ApiClient.instance.post('/products', data: formData);
      
      if (response.data['success'] == true) {
        // Refresh the seller dashboard so the new product appears immediately
        if (Get.isRegistered<SellerDashboardController>()) {
          Get.find<SellerDashboardController>().fetchDashboardData();
        }
        Get.back(); // close screen
        Get.snackbar('تم الإرسال', 'تمت إضافة منتجك وهو قيد المراجعة',
            backgroundColor: Colors.green, colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
      }
    } catch (e) {
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ في الإضافة', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } finally {
      isLoading.value = false;
    }
  }
}
