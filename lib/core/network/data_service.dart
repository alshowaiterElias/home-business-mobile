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

  // In-memory caches to prevent redundant network requests and UI flickering
  static final Map<String, Map<String, dynamic>> _productCache = {};
  static final Map<String, Future<Map<String, dynamic>>> _inFlightProductRequests = {};

  static final Map<String, Map<String, dynamic>> _businessCache = {};
  static final Map<String, Future<Map<String, dynamic>>> _inFlightBusinessRequests = {};
  static Map<String, dynamic>? _myBusinessDashboardCache;

  // Track globally followed store IDs for instant 0ms follow state resolution
  static final Set<String> _followedStoreIds = {};
  static bool hasLoadedFollowedStores = false;

  static bool? isStoreFollowed(String storeId) {
    if (!hasLoadedFollowedStores) return null;
    return _followedStoreIds.contains(storeId);
  }

  static void setStoreFollowed(String storeId, bool followed) {
    if (followed) {
      _followedStoreIds.add(storeId);
    } else {
      _followedStoreIds.remove(storeId);
    }
  }

  static void clearFollowedStores() {
    _followedStoreIds.clear();
    hasLoadedFollowedStores = false;
  }

  // Fetch Single Product with in-memory caching & request deduplication
  static Future<Map<String, dynamic>> getProductById(String id) async {
    if (_productCache.containsKey(id)) {
      return _productCache[id]!;
    }
    if (_inFlightProductRequests.containsKey(id)) {
      return _inFlightProductRequests[id]!;
    }

    final future = _fetchAndCacheProduct(id);
    _inFlightProductRequests[id] = future;
    return future;
  }

  static Future<Map<String, dynamic>> _fetchAndCacheProduct(String id) async {
    try {
      final response = await ApiClient.instance.get('/products/$id');
      final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
      if (data.isNotEmpty) {
        _productCache[id] = data;
      }
      return data;
    } catch (e) {
      rethrow;
    } finally {
      _inFlightProductRequests.remove(id);
    }
  }

  // Fetch Business Profile with in-memory caching & request deduplication
  static Future<Map<String, dynamic>> getBusinessById(
    String id, {
    bool forceRefresh = false,
  }) async {
    // Only return cached business if it has full profile data and not forcing refresh
    if (!forceRefresh &&
        _businessCache.containsKey(id) &&
        _businessCache[id]?['_isFull'] == true) {
      return _businessCache[id]!;
    }
    if (_inFlightBusinessRequests.containsKey(id)) {
      return _inFlightBusinessRequests[id]!;
    }

    final future = _fetchAndCacheBusiness(id);
    _inFlightBusinessRequests[id] = future;
    return future;
  }

  /// Get synchronously cached business data if present
  static Map<String, dynamic>? getCachedBusiness(String id) {
    return _businessCache[id];
  }

  /// Prime or update the business cache in memory
  static void cacheBusiness(String id, Map<String, dynamic> data) {
    if (data.isNotEmpty) {
      final products = data['products'] as List<dynamic>?;
      final bool hasFullProducts = products != null &&
          products.isNotEmpty &&
          products.any((p) {
            if (p is Map) {
              final title = p['title']?.toString();
              return title != null && title.trim().isNotEmpty;
            }
            return false;
          });

      if (data['_isFull'] == true || hasFullProducts) {
        final fullData = Map<String, dynamic>.from(data);
        fullData['_isFull'] = true;
        _businessCache[id] = fullData;
      } else {
        // Only store partial data if we don't already have a full profile cached
        if (!_businessCache.containsKey(id) || _businessCache[id]?['_isFull'] != true) {
          final partialData = Map<String, dynamic>.from(data);
          partialData['_isFull'] = false;
          _businessCache[id] = partialData;
        }
      }
    }
  }

  static Future<Map<String, dynamic>> _fetchAndCacheBusiness(String id) async {
    try {
      final response = await ApiClient.instance.get('/business/$id');
      final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
      if (data.isNotEmpty) {
        data['_isFull'] = true;
        _businessCache[id] = data;
      }
      return data;
    } catch (e) {
      rethrow;
    } finally {
      _inFlightBusinessRequests.remove(id);
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

  // Toggle Follow / Unfollow Store
  static Future<Map<String, dynamic>> toggleFollowStore(String businessId) async {
    try {
      final response = await ApiClient.instance.post('/business/$businessId/follow');
      final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
      final isFollowed = data['isFollowed'] == true;

      setStoreFollowed(businessId, isFollowed);

      // Keep cache in sync so store screen retains follow state upon revisit
      if (_businessCache.containsKey(businessId)) {
        _businessCache[businessId]!['isFollowed'] = isFollowed;
        if (data['followersCount'] != null) {
          _businessCache[businessId]!['followersCount'] = data['followersCount'];
        }
      } else {
        _businessCache[businessId] = {
          'id': businessId,
          'isFollowed': isFollowed,
          if (data['followersCount'] != null) 'followersCount': data['followersCount'],
        };
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // Get Followed Stores List
  static Future<List<dynamic>> getFollowedStores() async {
    try {
      final response = await ApiClient.instance.get('/business/followed');
      final list = (response.data['data'] as List<dynamic>?) ?? [];
      _followedStoreIds.clear();
      for (final s in list) {
        if (s is Map && s['id'] != null) {
          final id = s['id'].toString();
          _followedStoreIds.add(id);
          // Prime individual store cache as well
          cacheBusiness(id, {
            ...s,
            'isFollowed': true,
          });
        }
      }
      hasLoadedFollowedStores = true;
      return list;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch My Business Profile Dashboard (includes all products)
  static Future<Map<String, dynamic>> getMyBusinessDashboard({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _myBusinessDashboardCache != null) {
      return _myBusinessDashboardCache!;
    }
    try {
      final response = await ApiClient.instance.get('/business/me/dashboard');
      final data = (response.data['data'] as Map<String, dynamic>?) ?? {};
      if (data.isNotEmpty) {
        _myBusinessDashboardCache = data;
      }
      return data;
    } catch (e) {
      rethrow;
    }
  }

  static void invalidateMyBusinessDashboard() {
    _myBusinessDashboardCache = null;
  }

  // Update My Business Profile
  static Future<Map<String, dynamic>> updateMyBusiness(dynamic formData) async {
    try {
      final response = await ApiClient.instance.put(
        '/business',
        data: formData,
      );
      invalidateMyBusinessDashboard();
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

  // Fetch Report Reasons
  static Future<List<String>> getReportReasons(String targetType) async {
    try {
      final response = await ApiClient.instance.get(
        '/taxonomy/report-reasons',
        queryParameters: {'targetType': targetType},
      );
      final List data = response.data['data'] ?? [];
      return data.map((item) => item['reasonAr'].toString()).toList();
    } catch (e) {
      return [];
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

  // Toggle Product Availability (Store owner)
  static Future<Map<String, dynamic>> toggleProductAvailability(
    String productId,
  ) async {
    try {
      final response = await ApiClient.instance.patch(
        '/products/$productId/availability',
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch Seller Store Analytics
  static Future<Map<String, dynamic>> getMyStoreAnalytics({int days = 30}) async {
    try {
      final response = await ApiClient.instance.get(
        '/analytics/my-store',
        queryParameters: {'days': days},
      );
      return response.data['data'] as Map<String, dynamic>? ?? {};
    } catch (e) {
      rethrow;
    }
  }
}
