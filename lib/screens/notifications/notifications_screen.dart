import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../controllers/notification_controller.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _getIconForType(String type) {
    switch (type) {
      case 'PRODUCT_APPROVED': return Icons.check_circle_outline;
      case 'PRODUCT_REJECTED': return Icons.cancel_outlined;
      case 'NEW_REVIEW': return Icons.star_outline_rounded;
      case 'SYSTEM_ALERT': return Icons.waving_hand_rounded;
      default: return Icons.notifications_none_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'PRODUCT_APPROVED': return AppTheme.primary;
      case 'PRODUCT_REJECTED': return AppTheme.error;
      case 'NEW_REVIEW': return AppTheme.accent;
      case 'SYSTEM_ALERT': return const Color(0xFF5C6BC0);
      default: return AppTheme.textHint;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(NotificationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: Text('تحديد كـ مقروء', style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Text('لا توجد إشعارات', style: theme.textTheme.bodyLarge?.copyWith(color: AppTheme.textHint)),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchNotifications,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
            itemCount: controller.notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
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
              final timeString = createdAt != null ? _formatTimeAgo(createdAt) : '';

              return Material(
                color: !isRead ? AppTheme.primarySurface.withOpacity(0.2) : Colors.transparent,
                child: ListTile(
                  onTap: () {
                    if (!isRead) controller.markAsRead(n['id']);
                  },
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16, vertical: AppTheme.space8),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: Text(n['title'] ?? '', style: theme.textTheme.titleMedium),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(n['body'] ?? '', style: theme.textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(timeString, style: theme.textTheme.bodySmall),
                    ],
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


