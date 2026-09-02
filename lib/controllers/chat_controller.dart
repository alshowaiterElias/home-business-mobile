import 'dart:async';
import 'package:get/get.dart';
import '../models/chat_models.dart';
import '../core/network/chat_service.dart';
import '../core/network/socket_service.dart';

/// Global chat controller — manages conversations list, unread count,
/// and real-time updates. Persists across the app lifecycle.
class ChatController extends GetxController {
  final conversations = <Conversation>[].obs;
  final unreadCount = 0.obs;
  final isLoading = false.obs;

  String? _nextCursor;
  bool _hasMore = true;

  StreamSubscription? _newMessageSub;
  StreamSubscription? _convUpdatedSub;
  StreamSubscription? _messageReadSub;

  @override
  void onInit() {
    super.onInit();
    _listenToSocket();
    loadConversations();
    refreshUnreadCount();
  }

  @override
  void onClose() {
    _newMessageSub?.cancel();
    _convUpdatedSub?.cancel();
    _messageReadSub?.cancel();
    super.onClose();
  }

  // ── Socket listeners ────────────────────────────────────────────
  void _listenToSocket() {
    _newMessageSub = SocketService.instance.onNewMessage.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null) {
        // Refresh the specific conversation in the list
        _refreshSingleConversation(convId);
        refreshUnreadCount();
      }
    });

    _convUpdatedSub = SocketService.instance.onConversationUpdated.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null) {
        _refreshSingleConversation(convId);
        refreshUnreadCount();
      }
    });

    _messageReadSub = SocketService.instance.onMessageRead.listen((data) {
      final convId = data['conversationId'] as String?;
      if (convId != null) {
        _refreshSingleConversation(convId);
        refreshUnreadCount();
      }
    });
  }

  // ── Load conversations (initial or paginated) ───────────────────
  Future<void> loadConversations({bool refresh = false}) async {
    if (isLoading.value) return;

    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }

    if (!_hasMore && !refresh) return;

    isLoading.value = true;
    try {
      final result = await ChatApiService.getConversations(
        cursor: refresh ? null : _nextCursor,
      );
      final List<dynamic> rawList = result['conversations'] ?? [];
      final fetched = rawList.map((j) => Conversation.fromJson(j)).toList();

      if (refresh) {
        conversations.value = fetched;
      } else {
        conversations.addAll(fetched);
      }

      _nextCursor = result['nextCursor'];
      _hasMore = _nextCursor != null;
    } catch (e) {
      print('Error loading conversations: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Refresh unread count ────────────────────────────────────────
  Future<void> refreshUnreadCount() async {
    try {
      unreadCount.value = await ChatApiService.getUnreadCount();
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  // ── Refresh a single conversation in the list ───────────────────
  Future<void> _refreshSingleConversation(String convId) async {
    try {
      // Re-fetch conversations to get latest data for that conversation
      // (simpler than fetching a single conv endpoint which doesn't exist yet)
      await loadConversations(refresh: true);
    } catch (_) {}
  }

  // ── Remove a conversation from the local list ───────────────────
  Future<void> removeConversation(String convId) async {
    try {
      await ChatApiService.deleteConversation(convId);
      conversations.removeWhere((c) => c.id == convId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف المحادثة');
    }
  }

  // ── Toggle mute status ──────────────────────────────────────────
  Future<void> toggleMute(String convId, bool currentMuteStatus) async {
    try {
      await ChatApiService.muteConversation(convId, !currentMuteStatus);
      final index = conversations.indexWhere((c) => c.id == convId);
      if (index != -1) {
        // Create a copy of the conversation with updated mute status
        // Since Dart doesn't have data classes easily without packages, we modify or refetch.
        await _refreshSingleConversation(convId);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تحديث إعدادات الإشعارات');
    }
  }
}
