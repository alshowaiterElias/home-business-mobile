import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_models.dart';
import '../core/network/chat_service.dart';
import '../core/network/socket_service.dart';
import 'chat_controller.dart';

/// Per-conversation controller — manages messages, typing, and read receipts
/// for an active chat. Created when opening a chat, disposed when leaving.
class ConversationController extends GetxController with WidgetsBindingObserver {
  final String conversationId;
  final String currentUserId;

  ConversationController({required this.conversationId, required this.currentUserId});

  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isTyping = false.obs;
  final typingUserId = ''.obs;
  final replyingTo = Rxn<ChatMessage>();
  final showScrollToBottom = false.obs;

  final textController = TextEditingController();

  String? _nextCursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  Timer? _typingTimer;

  StreamSubscription? _newMessageSub;
  StreamSubscription? _readSub;
  StreamSubscription? _deletedSub;
  StreamSubscription? _typingStartSub;
  StreamSubscription? _typingStopSub;
  StreamSubscription? _connectionStatusSub;

  static const _uuid = Uuid();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    SocketService.instance.joinConversation(conversationId);
    _listenToSocket();
    loadMessages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      loadMessages(refresh: true);
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    SocketService.instance.leaveConversation(conversationId);
    _newMessageSub?.cancel();
    _readSub?.cancel();
    _deletedSub?.cancel();
    _typingStartSub?.cancel();
    _typingStopSub?.cancel();
    _connectionStatusSub?.cancel();
    _typingTimer?.cancel();
    textController.dispose();
    super.onClose();
  }

  // ── Socket listeners ────────────────────────────────────────────
  void _listenToSocket() {
    _newMessageSub = SocketService.instance.onNewMessage.listen((data) {
      if (data['conversationId'] != conversationId) return;
      final msgData = data['message'];
      if (msgData == null) return;

      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(msgData));

      // Skip if we already have this message (optimistic or duplicate)
      if (messages.any((m) => m.id == msg.id)) return;

      // Replace optimistic message if tempId matches
      if (msg.tempId != null) {
        final idx = messages.indexWhere((m) => m.tempId == msg.tempId && m.isPending);
        if (idx != -1) {
          messages[idx] = msg;
          return;
        }
      }

      messages.insert(0, msg);

      // Auto mark as read if from someone else
      if (msg.senderId != currentUserId) {
        _markAsRead(msg.id);
      }
    });

    _readSub = SocketService.instance.onMessageRead.listen((data) {
      if (data['conversationId'] != conversationId) return;
      // Could update message read status UI here if needed
    });

    _deletedSub = SocketService.instance.onMessageDeleted.listen((data) {
      if (data['conversationId'] != conversationId) return;
      final msgId = data['messageId'] as String?;
      final forAll = data['deletedForAll'] as bool? ?? false;
      if (forAll && msgId != null) {
        messages.removeWhere((m) => m.id == msgId);
      }
    });

    _typingStartSub = SocketService.instance.onTypingStart.listen((data) {
      if (data['conversationId'] != conversationId) return;
      final uid = data['userId'] as String? ?? '';
      if (uid != currentUserId) {
        typingUserId.value = uid;
        isTyping.value = true;
      }
    });

    _typingStopSub = SocketService.instance.onTypingStop.listen((data) {
      if (data['conversationId'] != conversationId) return;
      isTyping.value = false;
      typingUserId.value = '';
    });

    _connectionStatusSub = SocketService.instance.onConnectionStatusChanged.listen((isConnected) {
      if (isConnected) {
        // We reconnected! Let's fetch any missed messages.
        loadMessages(refresh: true);
      }
    });
  }

  // ── Load messages (cursor-paginated, newest first) ──────────────
  Future<void> loadMessages({bool refresh = false}) async {
    if (isLoading.value) return;
    if (!_hasMore && !refresh) return;

    if (refresh) {
      _nextCursor = null;
      _hasMore = true;
    }

    isLoading.value = true;
    try {
      final result = await ChatApiService.getMessages(
        conversationId,
        cursor: refresh ? null : _nextCursor,
      );
      final List<dynamic> rawList = result['messages'] ?? [];
      final fetched = rawList.map((j) => ChatMessage.fromJson(j)).toList();

      if (refresh) {
        messages.assignAll(fetched);
      } else {
        messages.addAll(fetched);
      }

      _nextCursor = result['nextCursor'];
      _hasMore = _nextCursor != null;

      // Mark the latest message as read
      if (messages.isNotEmpty) {
        final latest = messages.first;
        if (latest.senderId != currentUserId) {
          _markAsRead(latest.id);
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Send text message ───────────────────────────────────────────
  Future<void> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    final tempId = _uuid.v4();
    final optimistic = ChatMessage(
      id: tempId,
      conversationId: conversationId,
      senderId: currentUserId,
      type: 'TEXT',
      text: text.trim(),
      tempId: tempId,
      replyToId: replyingTo.value?.id,
      createdAt: DateTime.now(),
      isPending: true,
      replyTo: replyingTo.value,
    );

    messages.insert(0, optimistic);
    replyingTo.value = null;
    textController.clear();
    _stopTyping();

    try {
      final result = await ChatApiService.sendMessage(
        conversationId,
        text: text.trim(),
        tempId: tempId,
        replyToId: optimistic.replyToId,
      );
      // Replace optimistic with server response
      final idx = messages.indexWhere((m) => m.tempId == tempId);
      if (idx != -1) {
        messages[idx] = ChatMessage.fromJson(result);
      }

      // Refresh global chat controller
      if (Get.isRegistered<ChatController>()) {
        Get.find<ChatController>().refreshUnreadCount();
      }
    } catch (e) {
      // Mark as failed
      final idx = messages.indexWhere((m) => m.tempId == tempId);
      if (idx != -1) {
        messages[idx].isPending = false;
        messages[idx].isFailed = true;
        messages.refresh();
      }
    }
  }

  // ── Send reference message (product/store) ──────────────────────
  Future<void> sendReferenceMessage({
    required String type,
    required String referenceType,
    required String referenceId,
    String? snapshotTitle,
    String? snapshotPrice,
    String? snapshotImage,
    Map<String, dynamic>? snapshotMeta,
  }) async {
    final tempId = _uuid.v4();

    try {
      final result = await ChatApiService.sendMessage(
        conversationId,
        type: type,
        tempId: tempId,
        reference: {
          'referenceType': referenceType,
          'referenceId': referenceId,
          if (snapshotTitle != null) 'snapshotTitle': snapshotTitle,
          if (snapshotPrice != null) 'snapshotPrice': snapshotPrice,
          if (snapshotImage != null) 'snapshotImage': snapshotImage,
          if (snapshotMeta != null) 'snapshotMeta': snapshotMeta,
        },
      );
      // The server-side emission will handle adding it to the list
      // But add it locally if it wasn't received via socket yet
      final msg = ChatMessage.fromJson(result);
      if (!messages.any((m) => m.id == msg.id)) {
        messages.insert(0, msg);
      }
    } catch (e) {
      Get.snackbar('خطأ', 'فشل إرسال المرجع');
    }
  }

  Future<void> deleteMessage(String messageId, {bool forAll = false}) async {
    try {
      await ChatApiService.deleteMessage(messageId, forAll: forAll);
      messages.removeWhere((m) => m.id == messageId);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل حذف الرسالة');
    }
  }

  // ── Mark as read ────────────────────────────────────────────────
  void _markAsRead(String messageId) {
    ChatApiService.markAsRead(conversationId, messageId).catchError((_) {});
    SocketService.instance.emitReadReceipt(conversationId, messageId);
  }

  // ── Typing indicators ──────────────────────────────────────────
  void onTextChanged(String text) {
    if (text.isNotEmpty) {
      SocketService.instance.startTyping(conversationId);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
    } else {
      _stopTyping();
    }
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    SocketService.instance.stopTyping(conversationId);
  }

  // ── Reply ───────────────────────────────────────────────────────
  void setReplyTo(ChatMessage message) {
    replyingTo.value = message;
  }

  void cancelReply() {
    replyingTo.value = null;
  }
}
