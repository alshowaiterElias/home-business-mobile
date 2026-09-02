import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_client.dart';
import 'storage_service.dart';

/// Singleton service managing the Socket.IO connection for real-time chat.
/// Connects with JWT auth, auto-reconnects, and exposes event streams.
class SocketService {
  SocketService._();
  static final SocketService _instance = SocketService._();
  static SocketService get instance => _instance;

  io.Socket? _socket;
  bool _isConnected = false;

  // ── Event stream controllers ────────────────────────────────────
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageDeletedController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStartController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStopController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  // ── Public streams ──────────────────────────────────────────────
  Stream<Map<String, dynamic>> get onNewMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated => _conversationUpdatedController.stream;
  Stream<Map<String, dynamic>> get onMessageRead => _messageReadController.stream;
  Stream<Map<String, dynamic>> get onMessageDeleted => _messageDeletedController.stream;
  Stream<Map<String, dynamic>> get onTypingStart => _typingStartController.stream;
  Stream<Map<String, dynamic>> get onTypingStop => _typingStopController.stream;
  Stream<bool> get onConnectionStatusChanged => _connectionStatusController.stream;

  bool get isConnected => _isConnected;

  /// Connect to the Socket.IO server using the stored JWT token.
  void connect() {
    final token = StorageService.getToken();
    if (token == null) return;

    // Derive the server URL (strip /api/v1)
    final serverUrl = ApiClient.baseUrl.replaceAll('/api/v1', '');

    _socket?.dispose();
    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _connectionStatusController.add(true);
      print('🔌 Socket connected');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _connectionStatusController.add(false);
      print('🔌 Socket disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      print('🔌 Socket connect error: $error');
    });

    // ── Listen for real-time events ────────────────────────────────
    _socket!.on('message:new', (data) {
      _messageController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('conversation:updated', (data) {
      _conversationUpdatedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('message:read', (data) {
      _messageReadController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('message:deleted', (data) {
      _messageDeletedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('typing:start', (data) {
      _typingStartController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('typing:stop', (data) {
      _typingStopController.add(Map<String, dynamic>.from(data));
    });
  }

  /// Disconnect from the server (e.g. on logout).
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  /// Join a conversation room (call when opening a chat).
  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', {'conversationId': conversationId});
  }

  /// Leave a conversation room (call when closing a chat).
  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', {'conversationId': conversationId});
  }

  /// Emit typing start indicator.
  void startTyping(String conversationId) {
    _socket?.emit('typing:start', {'conversationId': conversationId});
  }

  /// Emit typing stop indicator.
  void stopTyping(String conversationId) {
    _socket?.emit('typing:stop', {'conversationId': conversationId});
  }

  /// Emit read receipt.
  void emitReadReceipt(String conversationId, String messageId) {
    _socket?.emit('message:read', {'conversationId': conversationId, 'messageId': messageId});
  }

  /// Dispose all stream controllers.
  void dispose() {
    disconnect();
    _messageController.close();
    _conversationUpdatedController.close();
    _messageReadController.close();
    _messageDeletedController.close();
    _typingStartController.close();
    _typingStopController.close();
    _connectionStatusController.close();
  }
}
