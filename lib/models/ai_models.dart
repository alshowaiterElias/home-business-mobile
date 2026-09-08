String cleanAiDisplayText(String raw) {
  if (raw.isEmpty) return '';
  return raw
      .replaceAll(RegExp(r'```(?:json)?[\s\S]*?```', caseSensitive: false), '')
      .replaceAll(RegExp(r'<product\s+id="[^"]*"\s*></product>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<product\s+id="[^"]*"\s*/>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<product[^>]*>[\s\S]*?</product>', caseSensitive: false), '')
      .replaceAll(RegExp(r'</?product[^>]*>', caseSensitive: false), '')
      .trim();
}

class AiResponse {
  final String requestId;
  final String text;
  final List<AiBlock> blocks;
  final List<AiRecommendation> recommendations;
  final List<AiSource> sources;

  AiResponse({
    required this.requestId,
    required this.text,
    required this.blocks,
    required this.recommendations,
    required this.sources,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    return AiResponse(
      requestId: json['requestId'] ?? '',
      text: cleanAiDisplayText(json['text'] ?? ''),
      blocks: json['blocks'] != null
          ? (json['blocks'] as List).map((i) => AiBlock.fromJson(i)).toList()
          : [],
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List).map((i) => AiRecommendation.fromJson(i)).toList()
          : [],
      sources: json['sources'] != null
          ? (json['sources'] as List).map((i) => AiSource.fromJson(i)).toList()
          : [],
    );
  }
}

class AiBlock {
  final String type;
  final String? productId;
  final String? storeId;
  final List<String>? productIds;
  final Map<String, dynamic>? productData;

  AiBlock({
    required this.type,
    this.productId,
    this.storeId,
    this.productIds,
    this.productData,
  });

  factory AiBlock.fromJson(Map<String, dynamic> json) {
    return AiBlock(
      type: json['type'] ?? 'unknown',
      productId: json['productId'],
      storeId: json['storeId'],
      productIds: json['productIds'] != null ? List<String>.from(json['productIds']) : null,
      productData: json['product'] is Map<String, dynamic>
          ? json['product'] as Map<String, dynamic>
          : (json['productData'] is Map<String, dynamic> ? json['productData'] as Map<String, dynamic> : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (productId != null) 'productId': productId,
      if (storeId != null) 'storeId': storeId,
      if (productIds != null) 'productIds': productIds,
      if (productData != null) 'product': productData,
    };
  }
}

class AiRecommendation {
  final String text;

  AiRecommendation({required this.text});

  factory AiRecommendation.fromJson(Map<String, dynamic> json) {
    return AiRecommendation(
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
    };
  }
}

class AiSource {
  final String type;
  final String id;
  final String? name;

  AiSource({required this.type, required this.id, this.name});

  factory AiSource.fromJson(Map<String, dynamic> json) {
    return AiSource(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      if (name != null) 'name': name,
    };
  }
}

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final List<AiBlock> blocks;
  final List<AiRecommendation> recommendations;
  final List<AiSource> sources;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;
  final String? statusText;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.blocks = const [],
    this.recommendations = const [],
    this.sources = const [],
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
    this.statusText,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'sources': sources.map((s) => s.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      if (statusText != null) 'statusText': statusText,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      text: cleanAiDisplayText(json['text'] ?? ''),
      blocks: json['blocks'] != null
          ? (json['blocks'] as List)
              .map((i) => AiBlock.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      recommendations: json['recommendations'] != null
          ? (json['recommendations'] as List)
              .map((i) => AiRecommendation.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      sources: json['sources'] != null
          ? (json['sources'] as List)
              .map((i) => AiSource.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      statusText: json['statusText'],
    );
  }

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    List<AiBlock>? blocks,
    List<AiRecommendation>? recommendations,
    List<AiSource>? sources,
    DateTime? timestamp,
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    String? statusText,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      blocks: blocks ?? this.blocks,
      recommendations: recommendations ?? this.recommendations,
      sources: sources ?? this.sources,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      statusText: statusText ?? this.statusText,
    );
  }
}

/// Server-Sent Events (SSE) stream event types for progressive AI streaming
abstract class AiStreamEvent {}

class AiTokenEvent extends AiStreamEvent {
  final String token;
  AiTokenEvent(this.token);
}

class AiStatusEvent extends AiStreamEvent {
  final String message;
  AiStatusEvent(this.message);
}

class AiDoneEvent extends AiStreamEvent {
  final AiResponse response;
  AiDoneEvent(this.response);
}

class AiErrorEvent extends AiStreamEvent {
  final String error;
  AiErrorEvent(this.error);
}

