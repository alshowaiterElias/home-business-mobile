import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/data_service.dart';
import '../core/network/api_client.dart';
import '../core/network/error_handler.dart';
import 'auth_controller.dart';
import 'data_controller.dart';
import 'package:dio/dio.dart' as dio;

class CreateStoreController extends GetxController {
  var isLoading = false.obs;
  var locations = [].obs;
  var selectedGovId = ''.obs;
  var selectedCityId = ''.obs;

  final businessNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  var logoFile = Rxn<File>();

  @override
  void onInit() {
    super.onInit();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      final data = await DataService.getLocations();
      locations.assignAll(data);
    } catch (e) {
      print('Error loading locations: $e');
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      logoFile.value = File(picked.path);
    }
  }

  Future<void> createStore() async {
    if (businessNameController.text.isEmpty || phoneController.text.isEmpty || selectedCityId.value.isEmpty) {
      Get.snackbar('خطأ', 'يرجى تعبئة جميع الحقول المطلوبة', backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    isLoading.value = true;
    try {
      final formattedPhone = '+967${phoneController.text.trim()}';

      final formData = dio.FormData.fromMap({
        'businessName': businessNameController.text.trim(),
        'description': descriptionController.text.trim(),
        'contactPhone': formattedPhone,
        'cityId': selectedCityId.value,
        'addressDetails': addressController.text.trim(),
      });

      if (logoFile.value != null) {
        formData.files.add(MapEntry(
          'logo',
          await dio.MultipartFile.fromFile(logoFile.value!.path, filename: 'logo.jpg'),
        ));
      }

      final response = await ApiClient.instance.post('/business', data: formData);
      if (response.data['success'] == true) {
        final authController = Get.find<AuthController>();
        authController.createStore();
        
        // Refresh auth profile so currentUser includes the new business data
        authController.fetchProfile();
        
        // Refresh the stores list on the home screen
        if (Get.isRegistered<DataController>()) {
          Get.find<DataController>().fetchTopStores();
        }
        
        Get.offNamed('/seller-dashboard');
        Get.snackbar(
          'تم بنجاح', 'تم إنشاء متجرك. يمكنك الآن إضافة المنتجات.',
          backgroundColor: Colors.green, colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16)
        );
      }
    } catch (e) {
      final errorMsg = ApiErrorHandler.handle(e);
      Get.snackbar('خطأ في إنشاء المتجر', errorMsg, backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 4));
    } finally {
      isLoading.value = false;
    }
  }
}
