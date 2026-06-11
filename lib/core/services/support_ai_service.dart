import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env.dart';

/// One turn in the conversation.
class AiMessage {
  final String role; // 'system' | 'user' | 'assistant'
  final String content;
  final DateTime sentAt;
  const AiMessage({
    required this.role,
    required this.content,
    required this.sentAt,
  });
  Map<String, dynamic> toJson() => {'role': role, 'content': content};
  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
        role: j['role']?.toString() ?? 'user',
        content: j['content']?.toString() ?? '',
        sentAt: DateTime.now(),
      );
}

/// Client for the support assistant. Talks to a backend you control
/// which then calls MiniMax-M3 (or any OpenAI-compatible chat
/// completions endpoint). Keeping the API key off-device means you
/// can rate-limit, log, A/B-test prompts, and swap models later
/// without shipping a new app build.
class SupportAiService {
  SupportAiService._();
  static final SupportAiService instance = SupportAiService._();

  bool get isConfigured => AppEnv.supportAiUrl.isNotEmpty;

  /// Sends the conversation to the backend and returns the assistant's
  /// reply. Throws on network / non-2xx.
  Future<AiMessage> chat({
    required List<AiMessage> history,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (!isConfigured) {
      // Local fallback that just acknowledges the user — useful in dev
      // when no backend is wired up yet.
      AiMessage? lastUser;
      for (final m in history.reversed) {
        if (m.role == 'user') {
          lastUser = m;
          break;
        }
      }
      return _fallback(lastUser?.content ?? '');
    }
    final payload = {
      'model': AppEnv.supportAiModel,
      'messages': [
        {'role': 'system', 'content': AppEnv.supportAiSystemPrompt},
        ...history.map((m) => m.toJson()),
      ],
    };
    final res = await http
        .post(
          Uri.parse(AppEnv.supportAiUrl),
          headers: {
            'Content-Type': 'application/json',
            if (AppEnv.supportAiApiKey.isNotEmpty)
              'Authorization': 'Bearer ${AppEnv.supportAiApiKey}',
          },
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('AI backend returned ${res.statusCode}');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    // Accept either { message: { role, content } } or
    // { choices: [{ message: { role, content } }] } (OpenAI style).
    final dynamic msgJson = body['message'] ??
        (body['choices'] is List && (body['choices'] as List).isNotEmpty
            ? (body['choices'] as List).first['message']
            : null);
    if (msgJson is Map<String, dynamic>) {
      return AiMessage.fromJson(msgJson);
    }
    return _fallback(history.isNotEmpty ? history.last.content : '');
  }

  /// Streaming variant. Yields assistant text as it arrives. The
  /// backend must respond with `text/event-stream` (SSE), one
  /// `data: {"delta":"..."}` line per chunk.
  Stream<String> chatStream({
    required List<AiMessage> history,
    Duration timeout = const Duration(seconds: 60),
  }) async* {
    if (!isConfigured) {
      AiMessage? lastUser;
      for (final m in history.reversed) {
        if (m.role == 'user') {
          lastUser = m;
          break;
        }
      }
      final reply = await _fallback(lastUser?.content ?? '');
      yield reply.content;
      return;
    }
    final client = http.Client();
    try {
      final req = http.Request('POST', Uri.parse(AppEnv.supportAiUrl));
      req.headers['Content-Type'] = 'application/json';
      req.headers['Accept'] = 'text/event-stream';
      if (AppEnv.supportAiApiKey.isNotEmpty) {
        req.headers['Authorization'] = 'Bearer ${AppEnv.supportAiApiKey}';
      }
      req.body = jsonEncode({
        'model': AppEnv.supportAiModel,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': AppEnv.supportAiSystemPrompt},
          ...history.map((m) => m.toJson()),
        ],
      });
      final res = await client.send(req).timeout(timeout);
      if (res.statusCode != 200) {
        throw Exception('AI stream error ${res.statusCode}');
      }
      await for (final chunk in res.stream.transform(utf8.decoder)) {
        for (final line in chunk.split('\n')) {
          final t = line.trim();
          if (!t.startsWith('data:')) continue;
          final data = t.substring(5).trim();
          if (data == '[DONE]') return;
          try {
            final j = jsonDecode(data) as Map<String, dynamic>;
            final delta = j['delta']?.toString() ??
                j['content']?.toString() ??
                '';
            if (delta.isNotEmpty) yield delta;
          } catch (_) {
            // ignore malformed chunks
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<AiMessage> _fallback(String userText) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final lowered = userText.toLowerCase();
    String reply;
    if (lowered.contains('track') || lowered.contains('apk')) {
      reply =
          'You can track any AirPak Express parcel at the Tracking page '
          'using the number that starts with "APK". Want me to take you '
          'there?';
    } else if (lowered.contains('price') || lowered.contains('cost') ||
        lowered.contains('rate')) {
      reply =
          'Pricing depends on weight, dimensions, destination, and the '
          'service level (Express / Standard / Air / Sea). A 1kg parcel '
          'from KL to Singapore starts around USD 18 with Express.';
    } else if (lowered.contains('fpx') || lowered.contains('bank')) {
      reply =
          'We support FPX (Malaysian online banking) through Stripe. Pick '
          'FPX at checkout — the usual online banking login will pop up.';
    } else if (lowered.contains('refund') || lowered.contains('cancel')) {
      reply =
          'For cancellations within 24h of booking we refund in full. '
          'I can connect you to a human agent to process it — just say '
          'the word.';
    } else {
      reply =
          'Got it — let me connect you to a human agent so they can help '
          'in detail. Average reply time is 2 minutes.';
    }
    return AiMessage(role: 'assistant', content: reply, sentAt: DateTime.now());
  }
}
