import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/utils/category_icon_helper.dart';

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
      icon: CategoryIconHelper.getIcon(json['iconUrl']),
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
  final bool isSellerVerified;
  final bool isBoosted;
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
    this.isSellerVerified = false,
    this.isBoosted = false,
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
    bool isVerified = false;
    if (json['business'] != null) {
      bizId = json['business']['id'] ?? '';
      sUserId = json['business']['userId'] ?? '';
      seller = json['business']['businessName'] ?? seller;
      phone = json['business']['contactPhone'] ?? phone;
      isVerified = json['business']['isVerified'] == true ||
          json['business']['is_verified'] == true;
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
      isSellerVerified: isVerified,
      isBoosted: json['isBoosted'] == true || json['is_boosted'] == true,
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
