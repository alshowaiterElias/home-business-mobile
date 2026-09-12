import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class CollectionService {
  static List<dynamic>? _cachedMyCollections;
  static final Map<String, List<dynamic>> _cachedStoreCollections = {};

  static List<dynamic>? get cachedMyCollections => _cachedMyCollections;

  static List<dynamic>? getCachedStoreCollections(String businessId) =>
      _cachedStoreCollections[businessId];

  static void invalidateMyCollections() {
    _cachedMyCollections = null;
  }

  static void invalidateStoreCollections([String? businessId]) {
    if (businessId != null) {
      _cachedStoreCollections.remove(businessId);
    } else {
      _cachedStoreCollections.clear();
    }
  }

  /// Public: Fetch featured collections for homepage
  static Future<List<dynamic>> getFeaturedCollections() async {
    try {
      final response = await ApiClient.instance.get('/collections/featured');
      return response.data['data'] as List<dynamic>? ?? [];
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CollectionService] getFeaturedCollections error: $e');
      return [];
    }
  }

  /// Public: Fetch collections for a specific store
  static Future<List<dynamic>> getStoreCollections(
    String businessId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cachedStoreCollections.containsKey(businessId)) {
      return _cachedStoreCollections[businessId]!;
    }
    try {
      final response = await ApiClient.instance.get('/collections/store/$businessId');
      final list = response.data['data'] as List<dynamic>? ?? [];
      _cachedStoreCollections[businessId] = list;
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CollectionService] getStoreCollections error: $e');
      return _cachedStoreCollections[businessId] ?? [];
    }
  }

  /// Public: Fetch single collection detail with products
  static Future<Map<String, dynamic>> getCollectionById(String id) async {
    final response = await ApiClient.instance.get('/collections/$id');
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  /// Seller: Fetch own collections with in-memory caching
  static Future<List<dynamic>> getMyCollections({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedMyCollections != null) {
      return _cachedMyCollections!;
    }
    try {
      final response = await ApiClient.instance.get('/collections/my-collections');
      final list = response.data['data'] as List<dynamic>? ?? [];
      _cachedMyCollections = list;
      return list;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ [CollectionService] getMyCollections error: $e');
      return _cachedMyCollections ?? [];
    }
  }

  /// Seller: Create a new collection
  static Future<Map<String, dynamic>> createCollection({
    required String title,
    String? description,
    File? coverFile,
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('title', title));
    if (description != null && description.isNotEmpty) {
      formData.fields.add(MapEntry('description', description));
    }
    if (coverFile != null) {
      formData.files.add(
        MapEntry(
          'cover',
          await MultipartFile.fromFile(
            coverFile.path,
            filename: coverFile.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    final response = await ApiClient.instance.post('/collections', data: formData);
    invalidateMyCollections();
    invalidateStoreCollections();
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  /// Seller: Update collection
  static Future<Map<String, dynamic>> updateCollection(
    String id, {
    String? title,
    String? description,
    bool? isActive,
    File? coverFile,
  }) async {
    final formData = FormData();
    if (title != null) formData.fields.add(MapEntry('title', title));
    if (description != null) formData.fields.add(MapEntry('description', description));
    if (isActive != null) formData.fields.add(MapEntry('isActive', isActive.toString()));
    if (coverFile != null) {
      formData.files.add(
        MapEntry(
          'cover',
          await MultipartFile.fromFile(
            coverFile.path,
            filename: coverFile.path.split(Platform.pathSeparator).last,
          ),
        ),
      );
    }

    final response = await ApiClient.instance.put('/collections/$id', data: formData);
    invalidateMyCollections();
    invalidateStoreCollections();
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  /// Seller: Delete collection
  static Future<void> deleteCollection(String id) async {
    await ApiClient.instance.delete('/collections/$id');
    invalidateMyCollections();
    invalidateStoreCollections();
  }

  /// Seller: Add product to collection
  static Future<Map<String, dynamic>> addItem(String collectionId, String productId) async {
    final response = await ApiClient.instance.post(
      '/collections/$collectionId/items',
      data: {'productId': productId},
    );
    invalidateMyCollections();
    invalidateStoreCollections();
    return response.data['data'] as Map<String, dynamic>? ?? {};
  }

  /// Seller: Remove product from collection
  static Future<void> removeItem(String collectionId, String productId) async {
    await ApiClient.instance.delete('/collections/$collectionId/items/$productId');
    invalidateMyCollections();
    invalidateStoreCollections();
  }

  /// Seller: Reorder products in collection
  static Future<void> reorderItems(String collectionId, List<String> productIds) async {
    await ApiClient.instance.put(
      '/collections/$collectionId/items/reorder',
      data: {'productIds': productIds},
    );
    invalidateMyCollections();
    invalidateStoreCollections();
  }
}
