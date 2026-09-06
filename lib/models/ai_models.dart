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
      text: json['text'] ?? '',
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

  AiBlock({
    required this.type,
    this.productId,
    this.storeId,
    this.productIds,
  });

  factory AiBlock.fromJson(Map<String, dynamic> json) {
    return AiBlock(
      type: json['type'] ?? 'unknown',
      productId: json['productId'],
      storeId: json['storeId'],
      productIds: json['productIds'] != null ? List<String>.from(json['productIds']) : null,
    );
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
}

class AiSource {
  final String type;
  final String id;

  AiSource({required this.type, required this.id});

  factory AiSource.fromJson(Map<String, dynamic> json) {
    return AiSource(
      type: json['type'] ?? '',
      id: json['id'] ?? '',
    );
  }
}

class ChatMessage {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final List<AiBlock> blocks;
  final List<AiRecommendation> recommendations;
  final DateTime timestamp;
  final bool isLoading;
  final bool isError;
  final String? errorMessage;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.blocks = const [],
    this.recommendations = const [],
    required this.timestamp,
    this.isLoading = false,
    this.isError = false,
    this.errorMessage,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  ChatMessage copyWith({
    String? id,
    String? role,
    String? text,
    List<AiBlock>? blocks,
    List<AiRecommendation>? recommendations,
    DateTime? timestamp,
    bool? isLoading,
    bool? isError,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      blocks: blocks ?? this.blocks,
      recommendations: recommendations ?? this.recommendations,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

