import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:home_business_mobile/core/network/ai_service.dart';
import 'package:home_business_mobile/models/ai_models.dart';
import 'package:uuid/uuid.dart';

class AiAssistantController extends GetxController {
  final AiService _aiService;
  final Uuid _uuid = const Uuid();
  CancelToken? _cancelToken;

  AiAssistantController(this._aiService);

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _error = RxnString();
  String? get error => _error.value;

  String? _lastMessage;
  Map<String, dynamic>? _lastContext;
  String? get lastMessage => _lastMessage;

  bool get hasMessages => messages.isNotEmpty;

  Future<void> ask(String message, Map<String, dynamic> context) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    // Cancel any pending request
    cancelRequest();

    _lastMessage = trimmed;
    _lastContext = context;
    _isLoading.value = true;
    _error.value = null;
    _cancelToken = CancelToken();

    // 1. Add User Message
    final userMsgId = _uuid.v4();
    final userMessage = ChatMessage(
      id: userMsgId,
      role: 'user',
      text: trimmed,
      timestamp: DateTime.now(),
    );
    messages.add(userMessage);

    // 2. Add Loading Assistant Placeholder
    final assistantMsgId = _uuid.v4();
    final placeholder = ChatMessage(
      id: assistantMsgId,
      role: 'assistant',
      text: '',
      timestamp: DateTime.now(),
      isLoading: true,
    );
    messages.add(placeholder);

    // 3. Prepare History and Shown Product IDs
    final historyList = messages
        .where((m) => !m.isLoading && !m.isError && m.text.isNotEmpty && m.id != userMsgId && m.id != assistantMsgId)
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    final shownProductIds = messages
        .expand((m) => m.blocks)
        .where((b) => b.type == 'product' && b.productId != null)
        .map((b) => b.productId!)
        .toSet()
        .toList();

    try {
      final response = await _aiService.askAssistant(
        message: trimmed,
        context: context,
        history: historyList,
        shownProductIds: shownProductIds,
        cancelToken: _cancelToken,
      );

      // Deduplicate blocks if this is an informational follow-up query
      List<AiBlock> finalBlocks = response.blocks;
      if (shownProductIds.isNotEmpty && _isDetailFollowUp(trimmed)) {
        finalBlocks = response.blocks
            .where((b) => b.type != 'product')
            .toList();
      }

      final index = messages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1) {
        messages[index] = ChatMessage(
          id: assistantMsgId,
          role: 'assistant',
          text: response.text,
          blocks: finalBlocks,
          recommendations: response.recommendations,
          timestamp: DateTime.now(),
          isLoading: false,
        );
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _error.value = errorMsg;

      final index = messages.indexWhere((m) => m.id == assistantMsgId);
      if (index != -1) {
        if (errorMsg == 'تم إلغاء الطلب') {
          // Remove placeholder if user cancelled
          messages.removeAt(index);
        } else {
          messages[index] = ChatMessage(
            id: assistantMsgId,
            role: 'assistant',
            text: '',
            isError: true,
            errorMessage: errorMsg,
            timestamp: DateTime.now(),
            isLoading: false,
          );
        }
      }
    } finally {
      _isLoading.value = false;
      _cancelToken = null;
    }
  }

  Future<void> retry() async {
    if (_lastMessage != null && _lastContext != null) {
      // Remove any trailing error message before retrying
      if (messages.isNotEmpty && messages.last.isError) {
        messages.removeLast();
      }
      if (messages.isNotEmpty && messages.last.isUser) {
        messages.removeLast();
      }
      await ask(_lastMessage!, _lastContext!);
    }
  }

  void cancelRequest() {
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('User cancelled request');
    }
    _cancelToken = null;
    _isLoading.value = false;

    // Clean up any lingering loading placeholders
    messages.removeWhere((m) => m.isLoading);
  }

  void clear() {
    cancelRequest();
    messages.clear();
    _error.value = null;
    _isLoading.value = false;
    _lastMessage = null;
    _lastContext = null;
  }

  bool _isDetailFollowUp(String text) {
    final clean = text.toLowerCase();
    final patterns = [
      'بكم', 'كم سعر', 'سعرها', 'سعره', 'سعر', 'سعرهم', 'السعر',
      'اسعار', 'أسعار', 'الاسعار', 'الأسعار', 'اسعاره', 'اسعارها', 'اسعارهم', 'أسعارهم',
      'تكلفة', 'تكلفته', 'تكاليف', 'التكاليف', 'قيمة', 'قيمته', 'قيمتها', 'ثمن', 'حساب',
      'مقاس', 'مقاسات', 'حجم', 'احجام', 'أحجام',
      'لون', 'الوان', 'ألوان',
      'مكونات', 'تفاصيل', 'طريقة', 'وصف', 'مواصفات',
      'رقم', 'هاتف', 'تواصل', 'واتساب', 'موقع', 'عنوان',
      'متوفر منه', 'متوفر منها', 'في منه', 'في منها',
      'شكرا', 'شكراً', 'يعطيك العافية', 'تمام', 'تسلم', 'مشكور'
    ];
    return patterns.any((p) => clean.contains(p));
  }

  @override
  void onClose() {
    cancelRequest();
    super.onClose();
  }
}
