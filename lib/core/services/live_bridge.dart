import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Live event types emitted by the bridge.
enum LiveEventType { hello, presence, typing, chat, pong, authError, raw }

class LiveEvent {
  final LiveEventType type;
  final String? rawType;
  final String? userId;
  final String? name;
  final String? role;
  final bool? online;
  final bool? typing;
  final String? text;
  final Map<String, dynamic>? message;
  final Map<String, dynamic> payload;
  final int seq;
  final DateTime at;

  LiveEvent({
    required this.type,
    this.rawType,
    this.userId,
    this.name,
    this.role,
    this.online,
    this.typing,
    this.text,
    this.message,
    this.payload = const {},
    this.seq = 0,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  factory LiveEvent.fromJson(Map<String, dynamic> j) {
    final t = (j['type'] as String?) ?? 'chat';
    return LiveEvent(
      type: switch (t) {
        'hello' => LiveEventType.hello,
        'presence' => LiveEventType.presence,
        'typing' => LiveEventType.typing,
        'chat' => LiveEventType.chat,
        'pong' => LiveEventType.pong,
        _ => LiveEventType.raw,
      },
      rawType: t,
      userId: j['userId'] as String?,
      name: j['name'] as String?,
      role: j['role'] as String?,
      online: j['online'] as bool?,
      typing: j['typing'] as bool?,
      text: j['text'] as String?,
      message: j['message'] is Map
          ? Map<String, dynamic>.from(j['message'] as Map)
          : null,
      payload: j,
      seq: (j['seq'] as int?) ?? 0,
      at: (j['at'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(j['at'] as int)
          : DateTime.now(),
    );
  }
}

/// WebSocket client for the live bridge. Auto-reconnects with backoff
/// and streams every event to listeners.
class LiveBridgeClient {
  final String baseUrl; // e.g. http://localhost:3001
  final String token;   // dev:USER_ID or signed JWT
  final String room;
  final String role;    // 'user' or 'admin'
  final String userId;
  final String displayName;

  WebSocketChannel? _ch;
  StreamSubscription? _sub;
  Timer? _retry;
  Timer? _ping;
  bool _disposed = false;
  int _backoff = 1;
  late String _currentRoom = room;

  final _events = StreamController<LiveEvent>.broadcast();
  final _connection = ValueNotifier<LiveConnState>(LiveConnState.idle);

  LiveBridgeClient({
    required this.baseUrl,
    required this.token,
    required this.room,
    required this.role,
    required this.userId,
    this.displayName = '',
  });

  Stream<LiveEvent> get events => _events.stream;
  Stream<LiveEvent> get stream => _events.stream;
  ValueListenable<LiveConnState> get connection => _connection;

  /// Switch to a different room. Closes the current socket and
  /// reconnects with the new room parameter.
  void switchRoom(String newRoom) {
    if (_currentRoom == newRoom) return;
    _currentRoom = newRoom;
    _ping?.cancel();
    _sub?.cancel();
    _ch?.sink.close();
    _ch = null;
    _sub = null;
    connect();
  }

  void connect() {
    if (_disposed) return;
    _connection.value = LiveConnState.connecting;
    final base = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
    final url =
        '$base/ws?token=${Uri.encodeComponent(token)}&room=${Uri.encodeComponent(_currentRoom)}&role=${Uri.encodeComponent(role)}';
    try {
      _ch = WebSocketChannel.connect(Uri.parse(url));
      _connection.value = LiveConnState.connected;
      _backoff = 1;
      _sub = _ch!.stream.listen(_onMessage, onError: _onError, onDone: _onDone);
      // Heartbeat every 20s.
      _ping?.cancel();
      _ping = Timer.periodic(const Duration(seconds: 20), (_) {
        try {
          _ch?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (_) {}
      });
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final j = jsonDecode(raw is String ? raw : raw.toString()) as Map<String, dynamic>;
      _events.add(LiveEvent.fromJson(j));
    } catch (_) {}
  }

  void _onError(Object _) => _scheduleReconnect();
  void _onDone() => _scheduleReconnect();

  void _scheduleReconnect() {
    if (_disposed) return;
    _connection.value = LiveConnState.reconnecting;
    _ping?.cancel();
    _sub?.cancel();
    _sub = null;
    _ch = null;
    final ms = (_backoff * 1000).clamp(1000, 15000);
    _backoff = (_backoff * 2).clamp(1, 8);
    _retry?.cancel();
    _retry = Timer(Duration(milliseconds: ms), connect);
  }

  void sendChat(String text) {
    if (_ch == null) return;
    try {
      _ch!.sink.add(jsonEncode({
        'type': 'chat',
        'text': text,
        'userId': userId,
        'name': displayName,
        'role': role,
        'at': DateTime.now().millisecondsSinceEpoch,
      }));
    } catch (_) {}
  }

  void sendTyping(bool typing) {
    if (_ch == null) return;
    try {
      _ch!.sink.add(jsonEncode({
        'type': 'typing',
        'typing': typing,
        'userId': userId,
        'name': displayName,
        'role': role,
      }));
    } catch (_) {}
  }

  Future<void> dispose() async {
    _disposed = true;
    _ping?.cancel();
    _retry?.cancel();
    await _sub?.cancel();
    await _ch?.sink.close();
    await _events.close();
  }
}

enum LiveConnState { idle, connecting, connected, reconnecting }
