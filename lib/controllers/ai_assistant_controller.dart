import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:home_business_mobile/controllers/data_controller.dart';
import 'package:home_business_mobile/core/network/ai_service.dart';
import 'package:home_business_mobile/core/network/data_service.dart';
import 'package:home_business_mobile/core/network/storage_service.dart';
import 'package:home_business_mobile/models/ai_models.dart';
import 'package:uuid/uuid.dart';

class AiAssistantController extends GetxController {
  final AiService _aiService;
  final Uuid _uuid = const Uuid();
  CancelToken? _cancelToken;

  AiAssistantController(this._aiService);

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final RxMap<String, String> knownStores = <String, String>{}.obs;

  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _error = RxnString();
  String? get error => _error.value;

  String? _lastMessage;
  Map<String, dynamic>? _lastContext;
  String? get lastMessage => _lastMessage;

  bool get hasMessages => messages.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _loadPersistedMessages();
    _initKnownStores();
  }

  void _initKnownStores() {
    // 1. From persisted messages
    for (final m in messages) {
      _extractStoresFromMessage(m);
    }

    // 2. From DataController if available
    try {
      if (Get.isRegistered<DataController>()) {
        final dataCtrl = Get.find<DataController>();
        for (final s in dataCtrl.topStores) {
          if (s is Map && s['id'] != null && s['businessName'] != null) {
            knownStores[s['businessName'].toString().trim()] = s['id'].toString();
          }
        }
        for (final s in dataCtrl.featuredStores) {
          if (s is Map && s['id'] != null && s['businessName'] != null) {
            knownStores[s['businessName'].toString().trim()] = s['id'].toString();
          }
        }
      }
    } catch (_) {}

    // 3. Preload all stores asynchronously from DataService
    DataService.getBusinesses().then((storeList) {
      for (final s in storeList) {
        if (s is Map && s['id'] != null && s['businessName'] != null) {
          knownStores[s['businessName'].toString().trim()] = s['id'].toString();
        }
      }
    }).catchError((_) {});
  }

  void _extractStoresFromMessage(ChatMessage m) {
    for (final src in m.sources) {
      if (src.type == 'store' && src.name != null && src.name!.isNotEmpty) {
        knownStores[src.name!.trim()] = src.id;
      }
    }
    for (final b in m.blocks) {
      final biz = b.productData?['business'];
      if (biz is Map && biz['id'] != null && biz['businessName'] != null) {
        knownStores[biz['businessName'].toString().trim()] = biz['id'].toString();
      }
      final storeName = b.productData?['storeName'];
      final storeId = b.productData?['storeId'] ?? b.storeId;
      if (storeName != null && storeId != null) {
        knownStores[storeName.toString().trim()] = storeId.toString();
      }
    }
  }

  Map<String, String> getAllKnownStores([ChatMessage? message]) {
    final result = Map<String, String>.from(knownStores);
    if (message != null) {
      for (final src in message.sources) {
        if (src.type == 'store' && src.name != null && src.name!.isNotEmpty) {
          result[src.name!.trim()] = src.id;
        }
      }
      for (final b in message.blocks) {
        final biz = b.productData?['business'];
        if (biz is Map && biz['id'] != null && biz['businessName'] != null) {
          result[biz['businessName'].toString().trim()] = biz['id'].toString();
        }
        final storeName = b.productData?['storeName'];
        final storeId = b.productData?['storeId'] ?? b.storeId;
        if (storeName != null && storeId != null) {
          result[storeName.toString().trim()] = storeId.toString();
        }
      }
    }
    return result;
  }

  Future<void> openStore(String storeName, [String? storeId]) async {
    String? resolvedId = storeId;
    if (resolvedId == null || resolvedId.isEmpty) {
      resolvedId = knownStores[storeName.trim()];
    }

    if (resolvedId != null && resolvedId.isNotEmpty) {
      Get.toNamed('/store', arguments: {'id': resolvedId});
      return;
    }

    try {
      final stores = await DataService.getBusinesses(search: storeName);
      final match = stores.firstWhereOrNull(
        (s) => s['businessName'].toString().trim() == storeName.trim(),
      );
      if (match != null && match['id'] != null) {
        final id = match['id'].toString();
        knownStores[storeName.trim()] = id;
        Get.toNamed('/store', arguments: {'id': id});
        return;
      }
    } catch (_) {}

    Get.snackbar(
      'المتجر',
      'تعذر فتح المتجر المحدد حالياً',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
    );
  }

  void _loadPersistedMessages() {
    try {
      final raw = StorageService.getAiChatHistory();
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
              .toList();
          messages.assignAll(loaded);
        }
      }
    } catch (e) {
      // Ignored if storage corrupted
    }
  }

  void _persistMessages() {
    try {
      final validMessages = messages
          .where((m) => !m.isLoading && !m.isError && m.text.isNotEmpty)
          .toList();
      // Keep last 20 messages to balance history size and memory
      final slice = validMessages.length > 20
          ? validMessages.sublist(validMessages.length - 20)
          : validMessages;
      final raw = jsonEncode(slice.map((m) => m.toJson()).toList());
      StorageService.saveAiChatHistory(raw);
    } catch (e) {
      // Ignored
    }
  }

  void startNewChat() {
    cancelRequest();
    messages.clear();
    _error.value = null;
    _isLoading.value = false;
    _lastMessage = null;
    _lastContext = null;
    StorageService.clearAiChatHistory();
  }

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
      statusText: 'جاري البحث والتحليل في السوق...',
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
      bool streamReceivedTokens = false;
      String accumulatedText = '';

      final stream = _aiService.askAssistantStream(
        message: trimmed,
        context: context,
        history: historyList,
        shownProductIds: shownProductIds,
        cancelToken: _cancelToken,
      );

      await for (final event in stream) {
        final index = messages.indexWhere((m) => m.id == assistantMsgId);
        if (index == -1) break;

        if (event is AiTokenEvent) {
          streamReceivedTokens = true;
          accumulatedText += event.token;
          messages[index] = messages[index].copyWith(
            text: accumulatedText,
            isLoading: true,
          );
          messages.refresh();
        } else if (event is AiStatusEvent) {
          if (accumulatedText.isEmpty) {
            messages[index] = messages[index].copyWith(
              statusText: event.message,
              isLoading: true,
            );
            messages.refresh();
          }
        } else if (event is AiDoneEvent) {
          final response = event.response;
          List<AiBlock> finalBlocks = response.blocks;
          if (shownProductIds.isNotEmpty && _isDetailFollowUp(trimmed)) {
            finalBlocks = response.blocks
                .where((b) => b.type != 'product')
                .toList();
          }

          final finalText = response.text.isNotEmpty ? response.text : accumulatedText;

          messages[index] = ChatMessage(
            id: assistantMsgId,
            role: 'assistant',
            text: cleanAiDisplayText(finalText),
            blocks: finalBlocks,
            recommendations: response.recommendations,
            sources: response.sources,
            timestamp: DateTime.now(),
            isLoading: false,
          );
          _extractStoresFromMessage(messages[index]);
          messages.refresh();
          _persistMessages();
          return;
        } else if (event is AiErrorEvent) {
          if (streamReceivedTokens && accumulatedText.isNotEmpty) {
            messages[index] = messages[index].copyWith(
              text: cleanAiDisplayText(accumulatedText),
              isLoading: false,
            );
            messages.refresh();
            _persistMessages();
            return;
          }
          throw Exception(event.error);
        }
      }
    } catch (e) {
      // Fallback: If streaming fails or connection is severed, use non-streaming askAssistant
      try {
        final response = await _aiService.askAssistant(
          message: trimmed,
          context: context,
          history: historyList,
          shownProductIds: shownProductIds,
          cancelToken: _cancelToken,
        );

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
            text: cleanAiDisplayText(response.text),
            blocks: finalBlocks,
            recommendations: response.recommendations,
            sources: response.sources,
            timestamp: DateTime.now(),
            isLoading: false,
          );
          _extractStoresFromMessage(messages[index]);
          messages.refresh();
          _persistMessages();
        }
        return;
      } catch (fallbackError) {
        final errorMsg = fallbackError.toString().replaceAll('Exception: ', '');
        _error.value = errorMsg;

        final index = messages.indexWhere((m) => m.id == assistantMsgId);
        if (index != -1) {
          if (errorMsg == 'تم إلغاء الطلب') {
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
