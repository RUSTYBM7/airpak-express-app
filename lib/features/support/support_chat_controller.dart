import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/support_ai_service.dart';

/// One chat message. Persisted in SharedPreferences.
@immutable
class ChatMessage {
  final String id;
  final String role; // 'user' | 'agent' | 'system' | 'ai'
  final String text;
  final DateTime sentAt;
  final String? threadId;
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.sentAt,
    this.threadId,
  });
  Map<String, dynamic> toMap() => {
        'id': id,
        'role': role,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'threadId': threadId,
      };
  factory ChatMessage.fromMap(Map m) => ChatMessage(
        id: m['id'] as String,
        role: m['role'] as String,
        text: m['text'] as String,
        sentAt: DateTime.tryParse(m['sentAt'] as String? ?? '') ?? DateTime.now(),
        threadId: m['threadId'] as String?,
      );
}

@immutable
class SupportChatState {
  final String threadId;
  final List<ChatMessage> messages;
  final bool humanGreeted;
  final bool hasUnreadAgentReply;
  final DateTime? lastReadAt;
  const SupportChatState({
    required this.threadId,
    required this.messages,
    required this.humanGreeted,
    required this.hasUnreadAgentReply,
    this.lastReadAt,
  });
  SupportChatState copyWith({
    String? threadId,
    List<ChatMessage>? messages,
    bool? humanGreeted,
    bool? hasUnreadAgentReply,
    DateTime? lastReadAt,
  }) =>
      SupportChatState(
        threadId: threadId ?? this.threadId,
        messages: messages ?? this.messages,
        humanGreeted: humanGreeted ?? this.humanGreeted,
        hasUnreadAgentReply: hasUnreadAgentReply ?? this.hasUnreadAgentReply,
        lastReadAt: lastReadAt ?? this.lastReadAt,
      );

  static SupportChatState empty(String userId) => SupportChatState(
        threadId: 'th_${userId}_${DateTime.now().millisecondsSinceEpoch}',
        messages: const [],
        humanGreeted: false,
        hasUnreadAgentReply: false,
      );
}

/// Per-thread controller. Survives reloads + sign-out.
class SupportChatController extends StateNotifier<SupportChatState> {
  SupportChatController({
    required this.userId,
    required this.ai,
    SharedPreferences? prefs,
    SupportChatState? initial,
  }) : super(initial ?? _load(prefs, userId));

  final String userId;
  final SupportAiService ai;
  SharedPreferences? _prefs;
  static const _k = 'support_chat_v3';

  String get threadId => state.threadId;

  String _key() {
    final uid = userId.isEmpty ? 'anon' : userId;
    return '$_k:$uid';
  }

  SharedPreferences get _safePrefs {
    if (_prefs != null) return _prefs!;
    // Will never be hit in practice — controller is constructed with prefs.
    throw StateError('SharedPreferences not ready');
  }

  Future<void> hydrate(SharedPreferences prefs) async {
    _prefs = prefs;
    state = _load(prefs, userId);
  }

  static SupportChatState _load(SharedPreferences? prefs, String uid) {
    if (prefs == null) return SupportChatState.empty(uid);
    final key = 'support_chat_v3:${uid.isEmpty ? "anon" : uid}';
    String? raw;
    try {
      raw = prefs.getString(key);
    } catch (_) {
      return SupportChatState.empty(uid);
    }
    if (raw == null) return SupportChatState.empty(uid);
    try {
      final m = jsonDecode(raw) as Map;
      final messages = ((m['messages'] as List?) ?? const [])
          .map((e) => ChatMessage.fromMap((e as Map).cast<String, dynamic>()))
          .toList();
      return SupportChatState(
        threadId: (m['threadId'] as String?) ??
            'th_${uid}_${DateTime.now().millisecondsSinceEpoch}',
        messages: messages,
        humanGreeted: (m['humanGreeted'] as bool?) ?? false,
        hasUnreadAgentReply: (m['hasUnreadAgentReply'] as bool?) ?? false,
        lastReadAt: m['lastReadAt'] != null
            ? DateTime.tryParse(m['lastReadAt'] as String)
            : null,
      );
    } catch (_) {
      return SupportChatState.empty(uid);
    }
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    await _prefs!.setString(_key(), jsonEncode({
      'threadId': state.threadId,
      'messages': state.messages.map((m) => m.toMap()).toList(),
      'humanGreeted': state.humanGreeted,
      'hasUnreadAgentReply': state.hasUnreadAgentReply,
      'lastReadAt': state.lastReadAt?.toIso8601String(),
    }));
  }

