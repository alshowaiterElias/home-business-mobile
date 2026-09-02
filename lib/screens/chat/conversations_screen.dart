import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../controllers/chat_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/chat_models.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();

    return Obx(() {
      if (!auth.isLoggedIn.value) {
        return _buildLoginPrompt(context, theme);
      }

      // Ensure ChatController is registered
      if (!Get.isRegistered<ChatController>()) {
        Get.put(ChatController(), permanent: true);
      }
      final chatCtrl = Get.find<ChatController>();

      return Scaffold(
        appBar: AppBar(
          title: const Text('المحادثات'),
          centerTitle: true,
        ),
        body: Obx(() {
          if (chatCtrl.isLoading.value && chatCtrl.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatCtrl.conversations.isEmpty) {
            return _buildEmptyState(context, theme);
          }

          return RefreshIndicator(
            onRefresh: () => chatCtrl.loadConversations(refresh: true),
            color: context.colors.primary,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space8),
              itemCount: chatCtrl.conversations.length,
              itemBuilder: (context, index) {
                final conv = chatCtrl.conversations[index];
                return _ConversationTile(
                  conversation: conv,
                  currentUserId: auth.userId.value,
                );
              },
            ),
          );
        }),
      );
    });
  }

  Widget _buildLoginPrompt(BuildContext context, ThemeData theme) {
    return Scaffold(
      appBar: AppBar(title: const Text('المحادثات')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_outlined, size: 64, color: context.colors.textHint),
            const SizedBox(height: AppTheme.space16),
            Text('سجّل الدخول لبدء المحادثات', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.space16),
            ElevatedButton(
              onPressed: () => Get.toNamed('/auth'),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: context.colors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 48,
                color: context.colors.primary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            Text('لا توجد محادثات', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTheme.space8),
            Text(
              'ابدأ محادثة مع بائع من خلال صفحة المنتج\nأو صفحة المتجر',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Conversation Tile ───────────────────────────────────────────
class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final String currentUserId;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final other = conversation.getOtherParticipant(currentUserId);
    final otherUser = other?.user;
    final displayName = otherUser?.displayName ?? 'مستخدم';
    final avatarUrl = otherUser?.avatarUrl != null
        ? ApiClient.getImageUrl(otherUser!.avatarUrl!)
        : null;
    final lastMsg = conversation.lastMessage;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: () {
        Get.toNamed('/chat/${conversation.id}', arguments: {
          'conversation': conversation,
        });
      },
      onLongPress: () => _showActions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        decoration: BoxDecoration(
          color: hasUnread
              ? context.colors.primarySurface.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: context.colors.divider, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 26,
              backgroundColor: context.colors.primarySurface,
              backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person_rounded, color: context.colors.primary, size: 26)
                  : null,
            ),
            const SizedBox(width: AppTheme.space12),

            // Name + Last Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(lastMsg.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasUnread ? context.colors.primary : context.colors.textHint,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _getPreviewText(lastMsg),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: hasUnread ? context.colors.textPrimary : context.colors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(ChatMessage? msg) {
    if (msg == null) return 'ابدأ المحادثة...';
    if (msg.isProductReference) return '📦 منتج';
    if (msg.isStoreReference) return '🏪 متجر';
    if (msg.isSystemMessage) return '🔔 رسالة نظام';
    return msg.text ?? '';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inDays == 0) {
      return DateFormat.Hm().format(time);
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return DateFormat.E('ar').format(time);
    } else {
      return DateFormat.MMMd('ar').format(time);
    }
  }

  void _showActions(BuildContext context) {
    final chatCtrl = Get.find<ChatController>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              ),
              title: Text(conversation.isMuted ? 'تفعيل الإشعارات' : 'كتم الإشعارات'),
              onTap: () {
                Get.back();
                chatCtrl.toggleMute(conversation.id, conversation.isMuted);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('حذف المحادثة', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                chatCtrl.removeConversation(conversation.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
