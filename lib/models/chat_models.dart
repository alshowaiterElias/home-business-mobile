/// Data models for the chat system.
/// All classes have `fromJson` factories matching the backend API response shape.

class ChatParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final String? lastReadMessageId;
  final DateTime joinedAt;
  final bool isMuted;
  final bool isArchived;
  final bool isDeleted;
  final ChatUser user;

  ChatParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.lastReadMessageId,
    required this.joinedAt,
    this.isMuted = false,
    this.isArchived = false,
    this.isDeleted = false,
    required this.user,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      lastReadMessageId: json['lastReadMessageId'] ?? json['last_read_message_id'],
      joinedAt: DateTime.parse(json['joinedAt'] ?? json['joined_at'] ?? DateTime.now().toIso8601String()),
      isMuted: json['isMuted'] ?? json['is_muted'] ?? false,
      isArchived: json['isArchived'] ?? json['is_archived'] ?? false,
      isDeleted: json['isDeleted'] ?? json['is_deleted'] ?? false,
      user: ChatUser.fromJson(json['user'] ?? {}),
    );
  }
}

class ChatUser {
  final String id;
  final String phoneNumber;
  final ChatBusiness? business;

  ChatUser({required this.id, required this.phoneNumber, this.business});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? '',
      business: json['business'] != null ? ChatBusiness.fromJson(json['business']) : null,
    );
  }

  /// Display name: business name if seller, phone number otherwise.
  String get displayName => business?.businessName ?? phoneNumber;

  /// Logo URL if seller, null otherwise.
  String? get avatarUrl => business?.logoUrl;
}

class ChatBusiness {
  final String id;
  final String businessName;
  final String? logoUrl;
  final String? contactPhone;

  ChatBusiness({required this.id, required this.businessName, this.logoUrl, this.contactPhone});

  factory ChatBusiness.fromJson(Map<String, dynamic> json) {
    return ChatBusiness(
      id: json['id'] ?? '',
      businessName: json['businessName'] ?? json['business_name'] ?? '',
      logoUrl: json['logoUrl'] ?? json['logo_url'],
      contactPhone: json['contactPhone'] ?? json['contact_phone'],
    );
  }
}

class Conversation {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatParticipant> participants;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;

  Conversation({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? json['updated_at'] ?? DateTime.now().toIso8601String()),
      participants: (json['participants'] as List? ?? [])
          .map((p) => ChatParticipant.fromJson(p))
          .toList(),
      lastMessage: json['lastMessage'] != null ? ChatMessage.fromJson(json['lastMessage']) : null,
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isArchived: json['isArchived'] ?? false,
    );
  }

  /// Get the other participant in a 1:1 conversation.
  ChatParticipant? getOtherParticipant(String currentUserId) {
    try {
      return participants.firstWhere((p) => p.userId != currentUserId);
    } catch (_) {
      return participants.isNotEmpty ? participants.first : null;
    }
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String type;
  final String? text;
  final String? tempId;
  final String? replyToId;
  final DateTime? deletedAt;
  final bool deletedForAll;
  final DateTime createdAt;
  final ChatUser? sender;
  final MessageReference? reference;
  final ChatMessage? replyTo;

  // Local-only state for optimistic sending
  bool isPending;
  bool isFailed;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.type = 'TEXT',
    this.text,
    this.tempId,
    this.replyToId,
    this.deletedAt,
    this.deletedForAll = false,
    required this.createdAt,
    this.sender,
    this.reference,
    this.replyTo,
    this.isPending = false,
    this.isFailed = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? json['conversation_id'] ?? '',
      senderId: json['senderId'] ?? json['sender_id'] ?? '',
      type: json['type'] ?? 'TEXT',
      text: json['text'],
      tempId: json['tempId'] ?? json['temp_id'],
      replyToId: json['replyToId'] ?? json['reply_to_id'],
      deletedAt: json['deletedAt'] != null ? DateTime.tryParse(json['deletedAt']) : null,
      deletedForAll: json['deletedForAll'] ?? json['deleted_for_all'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      sender: json['sender'] != null ? ChatUser.fromJson(json['sender']) : null,
      reference: json['reference'] != null ? MessageReference.fromJson(json['reference']) : null,
      replyTo: json['replyTo'] != null ? ChatMessage.fromJson(json['replyTo']) : null,
    );
  }

  bool get isProductReference => type == 'PRODUCT_REFERENCE';
  bool get isStoreReference => type == 'STORE_REFERENCE';
  bool get isSystemMessage => type == 'SYSTEM_MESSAGE';
  bool get isTextMessage => type == 'TEXT';
}

class MessageReference {
  final String id;
  final String messageId;
  final String referenceType;
  final String referenceId;
  final String? snapshotTitle;
  final String? snapshotPrice;
  final String? snapshotImage;
  final Map<String, dynamic>? snapshotMeta;

  MessageReference({
    required this.id,
    required this.messageId,
    required this.referenceType,
    required this.referenceId,
    this.snapshotTitle,
    this.snapshotPrice,
    this.snapshotImage,
    this.snapshotMeta,
  });

  factory MessageReference.fromJson(Map<String, dynamic> json) {
    return MessageReference(
      id: json['id'] ?? '',
      messageId: json['messageId'] ?? json['message_id'] ?? '',
      referenceType: json['referenceType'] ?? json['reference_type'] ?? '',
      referenceId: json['referenceId'] ?? json['reference_id'] ?? '',
      snapshotTitle: json['snapshotTitle'] ?? json['snapshot_title'],
      snapshotPrice: json['snapshotPrice'] ?? json['snapshot_price'],
      snapshotImage: json['snapshotImage'] ?? json['snapshot_image'],
      snapshotMeta: json['snapshotMeta'] ?? json['snapshot_meta'],
    );
  }
}