  void markRead() {
    if (!state.hasUnreadAgentReply) return;
    state = state.copyWith(hasUnreadAgentReply: false, lastReadAt: DateTime.now());
    _persist();
  }

  /// User sends a message.
  Future<void> sendUser(String text) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      role: 'user',
      text: text.trim(),
      sentAt: DateTime.now(),
      threadId: state.threadId,
    );
    final messages = [...state.messages, msg];
    state = state.copyWith(messages: messages, hasUnreadAgentReply: false);
    await _persist();

    // First user message: greet + hand-off system message (one-time).
    if (!state.humanGreeted) {
      final systemMsg = ChatMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch + 1}',
        role: 'system',
        text:
            'A human agent will join the chat within ~2 minutes. You can keep typing — your messages stay in the thread.',
        sentAt: DateTime.now().add(const Duration(milliseconds: 1)),
        threadId: state.threadId,
      );
      state = state.copyWith(
        messages: [...state.messages, systemMsg],
        humanGreeted: true,
      );
      await _persist();
    }

    // Best-effort AI hint.
    unawaited(_maybeShowAiSuggestion(text));
  }

  Future<void> _maybeShowAiSuggestion(String userText) async {
    try {
      final reply = await ai.chat(history: [
        ...state.messages
            .where((m) => m.role == 'user' || m.role == 'agent')
            .map((m) => AiMessage(role: m.role, content: m.text, sentAt: m.sentAt)),
        AiMessage(role: 'user', content: userText, sentAt: DateTime.now()),
      ]);
      if (reply.content.isEmpty) return;
      final hint = ChatMessage(
        id: 'm_${DateTime.now().microsecondsSinceEpoch + 2}',
        role: 'ai',
        text: reply.content,
        sentAt: DateTime.now().add(const Duration(milliseconds: 2)),
        threadId: state.threadId,
      );
      if (!mounted) return;
      state = state.copyWith(messages: [...state.messages, hint]);
      await _persist();
    } catch (_) {}
  }

  /// Admin / agent reply. Surfaces an unread badge for the user.
  Future<void> sendAgent(String text,
      {String agentName = 'AirPak Support'}) async {
    if (text.trim().isEmpty) return;
    final msg = ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      role: 'agent',
      text: text.trim(),
      sentAt: DateTime.now(),
      threadId: state.threadId,
    );
    state = state.copyWith(
      messages: [...state.messages, msg],
      hasUnreadAgentReply: true,
    );
    await _persist();
  }

  Future<void> clear() async {
    state = SupportChatState.empty(userId);
    await _persist();
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final supportAiServiceProvider = Provider<SupportAiService>((ref) {
  return SupportAiService.instance;
});

/// Per-user-id chat controller family.
final supportChatControllerProvider = StateNotifierProvider.family<
    SupportChatController, SupportChatState, String>((ref, userId) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final ai = ref.watch(supportAiServiceProvider);
  final ctrl = SupportChatController(
    userId: userId,
    ai: ai,
    initial: SupportChatState.empty(userId),
  );
  // When SharedPreferences arrives, hydrate the controller.
  prefsAsync.whenData((prefs) {
    Future.microtask(() => ctrl.hydrate(prefs));
  });
  return ctrl;
});
