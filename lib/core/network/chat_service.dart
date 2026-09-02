import 'api_client.dart';

/// REST API service for chat operations (conversations, messages, blocking).
/// Mirrors the backend `/api/v1/chat/*` endpoints.
class ChatApiService {
  // ─── Conversations ──────────────────────────────────────────────

  /// Get paginated conversation list.
  static Future<Map<String, dynamic>> getConversations({String? cursor, int limit = 20}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await ApiClient.instance.get('/chat/conversations', queryParameters: params);
    return response.data['data'];
  }

  /// Get or create a 1:1 conversation with another user.
  static Future<Map<String, dynamic>> getOrCreateConversation(String userId) async {
    final response = await ApiClient.instance.post('/chat/conversations', data: {'userId': userId});
    return response.data['data'];
  }

  // ─── Messages ───────────────────────────────────────────────────

  /// Get paginated messages for a conversation.
  static Future<Map<String, dynamic>> getMessages(String conversationId, {String? cursor, int limit = 30}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final response = await ApiClient.instance.get('/chat/conversations/$conversationId/messages', queryParameters: params);
    return response.data['data'];
  }

  /// Send a message to a conversation.
  static Future<Map<String, dynamic>> sendMessage(
    String conversationId, {
    String type = 'TEXT',
    String? text,
    String? tempId,
    String? replyToId,
    Map<String, dynamic>? reference,
  }) async {
    final response = await ApiClient.instance.post(
      '/chat/conversations/$conversationId/messages',
      data: {
        'type': type,
        if (text != null) 'text': text,
        if (tempId != null) 'tempId': tempId,
        if (replyToId != null) 'replyToId': replyToId,
        if (reference != null) 'reference': reference,
      },
    );
    return response.data['data'];
  }

  // ─── Actions ────────────────────────────────────────────────────

  /// Mark a conversation as read up to a specific message.
  static Future<void> markAsRead(String conversationId, String messageId) async {
    await ApiClient.instance.patch('/chat/conversations/$conversationId/read', data: {'messageId': messageId});
  }

  /// Mute or unmute a conversation.
  static Future<void> muteConversation(String conversationId, bool muted) async {
    await ApiClient.instance.patch('/chat/conversations/$conversationId/mute', data: {'muted': muted});
  }

  /// Archive or unarchive a conversation.
  static Future<void> archiveConversation(String conversationId, bool archived) async {
    await ApiClient.instance.patch('/chat/conversations/$conversationId/archive', data: {'archived': archived});
  }

  /// Soft-delete (hide) a conversation.
  static Future<void> deleteConversation(String conversationId) async {
    await ApiClient.instance.delete('/chat/conversations/$conversationId');
  }

  /// Delete a message.
  static Future<void> deleteMessage(String messageId, {bool forAll = false}) async {
    await ApiClient.instance.delete('/chat/messages/$messageId', data: {'forAll': forAll});
  }

  // ─── Blocking ───────────────────────────────────────────────────

  /// Block a user.
  static Future<void> blockUser(String userId) async {
    await ApiClient.instance.post('/chat/block/$userId');
  }

  /// Unblock a user.
  static Future<void> unblockUser(String userId) async {
    await ApiClient.instance.delete('/chat/block/$userId');
  }

  // ─── Unread Count ───────────────────────────────────────────────

  /// Get total unread message count across all conversations.
  static Future<int> getUnreadCount() async {
    final response = await ApiClient.instance.get('/chat/unread-count');
    return response.data['data']['unreadCount'] ?? 0;
  }
}
