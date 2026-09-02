import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../controllers/conversation_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/chat_models.dart';
import '../../widgets/chat_reference_cards.dart';
import '../../widgets/report_sheet.dart';
import 'marketplace_share_sheet.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ConversationController _controller;
  late String _conversationId;
  Conversation? _conversation;
  final Map<String, GlobalKey> _messageKeys = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _conversation = args['conversation'] as Conversation?;

    // Get conversation ID from route parameter or arguments
    _conversationId = Get.parameters['id'] ?? _conversation?.id ?? '';

    final auth = Get.find<AuthController>();
    _controller = Get.put(
      ConversationController(
        conversationId: _conversationId,
        currentUserId: auth.userId.value,
      ),
      tag: _conversationId,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
      if (_controller.hasMore && !_controller.isLoading.value) {
        _controller.loadMessages();
      }
    }
    _controller.showScrollToBottom.value = _scrollController.position.pixels > 300;
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    Get.delete<ConversationController>(tag: _conversationId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = Get.find<AuthController>();
    final other = _conversation?.getOtherParticipant(auth.userId.value);
    final otherUser = other?.user;
    final displayName = otherUser?.displayName ?? 'محادثة';
    final avatarUrl = otherUser?.avatarUrl != null
        ? ApiClient.getImageUrl(otherUser!.avatarUrl!)
        : null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            // Navigate to store/profile if business
            if (otherUser?.business != null) {
              Get.toNamed('/store', arguments: {'id': otherUser!.business!.id});
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.colors.primarySurface,
                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null
                    ? Icon(Icons.person_rounded, color: context.colors.primary, size: 18)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Obx(() {
                      if (_controller.isTyping.value) {
                        return Text(
                          'يكتب...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontSize: 11,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value && _controller.messages.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.messages.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.space32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 48, color: context.colors.textHint),
                        const SizedBox(height: AppTheme.space16),
                        Text('ابدأ المحادثة بإرسال رسالة', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                );
              }

              return Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space12,
                  vertical: AppTheme.space8,
                ),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = _controller.messages[index];
                  final isMine = msg.senderId == auth.userId.value;

                  // Date separator
                  Widget? dateSeparator;
                  if (index == _controller.messages.length - 1 ||
                      !_isSameDay(msg.createdAt, _controller.messages[index + 1].createdAt)) {
                    dateSeparator = _DateSeparator(date: msg.createdAt);
                  }

                  final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());

                  return Column(
                    key: key,
                    children: [
                      if (dateSeparator != null) dateSeparator,
                      _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        onReply: () => _controller.setReplyTo(msg),
                        onDelete: () => _showDeleteOptions(msg),
                        onCopy: msg.isTextMessage
                            ? () {
                                Clipboard.setData(ClipboardData(text: msg.text ?? ''));
                                Get.snackbar('', 'تم نسخ الرسالة',
                                    snackPosition: SnackPosition.BOTTOM,
                                    duration: const Duration(seconds: 1));
                              }
                            : null,
                        onReplyClicked: (replyId) {
                          final targetKey = _messageKeys[replyId];
                          if (targetKey?.currentContext != null) {
                            Scrollable.ensureVisible(
                              targetKey!.currentContext!,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                              alignment: 0.5,
                            );
                            
                            // Highlight effect could be added here
                          } else {
                            Get.snackbar('تنبيه', 'الرسالة الأصلية غير موجودة', snackPosition: SnackPosition.BOTTOM);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
              Obx(() {
                if (_controller.showScrollToBottom.value) {
                  return Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: context.colors.primary,
                      onPressed: _scrollToBottom,
                      child: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          );
        }),
      ),

          // Reply Preview
          Obx(() {
            final reply = _controller.replyingTo.value;
            if (reply == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              decoration: BoxDecoration(
                color: context.colors.surface,
                border: Border(top: BorderSide(color: context.colors.divider)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 36,
                    decoration: BoxDecoration(
                      color: context.colors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الرد على',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reply.text ?? (reply.isProductReference ? '📦 منتج' : '🏪 متجر'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: _controller.cancelReply,
                  ),
                ],
              ),
            );
          }),

          // Composer Bar
          _ComposerBar(controller: _controller),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showDeleteOptions(ChatMessage msg) {
    final auth = Get.find<AuthController>();
    final isMine = msg.senderId == auth.userId.value;

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                title: const Text('حذف للجميع'),
                onTap: () {
                  Get.back();
                  _controller.deleteMessage(msg.id, forAll: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('حذف لي'),
              onTap: () {
                Get.back();
                _controller.deleteMessage(msg.id, forAll: false);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Separator ──────────────────────────────────────────────
class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String label;
    if (diff.inDays == 0) {
      label = 'اليوم';
    } else if (diff.inDays == 1) {
      label = 'أمس';
    } else {
      label = DateFormat.yMMMd('ar').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
          ),
        ),
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onDelete;
  final VoidCallback? onCopy;
  final Function(String)? onReplyClicked;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.onReply,
    required this.onDelete,
    this.onCopy,
    this.onReplyClicked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.colors.isDark;

    // Bubble colors
    final bgColor = isMine
        ? (isDark ? const Color(0xFF1B4332) : const Color(0xFFDCF8C6))
        : context.colors.surface;
    final textColor = isMine
        ? (isDark ? Colors.white : context.colors.textPrimary)
        : context.colors.textPrimary;

    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isMine ? 14 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply preview
              if (message.replyTo != null) ...[
                GestureDetector(
                  onTap: () {
                    if (onReplyClicked != null && message.replyTo!.id.isNotEmpty) {
                      onReplyClicked!(message.replyTo!.id);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: context.colors.overlayLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border(
                        right: BorderSide(color: context.colors.primary, width: 3),
                      ),
                    ),
                    child: Text(
                      message.replyTo!.text ?? '📎 مرفق',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                ),
              ],

              // Reference card
              if (message.reference != null) ...[
                if (message.isProductReference)
                  ProductReferenceCard(reference: message.reference!),
                if (message.isStoreReference)
                  StoreReferenceCard(reference: message.reference!),
                if (message.text != null && message.text!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                ],
              ],

              // System message
              if (message.isSystemMessage) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        message.text ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Text content
              if (message.isTextMessage || (message.text != null && message.text!.isNotEmpty && !message.isSystemMessage)) ...[
                Text(
                  message.text ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],

              // Timestamp + status
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    DateFormat.Hm().format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? (isDark ? Colors.white60 : Colors.black45)
                          : context.colors.textHint,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 3),
                    Icon(
                      message.isPending
                          ? Icons.access_time_rounded
                          : message.isFailed
                              ? Icons.error_outline_rounded
                              : Icons.done_all_rounded,
                      size: 14,
                      color: message.isPending
                          ? Colors.grey
                          : message.isFailed
                              ? Colors.red
                              : (isDark ? Colors.lightBlueAccent : Colors.blue),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('رد'),
              onTap: () {
                Get.back();
                onReply();
              },
            ),
            if (onCopy != null)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('نسخ'),
                onTap: () {
                  Get.back();
                  onCopy!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: const Text('حذف', style: TextStyle(color: Colors.red)),
              onTap: () {
                Get.back();
                onDelete();
              },
            ),
            if (!isMine)
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                title: const Text('إبلاغ', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Get.back();
                  showReportSheet(
                    context,
                    targetType: 'MESSAGE',
                    targetId: message.id,
                    targetName: 'رسالة نصية',
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Composer Bar ────────────────────────────────────────────────
class _ComposerBar extends StatelessWidget {
  final ConversationController controller;
  const _ComposerBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.space8,
        AppTheme.space8,
        AppTheme.space8,
        MediaQuery.of(context).padding.bottom + AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.divider, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.colors.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: context.colors.textSecondary),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => MarketplaceShareSheet(chatController: controller),
              );
            },
          ),
          
          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              ),
              child: TextField(
                controller: controller.textController,
                onChanged: controller.onTextChanged,
                maxLines: 4,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Send button
          Material(
            color: context.colors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                final text = controller.textController.text;
                if (text.trim().isNotEmpty) {
                  controller.sendTextMessage(text);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
