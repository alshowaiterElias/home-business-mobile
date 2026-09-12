import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:home_business_mobile/controllers/ai_assistant_controller.dart';
import 'package:home_business_mobile/core/network/ai_service.dart';
import 'package:home_business_mobile/models/ai_models.dart';
import 'package:home_business_mobile/widgets/ai_markdown_message.dart';
import 'package:home_business_mobile/widgets/ai_response_blocks.dart';

class MarketplaceAssistantSheet extends StatefulWidget {
  final Map<String, dynamic> contextData;

  const MarketplaceAssistantSheet({super.key, required this.contextData});

  @override
  State<MarketplaceAssistantSheet> createState() =>
      _MarketplaceAssistantSheetState();
}

class _MarketplaceAssistantSheetState extends State<MarketplaceAssistantSheet> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AiAssistantController _controller;
  dynamic _messagesSubscription;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AiAssistantController>()) {
      Get.put(AiAssistantController(AiService()));
    }
    _controller = Get.find<AiAssistantController>();

    _messagesSubscription = _controller.messages.listen((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submit([String? presetText]) {
    final query = (presetText ?? _textController.text).trim();
    if (query.isEmpty) return;

    _textController.clear();
    FocusScope.of(context).unfocus();
    _controller.ask(query, widget.contextData);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _controller.cancelRequest();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المساعد الذكي للسوق',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مدعوم بالذكاء الاصطناعي لاكتشاف المنتجات',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                Obx(
                  () => _controller.hasMessages
                      ? IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 22),
                          tooltip: 'محادثة جديدة',
                          onPressed: () => _controller.startNewChat(),
                        )
                      : const SizedBox.shrink(),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages Timeline
          Expanded(
            child: Obx(() {
              if (!_controller.hasMessages) {
                return _buildEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: _controller.messages.length,
                itemBuilder: (context, index) {
                  final message = _controller.messages[index];
                  return KeyedSubtree(
                    key: ValueKey(message.id),
                    child: message.isUser
                        ? _buildUserBubble(message)
                        : _buildAssistantBubble(message),
                  );
                },
              );
            }),
          ),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildUserBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 40),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantBubble(ChatMessage message) {
    if (message.isLoading && message.text.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 40),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  message.statusText ?? 'جاري البحث والتحليل في السوق...',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (message.isError) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message.errorMessage ??
                            'تعذر الحصول على رد من المساعد.',
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _controller.retry(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'إعادة المحاولة',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text response container
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.purple.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top assistant badge & copy button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.purple,
                        size: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'المساعد الذكي',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade400,
                      ),
                    ),
                    const Spacer(),
                    if (!message.isLoading && message.text.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.text));
                          HapticFeedback.lightImpact();
                          Get.snackbar(
                            'تم النسخ',
                            'تم نسخ نص الرد إلى الحافظة',
                            snackPosition: SnackPosition.BOTTOM,
                            duration: const Duration(seconds: 1),
                            backgroundColor: Colors.black87,
                            colorText: Colors.white,
                            margin: const EdgeInsets.all(16),
                            borderRadius: 10,
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.copy_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rich Markdown & Store-linked Response Text
                AiMarkdownMessage(
                  text: message.text,
                  storeNameToId: _controller.getAllKnownStores(message),
                  onStoreTap: (storeName, storeId) =>
                      _controller.openStore(storeName, storeId),
                  isStreaming: message.isLoading,
                ),

                if (message.isLoading) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'يكتب الآن...',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.purple.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Product Blocks Section (if any)
          if (message.blocks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'المنتجات المقترحة:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildBlocksSection(message.blocks),
          ],

          // Follow-up Recommendations
          if (message.recommendations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: message.recommendations.map((rec) {
                final prompt = rec.text
                    .replaceAll('اقتراح من الذكاء الاصطناعي: ', '')
                    .trim();
                return InkWell(
                  onTap: () => _submit(prompt),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.purple.withOpacity(0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.purple,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          prompt,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.purple,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBlocksSection(List<AiBlock> blocks) {
    final productBlocks = blocks
        .where((b) => b.type == 'product' && b.productId != null)
        .toList();
    final otherBlocks = blocks.where((b) => b.type != 'product').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (productBlocks.length == 1)
          AiBlockRenderer(block: productBlocks.first)
        else if (productBlocks.length > 1)
          SizedBox(
            height: 250,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: productBlocks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: 175,
                child: AiBlockRenderer(block: productBlocks[i]),
              ),
            ),
          ),
        if (otherBlocks.isNotEmpty) ...[
          if (productBlocks.isNotEmpty) const SizedBox(height: 10),
          ...otherBlocks.map((b) => AiBlockRenderer(block: b)),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    final screen = widget.contextData['screen'] as String? ?? 'home';
    final productTitle = widget.contextData['productTitle'] as String?;
    final storeName = widget.contextData['storeName'] as String?;
    final searchQuery = widget.contextData['searchQuery'] as String?;

    Widget? contextBadge;
    String subtitle;
    List<String> suggestions;

    switch (screen) {
      case 'product_details':
        subtitle =
            'اسألني عن تفاصيل هذا المنتج، طريقة طلبه، أو منتجات أخرى مشابهة:';
        contextBadge = Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.purple.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shopping_bag_outlined,
                size: 16,
                color: Colors.purple,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  productTitle != null && productTitle.isNotEmpty
                      ? 'أنت تتصفح: $productTitle'
                      : 'أنت تتصفح تفاصيل المنتج',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
        suggestions = [
          'ما هي تفاصيل ومواصفات هذا المنتج؟ 📋',
          'كيف أتواصل مع المتجر لطلبه مباشرة؟ 💬',
          'هل توجد خدمة توصيل لهذا المنتج؟ 🚚',
          'اقترح لي منتجات مشابهة من نفس القسم ✨',
          'ما هي خيارات الأسعار أو العروض المتاحة؟ 💰',
          'معلومات عن المتجر والتقييمات 🏪',
        ];
        break;

      case 'store_details':
        subtitle =
            'اسألني عن منتجات هذا المتجر، الأسعار، أو التنسيق مع البائع:';
        contextBadge = Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.indigo.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.storefront_rounded,
                size: 16,
                color: Colors.indigo,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  storeName != null && storeName.isNotEmpty
                      ? 'أنت تتصفح متجر: $storeName'
                      : 'أنت تتصفح صفحة المتجر',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
        suggestions = [
          'ما هي أفضل المنتجات في هذا المتجر؟ 🌟',
          'ما هي أسعار المنتجات المتوفرة هنا؟ 💰',
          'كيف أتواصل مباشرة مع صاحب المتجر؟ 💬',
          'هل يقدم هذا المتجر خدمة توصيل؟ 🚚',
          'أقسام وتخصص هذا المتجر 🏷️',
        ];
        break;

      case 'search':
        if (searchQuery != null && searchQuery.isNotEmpty) {
          subtitle =
              'اسألني لمساعدتك في العثور على أفضل خيارات "$searchQuery":';
          contextBadge = Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.09),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blue.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'نتائج البحث لـ: "$searchQuery"',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
          suggestions = [
            'أفضل خيارات "$searchQuery" المتاحة 🌟',
            'أرخص أسعار "$searchQuery" في المتاجر 🏷️',
            'هل توجد خدمة توصيل لـ "$searchQuery"؟ 🚚',
            'المتاجر الأكثر تميزاً في "$searchQuery" 🏪',
          ];
        } else {
          subtitle =
              'اسألني عن أي منتج، أسعار، أو استكشف الأقسام المتاحة وسأقترح لك أفضل الخيارات.';
          suggestions = [
            'ابحث عن كيك وحلويات 🍰',
            'أريد بخور وعطور فاخرة 🌸',
            'جلابيات وملابس مطرزة للعيد 👗',
            'بهارات وحوايج يمنية طازجة 🌶️',
          ];
        }
        break;

      case 'home':
      default:
        subtitle =
            'اسألني عن أي منتج، أسعار، أو استكشف الأقسام المتاحة وسأقترح لك أفضل الخيارات.';
        suggestions = [
          'ابحث عن كيك وحلويات 🍰',
          'أريد بخور وعطور فاخرة 🌸',
          'جلابيات وملابس مطرزة للعيد 👗',
          'بهارات وحوايج يمنية طازجة 🌶️',
          'أريد بوكس هدية للعروس 🎁',
          'هل توجد خدمة توصيل في التطبيق؟ 🚚',
          'كيف طريقة الطلب والشراء؟ 📱',
        ];
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          if (contextBadge != null) contextBadge,
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 44,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'مرحباً بك في المساعد الذكي للسوق 👋',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'اقتراحات لبدء المحادثة:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return ActionChip(
                backgroundColor: isDark
                    ? const Color(0xFF261C33)
                    : const Color(0xFFF5EEFA),
                side: BorderSide(
                  color: isDark
                      ? Colors.purple.withValues(alpha: 0.35)
                      : Colors.purple.withValues(alpha: 0.22),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                label: Text(
                  s,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFE9D5FF)
                        : const Color(0xFF3B0764),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _submit(s);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'اسأل عن منتجات، أسعار، أو أفكار هدايا...',
                hintStyle: const TextStyle(fontSize: 13.5, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => CircleAvatar(
              backgroundColor: _controller.isLoading
                  ? Colors.grey
                  : Colors.purple,
              child: IconButton(
                icon: _controller.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _controller.isLoading ? null : () => _submit(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
