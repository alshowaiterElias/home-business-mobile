import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PRODUCT_APPROVED':
        return Icons.check_circle_outline;
      case 'PRODUCT_REJECTED':
        return Icons.cancel_outlined;
      case 'NEW_REVIEW':
        return Icons.star_outline_rounded;
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
      case 'NEW_REVIEW':
        return AppTheme.accent;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(NotificationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          Obx(() {
            if (controller.notifications.isEmpty) return const SizedBox();
            return Row(
              children: [
                TextButton(
                  onPressed: () => controller.markAllAsRead(),
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
                  onPressed: () => _showDeleteAllDialog(context, controller),
                ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
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
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72, endIndent: 16),
            itemBuilder: (_, i) {
              final n = controller.notifications[i];
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
                  controller.deleteNotification(n['id']);
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
                    onTap: () {
                      if (!isRead) controller.markAsRead(n['id']);
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
