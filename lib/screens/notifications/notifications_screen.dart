import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/data_service.dart';
import '../../controllers/notification_controller.dart';
import '../../models/dummy_data.dart';
import '../product/product_details_screen.dart';
import '../seller/seller_dashboard_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<NotificationController>()
        ? Get.find<NotificationController>()
        : Get.put(NotificationController());

    // Auto-refresh notifications every time the user enters this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.fetchNotifications();
    });
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PRODUCT_APPROVED':
        return Icons.check_circle_outline;
      case 'PRODUCT_REJECTED':
        return Icons.cancel_outlined;
      case 'PRODUCT_NEEDS_REVISION':
        return Icons.edit_note_outlined;
      case 'NEW_REVIEW':
        return Icons.star_outline_rounded;
      case 'NEW_PRODUCT_RELEASE':
        return Icons.shopping_bag_outlined;
      case 'SYSTEM_ALERT':
        return Icons.waving_hand_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'PRODUCT_APPROVED':
        return AppTheme.primary;
      case 'PRODUCT_REJECTED':
        return AppTheme.error;
      case 'PRODUCT_NEEDS_REVISION':
        return Colors.amber.shade800;
      case 'NEW_REVIEW':
        return AppTheme.accent;
      case 'NEW_PRODUCT_RELEASE':
        return AppTheme.primary;
      case 'SYSTEM_ALERT':
        return const Color(0xFF5C6BC0);
      default:
        return AppTheme.textHint;
    }
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 365) return 'منذ ${diff.inDays ~/ 365} سنة';
    if (diff.inDays > 30) return 'منذ ${diff.inDays ~/ 30} شهر';
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }

  void _showDeleteAllDialog(
    BuildContext context,
    NotificationController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح جميع الإشعارات'),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف كافة الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
              controller.deleteAllNotifications();
            },
            child: const Text(
              'حذف الكل',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> n,
  ) async {
    final type = n['type'] ?? '';
    final title = n['title'] ?? 'إشعار';
    final body = n['body'] ?? '';
    final productId = n['productId'] ?? n['targetId'];

    if (type == 'PRODUCT_NEEDS_REVISION' ||
        type == 'PRODUCT_REJECTED' ||
        type == 'PRODUCT_APPROVED' ||
        type == 'PRODUCT_SUSPENDED' ||
        type == 'NEW_REVIEW') {
      Get.to(() => const SellerDashboardScreen());
      return;
    }

    if (type == 'NEW_PRODUCT_RELEASE' || productId != null) {
      if (productId != null && productId.toString().isNotEmpty) {
        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );
        try {
          final rawProduct = await DataService.getProductById(
            productId.toString(),
          );
          if (Get.isDialogOpen ?? false) Get.back(); // Dismiss loading
          if (rawProduct.isNotEmpty) {
            final product = Product.fromJson(rawProduct);
            Get.to(() => ProductDetailsScreen(product: product));
            return;
          }
        } catch (e) {
          if (Get.isDialogOpen ?? false) Get.back(); // Dismiss loading on error
        }
      }
    }

    // Default or SYSTEM_ALERT: Show notification details dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Row(
          children: [
            Icon(_getIconForType(type), color: _getColorForType(type)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body.isNotEmpty ? body : 'لا توجد تفاصيل إضافية',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          Obx(() {
            if (_controller.notifications.isEmpty) return const SizedBox();
            return Row(
              children: [
                TextButton(
                  onPressed: () => _controller.markAllAsRead(),
                  child: Text(
                    'مقروء الكل',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_sweep_outlined,
                    color: AppTheme.error,
                  ),
                  tooltip: 'مسح الكل',
                  onPressed: () => _showDeleteAllDialog(context, _controller),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value && _controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  size: 64,
                  color: AppTheme.textHint.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'لا توجد إشعارات حالياً',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textHint,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _controller.fetchNotifications,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            itemCount: _controller.notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (_, i) {
              final n = _controller.notifications[i];
              final isRead = n['isRead'] == true;
              final type = n['type'] ?? '';
              final color = _getColorForType(type);
              final icon = _getIconForType(type);

              DateTime? createdAt;
              if (n['createdAt'] != null) {
                createdAt = DateTime.tryParse(n['createdAt']);
              }
              final timeString = createdAt != null
                  ? _formatTimeAgo(createdAt)
                  : '';

              return Dismissible(
                key: Key(n['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: AppTheme.error,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space20,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'حذف',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.delete_outline, color: Colors.white),
                    ],
                  ),
                ),
                onDismissed: (direction) {
                  _controller.deleteNotification(n['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الإشعار'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Material(
                  color: !isRead
                      ? AppTheme.primarySurface.withValues(alpha: 0.2)
                      : Colors.transparent,
                  child: ListTile(
                    onTap: () async {
                      if (!isRead) _controller.markAsRead(n['id']);
                      await _handleNotificationTap(context, n);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space8,
                    ),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Icon(icon, color: color, size: 22),
                    ),
                    title: Text(
                      n['title'] ?? '',
                      style: theme.textTheme.titleMedium,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          n['body'] ?? '',
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(timeString, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
