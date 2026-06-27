import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/cupertino.dart';
import '../../../app/design_system.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../../support/support_chat_controller.dart';

/// New live chat screen — persistent, real-time, with unread badge
/// for incoming admin messages. The "human will respond" message is
/// only shown ONCE — the first time a user sends a message.
class LiveChatScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? threadId;
  const LiveChatScreen({super.key, required this.userId, this.threadId});
  @override
  ConsumerState<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends ConsumerState<LiveChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Mark thread as read on open.
    Future.microtask(() {
      ref.read(supportChatControllerProvider(widget.userId).notifier).markRead();
    });
    // Listen for new messages and auto-scroll.
    ref.listenManual<SupportChatState>(
      supportChatControllerProvider(widget.userId),
      (prev, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    HapticService.light();
    setState(() => _sending = true);
    try {
      await ref
          .read(supportChatControllerProvider(widget.userId).notifier)
          .sendUser(text);
      _ctrl.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportChatControllerProvider(widget.userId));
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(threadId: state.threadId, userId: widget.userId),
            Expanded(
              child: state.messages.isEmpty
                  ? const _EmptyState()
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: state.messages.length,
                      itemBuilder: (ctx, i) {
                        final m = state.messages[i];
                        return _Bubble(message: m);
                      },
                    ),
            ),
            _Composer(
              ctrl: _ctrl,
              sending: _sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  final String threadId;
  final String userId;
  const _Header({required this.threadId, required this.userId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportChatControllerProvider(userId));
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(bottom: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.textColor),
            onPressed: () => context.pop(),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brand, AppColors.warning]),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const AirpakMark(size: 22, fg: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AirPak Support',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textColor)),
                Row(
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text('Online · Avg. reply 2 min',
                        style: TextStyle(fontSize: 11.5, color: context.textMutedColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
          if (state.hasUnreadAgentReply)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(99),
              ),
              child: const Text('NEW',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84, height: 84,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.brand, size: 38),
          ),
          const SizedBox(height: 16),
          Text('How can we help?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.textColor, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(
            'A human agent will join within ~2 minutes. Your conversation stays in the thread — you can come back any time.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: context.textMutedColor, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});
  @override
  Widget build(BuildContext context) {
    final isMe = message.role == 'user';
    final isSystem = message.role == 'system';
    final isAi = message.role == 'ai';
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.30)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_top_rounded, size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(message.text,
                      style: const TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (isAi) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 6, 64, 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.info),
                  const SizedBox(width: 4),
                  const Text('Mavis · suggestion',
                      style: TextStyle(fontSize: 10.5, color: AppColors.info, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
                  const Spacer(),
                  Text(DateFormat('HH:mm').format(message.sentAt),
                      style: TextStyle(fontSize: 10, color: context.textMutedColor)),
                ],
              ),
              const SizedBox(height: 4),
              Text(message.text, style: TextStyle(fontSize: 13.5, color: context.textColor, height: 1.4)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 16),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
              decoration: BoxDecoration(
                color: isMe ? AppColors.brand : context.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                ),
                border: isMe ? null : Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMe ? Colors.white : context.textColor,
                        height: 1.4,
                      )),
                  const SizedBox(height: 3),
                  Text(DateFormat('HH:mm').format(message.sentAt),
                      style: TextStyle(
                          fontSize: 10,
                          color: isMe ? Colors.white.withValues(alpha: 0.7) : context.textMutedColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController ctrl;
  final bool sending;
  final Future<void> Function() onSend;
  const _Composer({required this.ctrl, required this.sending, required this.onSend});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).viewPadding.bottom + 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: context.bgColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.borderColor),
              ),
              child: TextField(
                controller: ctrl,
                minLines: 1,
                maxLines: 5,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Message AirPak Support…',
                  hintStyle: TextStyle(color: context.textMutedColor, fontSize: 14),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: context.textColor, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: sending ? null : onSend,
              child: Container(
                width: 44, height: 44,
                alignment: Alignment.center,
                child: sending
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
