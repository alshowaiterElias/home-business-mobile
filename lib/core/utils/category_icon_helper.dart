import 'package:flutter/material.dart';

/// Maps backend icon keys to Flutter Material icons.
/// Matches the admin web icon catalog (90+ icons across 10 categories).
class CategoryIconHelper {
  CategoryIconHelper._();

  static const Map<String, IconData> _iconMap = {
    // ─── Food & Drinks ─────────────────────────
    'utensils': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded, // legacy alias
    'cake': Icons.cake_rounded,
    'pizza': Icons.local_pizza_rounded,
    'coffee': Icons.local_cafe_rounded,
    'icecream': Icons.icecream_rounded,
    'cup_soda': Icons.local_drink_rounded,
    'soup': Icons.soup_kitchen_rounded,
    'sandwich': Icons.lunch_dining_rounded,
    'cookie': Icons.cookie_rounded,
    'croissant': Icons.bakery_dining_rounded,
    'apple': Icons.apple_rounded,
    'cherry': Icons.apple_rounded,
    'carrot': Icons.eco_rounded,
    'fish': Icons.set_meal_rounded,
    'beef': Icons.kebab_dining_rounded,
    'drumstick': Icons.dinner_dining_rounded,
    'egg': Icons.egg_rounded,
    'milk': Icons.coffee_rounded,
    'flame': Icons.local_fire_department_rounded,
    'candy': Icons.auto_awesome_rounded,
    'wheat': Icons.grain_rounded,

    // ─── Fashion & Style ─────────────────────────
    'shirt': Icons.checkroom_rounded,
    'checkroom': Icons.checkroom_rounded, // legacy alias
    'shopping_bag': Icons.shopping_bag_rounded,
    'scissors': Icons.content_cut_rounded,
    'sparkles': Icons.auto_awesome_rounded,
    'glasses': Icons.visibility_rounded,
    'footprints': Icons.hiking_rounded,
    'gem': Icons.diamond_rounded,
    'crown': Icons.military_tech_rounded,
    'watch': Icons.watch_rounded,
    'ribbon': Icons.bookmark_rounded,

    // ─── Beauty & Perfumes ───────────────────────
    'sparkle': Icons.flare_rounded,
    'flower2': Icons.local_florist_rounded,
    'spa': Icons.spa_rounded, // legacy alias
    'heart': Icons.favorite_rounded,
    'smile': Icons.face_rounded,
    'face': Icons.face_retouching_natural, // legacy alias
    'feather': Icons.wb_sunny_rounded,
    'brush': Icons.brush_rounded,
    'droplets': Icons.water_drop_rounded,
    'pill': Icons.medication_rounded,
    'activity': Icons.monitor_heart_rounded,

    // ─── Crafts, Gifts & Art ─────────────────────
    'palette': Icons.palette_rounded, // legacy alias
    'gift': Icons.card_giftcard_rounded,
    'camera': Icons.camera_alt_rounded,
    'box': Icons.inventory_2_rounded,
    'party_popper': Icons.celebration_rounded,
    'paintbrush': Icons.draw_rounded,
    'stamp': Icons.print_rounded,
    'scroll': Icons.history_edu_rounded,
    'music': Icons.music_note_rounded,
    'mic': Icons.mic_rounded,

    // ─── Home & Living ───────────────────────────
    'home': Icons.home_rounded,
    'armchair': Icons.weekend_rounded,
    'weekend': Icons.weekend_rounded, // legacy alias
    'sofa': Icons.chair_rounded,
    'bed': Icons.bed_rounded,
    'lamp': Icons.lightbulb_rounded,
    'clock': Icons.access_time_rounded,
    'bath': Icons.bathtub_rounded,
    'door_open': Icons.meeting_room_rounded,
    'fan': Icons.mode_fan_off_rounded,

    // ─── Kids & Toys ─────────────────────────────
    'baby': Icons.child_care_rounded,
    'gamepad2': Icons.sports_esports_rounded,
    'shapes': Icons.category_rounded,

    // ─── Electronics & Tech ──────────────────────
    'smartphone': Icons.smartphone_rounded,
    'laptop': Icons.laptop_rounded,
    'headphones': Icons.headphones_rounded,
    'tv': Icons.tv_rounded,
    'wrench': Icons.build_rounded,
    'hammer': Icons.hardware_rounded,
    'cpu': Icons.memory_rounded,

    // ─── Plants & Nature ─────────────────────────
    'leaf': Icons.eco_rounded,
    'sprout': Icons.yard_rounded,
    'trees': Icons.park_rounded,
    'sun': Icons.wb_sunny_rounded,
    'moon': Icons.nightlight_round,
    'star': Icons.star_rounded,
    'cloud': Icons.cloud_rounded,

    // ─── Books & Stationery ──────────────────────
    'book_open': Icons.menu_book_rounded,
    'pencil': Icons.edit_rounded,
    'grad_cap': Icons.school_rounded,
    'briefcase': Icons.work_rounded,

    // ─── Services & Delivery ─────────────────────
    'truck': Icons.local_shipping_rounded,
    'package_check': Icons.verified_rounded,
    'shield_check': Icons.security_rounded,
    'store': Icons.storefront_rounded,
    'shopping_basket': Icons.shopping_basket_rounded,
    'badge_percent': Icons.discount_rounded,
    'map_pin': Icons.place_rounded,
    'folder': Icons.folder_rounded,
    'help_circle': Icons.help_outline_rounded,
  };

  /// Returns the corresponding [IconData] for a given backend [iconKey].
  /// If null, empty, or unmapped, returns [Icons.category_rounded] as fallback.
  static IconData getIcon(String? iconKey) {
    if (iconKey == null || iconKey.isEmpty) {
      return Icons.category_rounded;
    }

    final key = iconKey.trim().toLowerCase();
    return _iconMap[key] ?? Icons.category_rounded;
  }
}
