import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/network/data_service.dart';
import 'auth_controller.dart';

class SellerDashboardController extends GetxController {
  var isLoading = false.obs;
  var businessData = {}.obs;
  var myProducts = <dynamic>[].obs;
  var selectedFilter = 'ALL'.obs; // ALL, APPROVED, PENDING, REJECTED, SUSPENDED

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final auth = Get.find<AuthController>();
    final businessInfo = auth.currentUser['business'];
    if (businessInfo == null) return;

    isLoading.value = true;
    try {
      final data = await DataService.getMyBusinessDashboard();
      businessData.value = data;
      
      if (data['products'] != null) {
        myProducts.assignAll(data['products']);
      }
    } catch (e) {
      debugPrint('Error fetching seller dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<dynamic> get filteredProducts {
    final filter = selectedFilter.value.toUpperCase();
    if (filter == 'ALL') return myProducts;
    if (filter == 'REJECTED') {
      return myProducts.where((p) {
        final status = (p['status'] ?? '').toString().toUpperCase();
        return status == 'REJECTED' || status == 'SUSPENDED';
      }).toList();
    }
    return myProducts.where((p) {
      final status = (p['status'] ?? '').toString().toUpperCase();
      return status == filter;
    }).toList();
  }

  void setFilter(String filter) {
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
