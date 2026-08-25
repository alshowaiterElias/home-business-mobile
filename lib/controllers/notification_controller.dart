import 'package:get/get.dart';
import '../core/network/data_service.dart';
import 'auth_controller.dart';

class NotificationController extends GetxController {
  var notifications = <dynamic>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final auth = Get.find<AuthController>();
    ever(auth.isLoggedIn, (bool loggedIn) {
      if (loggedIn) {
        fetchNotifications();
      } else {
        notifications.clear();
      }
    });

    if (auth.isLoggedIn.value) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final data = await DataService.getNotifications();
      notifications.assignAll(data);
    } catch (e) {
      print('Failed to fetch notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String id) async {
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1 && notifications[index]['isRead'] == false) {
      // Optimistic update
      var notif = Map<String, dynamic>.from(notifications[index]);
      notif['isRead'] = true;
      notifications[index] = notif;
      
      try {
        await DataService.markNotificationAsRead(id);
      } catch (e) {
        // Revert on error
        notif['isRead'] = false;
        notifications[index] = notif;
        print('Failed to mark notification as read: $e');
      }
    }
  }

  Future<void> markAllAsRead() async {
    final unread = notifications.where((n) => n['isRead'] == false).toList();
    if (unread.isEmpty) return;

    // Optimistic update
    final backup = List<dynamic>.from(notifications);
    for (int i = 0; i < notifications.length; i++) {
      if (notifications[i]['isRead'] == false) {
        var notif = Map<String, dynamic>.from(notifications[i]);
        notif['isRead'] = true;
        notifications[i] = notif;
      }
    }

    try {
      await DataService.markAllNotificationsAsRead();
    } catch (e) {
      // Revert on error
      notifications.assignAll(backup);
      print('Failed to mark all as read: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      final removed = notifications.removeAt(index);
      try {
        await DataService.deleteNotification(id);
      } catch (e) {
        // Revert on error
        notifications.insert(index, removed);
        print('Failed to delete notification: $e');
      }
    }
  }

  Future<void> deleteAllNotifications() async {
    if (notifications.isEmpty) return;

    final backup = List<dynamic>.from(notifications);
    notifications.clear();

    try {
      await DataService.deleteAllNotifications();
    } catch (e) {
      // Revert on error
      notifications.assignAll(backup);
      print('Failed to delete all notifications: $e');
    }
  }

  int get unreadCount {
    return notifications.where((n) => n['isRead'] == false).length;
  }
}
