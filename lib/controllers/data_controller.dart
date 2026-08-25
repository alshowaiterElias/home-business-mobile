import 'package:get/get.dart';
import '../core/network/data_service.dart';
import '../core/network/error_handler.dart';

class DataController extends GetxController {
  var isLoadingCategories = false.obs;
  var isLoadingProducts = false.obs;
  var isLoadingFeaturedProducts = false.obs;
  var isLoadingFeaturedStores = false.obs;
  var isLoadingStores = false.obs;
  
  var categories = <dynamic>[].obs;
  var latestProducts = <dynamic>[].obs;
  var featuredProducts = <dynamic>[].obs;
  var featuredStores = <dynamic>[].obs;
  var locations = <dynamic>[].obs;
  var topStores = <dynamic>[].obs;

  // System Contacts
  var supportPhone = '+967772546343'.obs;
  var supportEmail = 'alshowaiterelias@gmail.com'.obs;
  var developerPhone = '+967772546343'.obs;
  var developerEmail = 'alshowaiterelias@gmail.com'.obs;

  @override
  void onInit() {
    super.onInit();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await Future.wait([
      fetchAppConfig(),
      fetchCategories(),
      fetchFeaturedProducts(),
      fetchFeaturedStores(),
      fetchLatestProducts(),
      fetchLocations(),
      fetchTopStores(),
    ]);
  }

  Future<void> fetchAppConfig() async {
    try {
      final config = await DataService.getAppConfig();
      if (config['supportPhone'] != null && config['supportPhone'].toString().trim().isNotEmpty) {
        supportPhone.value = config['supportPhone'].toString().trim();
      }
      if (config['supportEmail'] != null && config['supportEmail'].toString().trim().isNotEmpty) {
        supportEmail.value = config['supportEmail'].toString().trim();
      }
      if (config['developerPhone'] != null && config['developerPhone'].toString().trim().isNotEmpty) {
        developerPhone.value = config['developerPhone'].toString().trim();
      }
      if (config['developerEmail'] != null && config['developerEmail'].toString().trim().isNotEmpty) {
        developerEmail.value = config['developerEmail'].toString().trim();
      }
    } catch (e) {
      print('Error fetching app config: $e');
    }
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

  Future<void> fetchFeaturedProducts() async {
    isLoadingFeaturedProducts.value = true;
    try {
      final data = await DataService.getProducts(featured: true, limit: 10);
      featuredProducts.assignAll(data);
    } catch (e) {
      print('Error fetching featured products: ${ApiErrorHandler.handle(e)}');
    } finally {
      isLoadingFeaturedProducts.value = false;
    }
  }

  Future<void> fetchFeaturedStores() async {
    isLoadingFeaturedStores.value = true;
    try {
      final data = await DataService.getBusinesses(featured: true, limit: 10);
      featuredStores.assignAll(data);
    } catch (e) {
      print('Error fetching featured stores: ${ApiErrorHandler.handle(e)}');
    } finally {
      isLoadingFeaturedStores.value = false;
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
