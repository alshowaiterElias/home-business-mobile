import 'package:get/get.dart';
import '../core/network/data_service.dart';

class SellerAnalyticsController extends GetxController {
  static Map<String, dynamic>? _cachedAnalytics;
  static int? _cachedPeriod;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final selectedPeriod = 30.obs; // 7, 14, 30
  final analyticsData = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    if (_cachedAnalytics != null && _cachedAnalytics!.isNotEmpty) {
      analyticsData.value = _cachedAnalytics!;
      selectedPeriod.value = _cachedPeriod ?? 30;
      // Stale data exists: show immediately, do not auto-fetch on screen reopen
    } else {
      // First-time load only
      fetchAnalytics();
    }
  }

  Future<void> setPeriod(int days) async {
    if (selectedPeriod.value == days) return;
    selectedPeriod.value = days;
    await fetchAnalytics(days: days, isManual: true);
  }

  Future<void> fetchAnalytics({int? days, bool isManual = false}) async {
    try {
      if (analyticsData.isEmpty) {
        isLoading.value = true;
      } else {
        isRefreshing.value = true;
      }
      final period = days ?? selectedPeriod.value;
      final data = await DataService.getMyStoreAnalytics(days: period);
      analyticsData.value = data;
      _cachedAnalytics = data;
      _cachedPeriod = period;
    } catch (e) {
      // Keep existing stale data on error
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  // Getters for convenience
  Map<String, dynamic> get overview =>
      (analyticsData['overview'] as Map<String, dynamic>?) ?? {};

  int get totalViews =>
      ((overview['totalProductViews'] as int? ?? 0) +
          (overview['totalStoreViews'] as int? ?? 0));

  int get totalInquiries => overview['totalWhatsAppInquiries'] as int? ?? 0;

  int get totalFavorites => overview['totalFavorites'] as int? ?? 0;

  int get totalFollowers => overview['totalFollowers'] as int? ?? 0;

  double get averageRating =>
      double.tryParse(overview['averageRating']?.toString() ?? '0') ?? 0.0;

  List<dynamic> get productViewsByDay =>
      (analyticsData['trends']?['productViewsByDay'] as List<dynamic>?) ?? [];

  List<dynamic> get inquiriesByDay =>
      (analyticsData['trends']?['inquiriesByDay'] as List<dynamic>?) ?? [];

  List<dynamic> get storeViewsByDay =>
      (analyticsData['trends']?['storeViewsByDay'] as List<dynamic>?) ?? [];

  List<dynamic> get topProducts =>
      (analyticsData['topProducts'] as List<dynamic>?) ?? [];

  List<dynamic> get recentInquiries =>
      (analyticsData['recentInquiries'] as List<dynamic>?) ?? [];

  List<dynamic> get adPerformance =>
      (analyticsData['adPerformance'] as List<dynamic>?) ?? [];
}
