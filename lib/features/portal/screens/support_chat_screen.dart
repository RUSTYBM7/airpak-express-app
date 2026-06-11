import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../../app/router.dart';
import '../../../core/config/env.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/chat.dart';
import '../../../core/services/live_bridge.dart';
import '../../../core/services/support_ai_service.dart';
import '../../../core/widgets/motion.dart';
import '../../auth/providers/auth_controller.dart';

final _messagesProvider = FutureProvider.autoDispose
    .family<RepoResult<List<ChatMessage>>, String>((ref, threadId) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.messages(threadId);
});

/// Whom the user is currently talking to.
final _chatModeProvider =
    StateProvider.autoDispose<_ChatMode>((_) => _ChatMode.human);

enum _ChatMode { human, ai }

/// Apple Intelligence-style smart suggestions that appear as quick-pick
/// chips above the input. The actual content depends on the latest
/// AI message context.
class _SmartSuggestion {
  final String label;
  final String detail;
  final IconData icon;
  const _SmartSuggestion(this.label, this.detail, this.icon);
}

class SupportChatScreen extends ConsumerStatefulWidget {
  const SupportChatScreen({super.key});
  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _threadId = 'thread_demo';
  bool _sending = false;
  bool _aiStreaming = false;
  bool _composing = false;
  final List<ChatMessage> _local = [];
  final List<AiMessage> _aiHistory = [];
  LiveBridgeClient? _live;
  bool _agentTyping = false;
  String _agentName = '';
  bool _agentOnline = false;

  @override
  void initState() {
    super.initState();
    _connectBridge();
  }

