import 'package:get/get.dart';
import '../core/network/data_service.dart';
import 'auth_controller.dart';

class SellerDashboardController extends GetxController {
  var isLoading = false.obs;
  var businessData = {}.obs;
  var myProducts = <dynamic>[].obs;

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
      print('Error fetching seller dashboard: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int get activeProductsCount {
    return myProducts.where((p) => p['status'] == 'APPROVED').length;
  }

  int get pendingProductsCount {
    return myProducts.where((p) => p['status'] == 'PENDING').length;
  }

  int get rejectedProductsCount {
    return myProducts.where((p) => p['status'] == 'REJECTED').length;
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
