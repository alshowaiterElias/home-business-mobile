import 'package:get/get.dart';
import '../core/network/data_service.dart';
import '../core/network/error_handler.dart';

class DataController extends GetxController {
  var isLoadingCategories = false.obs;
  var isLoadingProducts = false.obs;
  
  var categories = <dynamic>[].obs;
  var latestProducts = <dynamic>[].obs;
  var locations = <dynamic>[].obs;
  var topStores = <dynamic>[].obs;
  var isLoadingStores = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await Future.wait([
      fetchCategories(),
      fetchLatestProducts(),
      fetchLocations(),
      fetchTopStores(),
    ]);
  }

  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final data = await DataService.getCategories();
      categories.assignAll(data);
    } catch (e) {
      print('Error fetching categories: ${ApiErrorHandler.handle(e)}');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  Future<void> fetchLatestProducts() async {
    isLoadingProducts.value = true;
    try {
      final data = await DataService.getProducts(limit: 10);
      latestProducts.assignAll(data);
    } catch (e) {
      print('Error fetching products: ${ApiErrorHandler.handle(e)}');
    } finally {
      isLoadingProducts.value = false;
    }
  }

  Future<void> fetchLocations() async {
    try {
      final data = await DataService.getLocations();
      locations.assignAll(data);
    } catch (e) {
      print('Error fetching locations: ${ApiErrorHandler.handle(e)}');
    }
  }

  Future<void> fetchTopStores() async {
    isLoadingStores.value = true;
    try {
      final data = await DataService.getBusinesses();
      topStores.assignAll(data);
    } catch (e) {
      print('Error fetching top stores: ${ApiErrorHandler.handle(e)}');
    } finally {
      isLoadingStores.value = false;
    }
  }
}
