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
        case 'restaurant': return Icons.restaurant_rounded;
        case 'checkroom': return Icons.checkroom_rounded;
        case 'spa': return Icons.spa_rounded;
        case 'palette': return Icons.palette_rounded;
        case 'weekend': return Icons.weekend_rounded;
        case 'face': return Icons.face_retouching_natural;
        default: return Icons.category_rounded;
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

    final children = (json['children'] as List<dynamic>?)
        ?.map((childJson) => Category.fromJson(childJson))
        .toList() ?? [];

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
    String phone = '';
    if (json['business'] != null) {
      bizId = json['business']['id'] ?? '';
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
      sellerPhone: phone,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}

/// Helper so `createdAt` can have a const default.
class _DefaultDate implements DateTime {
  const _DefaultDate();
  @override dynamic noSuchMethod(Invocation invocation) => DateTime.now().noSuchMethod(invocation);
}

// ─── Dummy Categories ───────────────────────────────────────────
const List<Category> dummyCategories = [
  Category(id: '1', nameAr: 'مأكولات',        icon: Icons.restaurant_rounded,  color: Color(0xFFFF7043), productCount: 42, children: [
    Category(id: '1a', nameAr: 'حلويات',       icon: Icons.cake_rounded,        color: Color(0xFFEC407A), productCount: 18),
    Category(id: '1b', nameAr: 'معجنات',       icon: Icons.bakery_dining,       color: Color(0xFFFF8A65), productCount: 14),
    Category(id: '1c', nameAr: 'وجبات رئيسية', icon: Icons.lunch_dining,        color: Color(0xFFFF7043), productCount: 10),
  ]),
  Category(id: '2', nameAr: 'ملابس وأزياء',    icon: Icons.checkroom_rounded,   color: Color(0xFF42A5F5), productCount: 35),
  Category(id: '3', nameAr: 'عطور وبخور',      icon: Icons.spa_rounded,         color: Color(0xFFAB47BC), productCount: 28),
  Category(id: '4', nameAr: 'مشغولات يدوية',   icon: Icons.palette_rounded,     color: Color(0xFF26A69A), productCount: 19),
  Category(id: '5', nameAr: 'مستلزمات منزلية', icon: Icons.weekend_rounded,     color: Color(0xFF5C6BC0), productCount: 23),
  Category(id: '6', nameAr: 'مستحضرات تجميل',  icon: Icons.face_retouching_natural, color: Color(0xFFEF5350), productCount: 16),
];

// ─── Dummy Products ─────────────────────────────────────────────
final List<Product> dummyProducts = [
  Product(
    id: '1',
    title: 'كيكة الشوكولاتة الفاخرة',
    description: 'كيكة شوكولاتة غنية بثلاث طبقات من الكريمة البلجيكية الداكنة، مزينة برقائق الشوكولاتة والتوت الطازج. مثالية للمناسبات والأعياد.',
    price: 6000,
    imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800&q=80',
    sellerName: 'مطبخ أم محمد',
    location: 'صنعاء، معين',
    rating: 4.8,
    reviewCount: 24,
    categoryName: 'حلويات',
  ),
  Product(
    id: '2',
    title: 'فستان قطني مشجر',
    description: 'فستان من القطن المصري الناعم بتصميم عصري مريح. متوفر بعدة مقاسات وألوان.',
    price: 8000,
    imageUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800&q=80',
    sellerName: 'أناقة عدن',
    location: 'عدن، كريتر',
    rating: 4.5,
    reviewCount: 12,
    isFavorited: true,
    categoryName: 'ملابس وأزياء',
  ),
  Product(
    id: '3',
    title: 'معجنات مشكلة طازجة',
    description: 'تشكيلة فاخرة من المعجنات الطازجة بحشوات مختلفة: جبن، لحم، زعتر، وسبانخ. مخبوزة يومياً.',
    price: 3500,
    imageUrl: 'https://images.unsplash.com/photo-1550617931-e17a7b70dce2?w=800&q=80',
    sellerName: 'مخبز الأماني',
    location: 'تعز، المظفر',
    rating: 4.9,
    reviewCount: 47,
    categoryName: 'معجنات',
  ),
  Product(
    id: '4',
    title: 'بخور عرائسي فاخر',
    description: 'بخور عدني أصيل برائحة العود والمسك تدوم طويلاً. يأتي في علبة هدايا فاخرة.',
    price: 15000,
    imageUrl: 'https://images.unsplash.com/photo-1601662528567-526cd06f6582?w=800&q=80',
    sellerName: 'بخور الأصالة',
    location: 'عدن، المنصورة',
    rating: 4.7,
    reviewCount: 31,
    categoryName: 'عطور وبخور',
  ),
  Product(
    id: '5',
    title: 'طقم بناتي أنيق',
    description: 'طقم بناتي أنيق للعيد مكون من فستان وبندانة متناسقة. خامة قطن ممتازة.',
    price: 12000,
    imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=800&q=80',
    sellerName: 'أناقة عدن',
    location: 'عدن، كريتر',
    rating: 4.3,
    reviewCount: 8,
    isFavorited: true,
    categoryName: 'ملابس وأزياء',
  ),
  Product(
    id: '6',
    title: 'بسبوسة بالمكسرات',
    description: 'بسبوسة طازجة محشية بالقشطة ومزينة بالمكسرات الفاخرة. مناسبة للولائم.',
    price: 4500,
    imageUrl: 'https://images.unsplash.com/photo-1576779435647-975549079fbe?w=800&q=80',
    sellerName: 'مطبخ أم محمد',
    location: 'صنعاء، معين',
    rating: 4.6,
    reviewCount: 15,
    categoryName: 'حلويات',
  ),
];