  void _connectBridge() {
    if (!AppEnv.liveBridgeEnabled) return;
    final auth = ref.read(authControllerProvider);
    final userId = auth.userId;
    if (userId == null) return;
    _live = LiveBridgeClient(
      baseUrl: AppEnv.apiBaseUrl,
      token: 'dev:$userId',
      room: _threadId,
      role: 'user',
      userId: userId,
      displayName: auth.profile?.displayName ?? 'You',
    );
    _live!.events.listen((ev) {
      if (!mounted) return;
      if (ev.type == LiveEventType.presence) {
        setState(() {
          _agentOnline = ev.online ?? false;
          if (ev.role == 'admin' && (ev.online ?? false)) {
            _agentName = ev.name ?? _agentName;
          }
        });
      } else if (ev.type == LiveEventType.typing) {
        if (ev.role == 'admin') {
          setState(() => _agentTyping = ev.typing ?? false);
        }
      } else if (ev.type == LiveEventType.chat) {
        final m = ev.message;
        if (m == null) return;
        setState(() {
          _local.add(ChatMessage(
            id: m['id']?.toString() ?? DateTime.now().toIso8601String(),
            threadId: _threadId,
            senderId: m['userId']?.toString() ?? 'admin',
            senderName: m['name']?.toString() ?? 'AirPak Support',
            text: m['text']?.toString() ?? '',
            fromAgent: (m['role']?.toString() ?? 'admin') == 'admin',
            sentAt: DateTime.fromMillisecondsSinceEpoch(
                (m['at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch),
          ));
          _agentTyping = false;
        });
        _scrollDown();
      }
    });
    _live!.connect();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _live?.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    final mode = ref.read(_chatModeProvider);
    if (mode == _ChatMode.human) {
      await _sendToHuman(text);
    } else {
      await _sendToAi(text);
    }
  }

  Future<void> _sendToHuman(String text) async {
    final auth = ref.read(authControllerProvider);
    setState(() => _sending = true);
    // Also fan out via the live bridge so a connected admin sees it
    // instantly. The REST call below still persists it for replay.
    _live?.sendChat(text);
    final res = await ref.read(shipmentRepoProvider).postMessage(
          threadId: _threadId,
          senderId: auth.userId,
          senderName: auth.profile?.displayName ?? 'You',
          text: text,
          fromAgent: false,
        );
    if (res.data != null) {
      _local.add(res.data!);
      _ctrl.clear();
      Future.delayed(const Duration(milliseconds: 1200), () async {
        if (!mounted) return;
        final reply = await ref.read(shipmentRepoProvider).postMessage(
              threadId: _threadId,
              senderId: 'agent_1',
              senderName: 'AirPak Support',
              text:
                  'Thanks for reaching out! A support agent will respond within 2 minutes.',
              fromAgent: true,
            );
        if (reply.data != null && mounted) {
          setState(() => _local.add(reply.data!));
          _scrollDown();
        }
      });
    }
    if (mounted) setState(() => _sending = false);
    _scrollDown();
  }

  Future<void> _sendToAi(String text) async {
    setState(() {
      _sending = true;
      _aiStreaming = true;
    });
    _aiHistory.add(AiMessage(role: 'user', content: text, sentAt: DateTime.now()));
    _ctrl.clear();
    _scrollDown();
    try {
      final reply = await SupportAiService.instance.chat(history: _aiHistory);
      _aiHistory.add(reply);
    } catch (e) {
      _aiHistory.add(AiMessage(
          role: 'assistant',
          content: 'Sorry, the AI assistant is unavailable right now. '
              'Try switching to a human agent.',
          sentAt: DateTime.now()));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _aiStreaming = false;
        });
        _scrollDown();
      }
    }
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: MotionDurations.medium,
          curve: MotionCurves.hero,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(_chatModeProvider);
    final async = ref.watch(_messagesProvider(_threadId));
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ChatHeader(
              mode: mode,
              agentOnline: _agentOnline,
              agentTyping: _agentTyping,
              agentName: _agentName,
            ),
            if (mode == _ChatMode.ai && _aiHistory.isNotEmpty && !_aiStreaming)
              _SmartSuggestionsBar(
                context: context,
                onTap: (s) {
                  _ctrl.text = s.label;
                  _send();
                },
              ),
            Expanded(
              child: mode == _ChatMode.human
                  ? _buildHumanList(async)
                  : _buildAiList(),
            ),
            if (mode == _ChatMode.ai && _composing)
              _TypingPulse(prompt: _ctrl.text),
            _Composer(
              controller: _ctrl,
              onSend: _send,
              onChange: (v) => setState(() => _composing = v.isNotEmpty),
              sending: _sending,
              isAi: mode == _ChatMode.ai,
              hint: mode == _ChatMode.human
                  ? 'Message AirPak Support…'
                  : 'Ask anything about your shipment…',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHumanList(AsyncValue<RepoResult<List<ChatMessage>>> async) {
    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.brand)),
      error: (e, _) => Center(child: Text('Couldn\'t load: $e')),
      data: (res) {
        final all = [...?res.data, ..._local];
        return ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          itemCount: all.length,
          itemBuilder: (_, i) => StaggeredFadeIn(
            index: i,
            child: _Bubble(msg: all[i]),
          ),
        );
      },
    );
  }

  Widget _buildAiList() {
    if (_aiHistory.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppleIntelligenceGlow(
                size: 92,
                active: true,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.appleIntelligenceGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('How can I help?',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Text(
                'Powered by ${AppEnv.supportAiModel}',
                style: TextStyle(
                    color: context.textMutedColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const _WritingToolsRow(),
              const SizedBox(height: 18),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: const [
                  'Track my parcel',
                  'Shipping cost to Singapore',
                  'How do I cancel?',
                  'Do you support FPX?',
                ]
                    .map((s) => ActionChip(
                          label: Text(s),
                          backgroundColor: context.surfaceColor,
                          side: BorderSide(color: context.borderColor),
                          labelStyle: TextStyle(
                              color: context.textColor,
                              fontWeight: FontWeight.w600),
                          onPressed: () {
                            _ctrl.text = s;
                            _send();
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: _aiHistory.length + (_aiStreaming ? 1 : 0),
      itemBuilder: (_, i) {
        if (i >= _aiHistory.length) {
          return const _TypingBubble();
        }
        return StaggeredFadeIn(
          index: i,
          child: _AiBubble(msg: _aiHistory[i]),
        );
      },
    );
  }
}

/// Apple Intelligence horizontal "writing tools" — quick actions that
/// summarise / translate / rephrase the conversation.
class _WritingToolsRow extends StatelessWidget {
  const _WritingToolsRow();
  @override
  Widget build(BuildContext context) {
    const tools = [
      ('Summarise', Icons.summarize_rounded),
      ('Translate', Icons.translate_rounded),
      ('Proofread', Icons.check_circle_outline_rounded),
      ('Make shorter', Icons.short_text_rounded),
    ];
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tools.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (label, icon) = tools[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (r) =>
                      AppColors.appleIntelligenceGradient.createShader(r),
                  child: Icon(icon, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.textBodyColor)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Apple Intelligence-style smart suggestions bar that appears after
/// the AI finishes a reply.
class _SmartSuggestionsBar extends StatelessWidget {
  final BuildContext context;
  final void Function(_SmartSuggestion) onTap;
  const _SmartSuggestionsBar({required this.context, required this.onTap});

  @override
  Widget build(BuildContext parentCtx) {
    final suggestions = const [
      _SmartSuggestion(
        'Get a summary of this thread',
        'Save 2 min',
        Icons.summarize_rounded,
      ),
      _SmartSuggestion(
        'Translate to 中文',
        'Multilingual',
        Icons.translate_rounded,
      ),
      _SmartSuggestion(
        'Connect me to a human',
        'Switch modes',
        Icons.support_agent_rounded,
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppleIntelligenceGlow(
                  size: 18, active: true, child: Container()),
              const SizedBox(width: 6),
              Text('Suggested for you',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: context.textMutedColor)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = suggestions[i];
                return PressScale(
                  onTap: () => onTap(s),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient:
                                AppColors.appleIntelligenceGradient,
                          ),
                          child: Icon(s.icon,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.textColor)),
                              Text(s.detail,
                                  style: TextStyle(
                                      fontSize: 10.5,
                                      color: context.textMutedColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatHeader extends ConsumerWidget {
  final _ChatMode mode;
  final bool agentOnline;
  final bool agentTyping;
  final String agentName;
  const _ChatHeader({
    required this.mode,
    required this.agentOnline,
    required this.agentTyping,
    required this.agentName,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAi = mode == _ChatMode.ai;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.portalDashboard),
          ),
          if (isAi)
            AppleIntelligenceGlow(
              size: 40,
              active: true,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.appleIntelligenceGradient,
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 20),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                ),
              ),
              child: const AirpakAvatar(size: 32),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isAi ? 'AI Assistant' : 'AirPak Support',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.textColor),
                ),
                Row(
                  children: [
                    if (isAi) ...[
                      AppleIntelligenceGlow(
                          size: 8, active: true, child: Container()),
                    ] else if (agentOnline) ...[
                      const PulseDot(color: AppColors.success, size: 7),
                    ] else ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: context.textSubtleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    Text(
                      isAi
                          ? 'Powered by ${AppEnv.supportAiModel}'
                          : agentTyping
                              ? '${agentName.isEmpty ? 'AirPak Support' : agentName} is typing…'
                              : agentOnline
                                  ? 'Live · ${agentName.isEmpty ? 'AirPak Support' : agentName} online'
                                  : 'Online · avg reply 2 min',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: context.textMutedColor,
                          fontStyle: agentTyping
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontWeight: agentOnline
                              ? FontWeight.w700
                              : FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (AppEnv.enableSupportAi)
            IconButton(
              icon: Icon(
                isAi
                    ? Icons.support_agent_rounded
                    : Icons.auto_awesome_rounded,
                color: isAi
                    ? null
                    : const Color(0xFFA29BFE),
              ),
              tooltip:
                  isAi ? 'Switch to human agent' : 'Switch to AI assistant',
              onPressed: () {
                ref.read(_chatModeProvider.notifier).state =
                    isAi ? _ChatMode.human : _ChatMode.ai;
              },
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<String> onChange;
  final bool sending;
  final bool isAi;
  final String hint;
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onChange,
    required this.sending,
    required this.isAi,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: context.surfaceColor.withValues(alpha: 0.85),
            border: Border(top: BorderSide(color: context.dividerColor)),
          ),
          padding: EdgeInsets.fromLTRB(
              8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAi)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.surfaceMutedColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      AppleIntelligenceGlow(
                          size: 14,
                          active: true,
                          child: Container(
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors
                                    .appleIntelligenceGradient),
                          )),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'AI responses are generated. Verify important details with a human agent.',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: context.textMutedColor),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    padding: const EdgeInsets.all(8),
                    icon: Icon(Icons.add_rounded,
                        color: isAi
                            ? const Color(0xFFA29BFE)
                            : AppColors.brand),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Attachment picker (mock)')),
                      );
                    },
                  ),
                  // Push-to-talk: tap-and-hold to record voice.
                  const _PushToTalkButton(),
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      decoration: BoxDecoration(
                        color: context.surfaceMutedColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.borderColor),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onChanged: onChange,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                              color: context.textSubtleColor, fontSize: 15),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: TextStyle(
                            fontSize: 15, color: context.textColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedContainer(
                    duration: MotionDurations.short,
                    child: sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: AppColors.brand),
                            ),
                          )
                        : IconButton(
                            onPressed: onSend,
                            icon: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: isAi
                                    ? AppColors.appleIntelligenceGradient
                                    : AppColors.brandGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAi
                                            ? const Color(0xFFA29BFE)
                                            : AppColors.brand)
                                        .withValues(alpha: 0.30),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingPulse extends StatefulWidget {
  final String prompt;
  const _TypingPulse({required this.prompt});
  @override
  State<_TypingPulse> createState() => _TypingPulseState();
}

class _TypingPulseState extends State<_TypingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceMutedColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.borderColor),
      ),
      child: Row(
        children: [
          AppleIntelligenceGlow(
            size: 14,
            active: true,
            child: Container(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final phrases = [
                  'Reading your message…',
                  'Looking up your latest shipment…',
                  'Drafting a helpful reply…',
                ];
                final i = (_c.value * phrases.length).floor() % phrases.length;
                return Text(
                  phrases[i],
                  style: TextStyle(
                      fontSize: 12,
                      color: context.textMutedColor,
                      fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  const _Bubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isMine = !msg.fromAgent;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.brand
              : context.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 20 : 6),
            bottomRight: Radius.circular(isMine ? 6 : 20),
          ),
          border: Border.all(
            color: isMine ? AppColors.brand : context.borderColor,
          ),
          boxShadow: isMine ? AppElevation.sm : context.cardShadow,
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: TextStyle(
                color: isMine ? Colors.white : context.textColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('h:mm a').format(msg.sentAt),
              style: TextStyle(
                color: isMine
                    ? Colors.white70
                    : context.textMutedColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final AiMessage msg;
  const _AiBubble({required this.msg});
  @override
  Widget build(BuildContext context) {
    final isUser = msg.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: isUser ? AppColors.brand : context.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          border: Border.all(
            color: isUser ? AppColors.brand : context.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Container(
                margin: const EdgeInsets.only(right: 8, top: 2),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 14, color: Color(0xFFA29BFE)),
              ),
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : context.textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(msg.sentAt),
                    style: TextStyle(
                      color: isUser
                          ? Colors.white70
                          : context.textMutedColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome_rounded,
                size: 14, color: Color(0xFFA29BFE)),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                return Row(
                  children: List.generate(3, (i) {
                    final t = ((_c.value + i * 0.3) % 1.0);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6 + 4 * t,
                      decoration: BoxDecoration(
                        color: const Color(0xFFA29BFE)
                            .withValues(alpha: 0.4 + 0.6 * t),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Push-to-talk voice button ───────────────────────────────────────────

class _PushToTalkButton extends StatefulWidget {
  const _PushToTalkButton();
  @override
  State<_PushToTalkButton> createState() => _PushToTalkButtonState();
}

class _PushToTalkButtonState extends State<_PushToTalkButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  double _elapsed = 0;

  void _onPressDown(LongPressStartDetails _) {
    setState(() {
      _pressed = true;
      _elapsed = 0;
    });
  }

  void _onPressEnd(LongPressEndDetails _) {
    final secs = _elapsed;
    setState(() {
      _pressed = false;
      _elapsed = 0;
    });
    if (secs < 0.4) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Captured ${secs.toStringAsFixed(1)}s voice note'),
          ],
        ),
        backgroundColor: AppColors.brand,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onPressDown,
      onLongPressEnd: _onPressEnd,
      onLongPressCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: MotionDurations.short,
        width: _pressed ? 110 : 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: _pressed
              ? const LinearGradient(
                  colors: [Color(0xFFFF453A), Color(0xFFFF6B61)])
              : null,
          color: _pressed ? null : context.surfaceMutedColor,
          borderRadius: BorderRadius.circular(99),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF453A).withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : null,
          border: Border.all(
              color: _pressed ? Colors.transparent : context.borderColor),
        ),
        child: Center(
          child: _pressed
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.graphic_eq_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('${_elapsed.toStringAsFixed(1)}s',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                )
              : Icon(Icons.mic_none_rounded,
                  size: 20, color: context.textColor),
        ),
      ),
    );
  }
}
