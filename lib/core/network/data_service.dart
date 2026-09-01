import 'api_client.dart';

class DataService {
  // Fetch Categories
  static Future<List<dynamic>> getCategories() async {
    try {
      final response = await ApiClient.instance.get('/taxonomy/categories');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Governorates and Cities
  static Future<List<dynamic>> getLocations() async {
    try {
      final response = await ApiClient.instance.get('/taxonomy/locations');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getProducts({
    String? categoryId,
    String? governorateId,
    int? limit,
    String? search,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? featured,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (governorateId != null) queryParams['governorateId'] = governorateId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (limit != null) queryParams['limit'] = limit;
      if (search != null) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (minRating != null) queryParams['minRating'] = minRating;
      if (featured != null) queryParams['featured'] = featured;

      final response = await ApiClient.instance.get(
        '/products',
        queryParameters: queryParams,
      );
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Single Product
  static Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await ApiClient.instance.get('/products/$id');
      return response.data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Business Profile
  static Future<Map<String, dynamic>> getBusinessById(String id) async {
    try {
      final response = await ApiClient.instance.get('/business/$id');
      return response.data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  // Fetch All Businesses (Stores)
  static Future<List<dynamic>> getBusinesses({
    String? governorateId,
    String? search,
    bool? featured,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (governorateId != null) queryParams['governorateId'] = governorateId;
      if (search != null) queryParams['search'] = search;
      if (featured != null) queryParams['featured'] = featured;
      if (limit != null) queryParams['limit'] = limit;

      final response = await ApiClient.instance.get(
        '/business',
        queryParameters: queryParams,
      );
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // Fetch My Business Profile Dashboard (includes all products)
  static Future<Map<String, dynamic>> getMyBusinessDashboard() async {
    try {
      final response = await ApiClient.instance.get('/business/me/dashboard');
      return response.data['data'] ?? {};
    } catch (e) {
      rethrow;
    }
  }

  // Update My Business Profile
  static Future<Map<String, dynamic>> updateMyBusiness(dynamic formData) async {
    try {
      final response = await ApiClient.instance.put(
        '/business',
        data: formData,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Favorites
  static Future<List<dynamic>> getFavorites() async {
    try {
      final response = await ApiClient.instance.get('/interactions/favorites');
      // The backend returns an array of Favorite objects, each containing a product
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // Toggle Favorite
  static Future<void> toggleFavorite(String productId) async {
    try {
      await ApiClient.instance.post(
        '/interactions/favorite',
        data: {'productId': productId},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Add or Edit Review
  static Future<void> addReview(
    String productId,
    int rating,
    String comment,
  ) async {
    try {
      await ApiClient.instance.post(
        '/interactions/review',
        data: {'productId': productId, 'rating': rating, 'comment': comment},
      );
    } catch (e) {
      rethrow;
    }
  }

  // Add Report
  static Future<void> addReport(
    String targetType,
    String targetId,
    String reason,
  ) async {
    try {
      await ApiClient.instance.post(
        '/interactions/report',
        data: {
          'targetType': targetType,
          'targetId': targetId,
          'reason': reason,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Notifications
  static Future<List<dynamic>> getNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }

  // Mark Notification as Read
  static Future<void> markNotificationAsRead(String id) async {
    try {
      await ApiClient.instance.patch('/notifications/$id/read');
    } catch (e) {
      rethrow;
    }
  }

  // Mark All Notifications as Read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      await ApiClient.instance.patch('/notifications/read-all');
    } catch (e) {
      rethrow;
    }
  }

  // Delete Single Notification
  static Future<void> deleteNotification(String id) async {
    try {
      await ApiClient.instance.delete('/notifications/$id');
    } catch (e) {
      rethrow;
    }
  }

  // Delete All Notifications
  static Future<void> deleteAllNotifications() async {
    try {
      await ApiClient.instance.delete('/notifications/delete-all');
    } catch (e) {
      rethrow;
    }
  }

  // Generate AI Marketing Ad for product
  static Future<List<String>> generateAiAd(String productId) async {
    try {
      final response = await ApiClient.instance.post(
        '/ai/generate-ad',
        data: {'productId': productId},
      );
      final List<dynamic> adsData = response.data['data']?['ads'] ?? [];
      return adsData.map((e) => e.toString()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Units of Sale
  static Future<List<dynamic>> getUnitsOfSale() async {
    try {
      final response = await ApiClient.instance.get('/taxonomy/units');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }

  // Fetch Public App Configuration (Support & Developer contacts)
  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final response = await ApiClient.instance.get('/config');
      return response.data['data'] ?? {};
    } catch (e) {
      return {};
    }
  }

  // Fetch Active Advertisements
  static Future<List<dynamic>> getAds() async {
    try {
      final response = await ApiClient.instance.get('/ads');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
