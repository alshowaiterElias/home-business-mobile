import 'package:flutter/material.dart';
import '../core/network/api_client.dart';

/// Centralised category model used across the entire app.
class Category {
  final String id;
  final String nameAr;
  final IconData icon;
  final Color color;
  final int productCount;
  final List<Category> children;

  const Category({
    required this.id,
    required this.nameAr,
    required this.icon,
    required this.color,
    this.productCount = 0,
    this.children = const [],
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Map backend icon string to Flutter IconData
    IconData getIcon(String? iconName) {
      switch (iconName) {
        case 'restaurant':
          return Icons.restaurant_rounded;
        case 'checkroom':
          return Icons.checkroom_rounded;
        case 'spa':
          return Icons.spa_rounded;
        case 'palette':
          return Icons.palette_rounded;
        case 'weekend':
          return Icons.weekend_rounded;
        case 'face':
          return Icons.face_retouching_natural;
        default:
          return Icons.category_rounded;
      }
    }

    // Map some generic colors based on ID or Name
    final colors = [
      const Color(0xFFFF7043),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
      const Color(0xFF26A69A),
      const Color(0xFF5C6BC0),
      const Color(0xFFEF5350),
    ];
    final color = colors[json['nameAr'].hashCode % colors.length];

    final children =
        (json['children'] as List<dynamic>?)
            ?.map((childJson) => Category.fromJson(childJson))
            .toList() ??
        [];

    return Category(
      id: json['id'] ?? '',
      nameAr: json['nameAr'] ?? '',
      icon: getIcon(json['iconUrl']),
      color: color,
      productCount: json['_count']?['products'] ?? 0,
      children: children,
    );
  }
}

/// Product model — enriched with rating, location, and review data.
class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String sellerName;
  final String sellerAvatar;
  final String location;
  final double rating;
  final int reviewCount;
  final bool isFavorited;
  final String categoryName;
  final String businessId;
  final String sellerUserId;
  final String sellerPhone;
  final DateTime createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sellerName,
    this.sellerAvatar = '',
    this.location = 'صنعاء',
    this.rating = 0,
    this.reviewCount = 0,
    this.isFavorited = false,
    this.categoryName = '',
    this.businessId = '',
    this.sellerUserId = '',
    this.sellerPhone = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultDate();

  factory Product.fromJson(Map<String, dynamic> json) {
    String imgUrl = 'https://via.placeholder.com/800';
    if (json['images'] != null && (json['images'] as List).isNotEmpty) {
      imgUrl = ApiClient.getImageUrl(json['images'][0]['imageUrl']);
    } else if (json['imageUrl'] != null) {
      imgUrl = ApiClient.getImageUrl(json['imageUrl']);
    }

    String seller = 'متجر';
    String loc = 'اليمن';
    String bizId = '';
    String sUserId = '';
    String phone = '';
    if (json['business'] != null) {
      bizId = json['business']['id'] ?? '';
      sUserId = json['business']['userId'] ?? '';
      seller = json['business']['businessName'] ?? seller;
      phone = json['business']['contactPhone'] ?? phone;
      if (json['business']['city'] != null) {
        loc = json['business']['city']['nameAr'] ?? loc;
      }
    }

    return Product(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      imageUrl: imgUrl,
      sellerName: seller,
      location: loc,
      rating: double.tryParse(json['averageRating']?.toString() ?? '0') ?? 0,
      reviewCount: json['reviewsCount'] ?? 0,
      categoryName: json['category']?['nameAr'] ?? '',
      businessId: bizId,
      sellerUserId: sUserId,
      sellerPhone: phone,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}

/// Helper so `createdAt` can have a const default.
class _DefaultDate implements DateTime {
  const _DefaultDate();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      DateTime.now().noSuchMethod(invocation);
}
