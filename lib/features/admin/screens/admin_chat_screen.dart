import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/chat.dart';
import '../../../core/models/presence.dart';
import '../../../core/services/live_bridge.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

final _threadsProvider = FutureProvider.autoDispose
    .family<RepoResult<List<ChatMessage>>, String>((ref, threadId) async {
  final repo = ref.watch(shipmentRepoProvider);
  return repo.messages(threadId);
});

/// Tracks the active online user list received from the live bridge.
class AdminPresenceNotifier extends StateNotifier<List<PresencePeer>> {
  AdminPresenceNotifier() : super(const []);
  void replace(List<PresencePeer> peers) {
    state = peers.where((p) => p.role == 'user').toList();
  }
}

final adminPresenceProvider =
    StateNotifierProvider<AdminPresenceNotifier, List<PresencePeer>>(
  (ref) => AdminPresenceNotifier(),
);

class AdminChatScreen extends ConsumerStatefulWidget {
  const AdminChatScreen({super.key});
  @override
  ConsumerState<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends ConsumerState<AdminChatScreen> {
  String _activeThread = 'thread_demo';
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _local = [];
  bool _sending = false;
  late final LiveBridgeClient _bridge;
  StreamSubscription<LiveEvent>? _bridgeSub;

  @override
  void initState() {
    super.initState();
    _bridge = LiveBridgeClient(
      baseUrl: 'http://localhost:3001',
      token: 'dev:agent_1',
      userId: 'agent_1',
      displayName: 'Agent Bob',
      role: 'admin',
      room: _activeThread,
    );
    _bridge.connect();
    _bridgeSub = _bridge.events.listen(_onBridge);
  }

  @override
  void dispose() {
    _bridgeSub?.cancel();
    _bridge.dispose();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onBridge(LiveEvent ev) {
    if (ev.rawType == 'admin-presence-snapshot') {
      final users = (ev.payload['users'] as List?) ?? const [];
      final peers = <PresencePeer>[];
      for (final m in users.whereType<Map>()) {
        peers.add(PresencePeer(
          userId: (m['userId'] as String?) ?? '?',
          name: (m['name'] as String?) ?? (m['userId'] as String?) ?? '?',
          role: (m['role'] as String?) ?? 'user',
          online: (m['online'] as bool?) ?? true,
          room: m['room'] as String?,
        ));
      }
      ref.read(adminPresenceProvider.notifier).replace(peers);
    }
  }

  void _switchThread(String t) {
    setState(() => _activeThread = t);
    _bridge.switchRoom(t);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final res = await ref.read(shipmentRepoProvider).postMessage(
          threadId: _activeThread,
          senderId: 'agent_1',
          senderName: 'You (Agent)',
          text: text,
          fromAgent: true,
        );
    if (res.data != null) {
      _local.add(res.data!);
      _ctrl.clear();
      // Broadcast the agent reply to the user over the bridge.
      _bridge.sendChat(res.data!.text);
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_threadsProvider(_activeThread));
    final auth = ref.watch(authControllerProvider);
    final presence = ref.watch(adminPresenceProvider);
    final threads = const [
      ('thread_demo', 'Demo Customer', 'shipnow.apk'),
      ('thread_acme', 'Acme Imports', 'acme.apk'),
      ('thread_lumen', 'Lumen Trading', 'lumen.apk'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 240,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader('Threads'),
                const SizedBox(height: 8),
                for (final t in threads)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: _activeThread == t.$1
                          ? AppColors.brandLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _activeThread == t.$1
                              ? AppColors.brand
                              : AppColors.border),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brandLight,
                        child: Text(
                          t.$2.substring(0, 1),
                          style: const TextStyle(
                              color: AppColors.brand,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      title: Text(t.$2,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      subtitle: Text('Order ${t.$3}',
                          style: const TextStyle(fontSize: 11)),
                      onTap: () => _switchThread(t.$1),
                    ),
                  ),
                const SizedBox(height: 18),
                _OnlineUsersPanel(presence: presence),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.brandLight,
                          child: Icon(Icons.person, color: AppColors.brand),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_activeThread == 'thread_demo'
                                  ? 'Demo Customer'
                                  : 'Customer'),
                              Text('Active chat',
                                  style: TextStyle(
                                      color: context.textMutedColor,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        _BridgeStatusDot(),
                        const SizedBox(width: 8),
                        Text('Replying as ${auth.profile?.displayName ?? 'agent'}',
                            style: TextStyle(
                                color: context.textMutedColor, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: async.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.brand)),
                      error: (e, _) => ErrorStateView(error: e),
                      data: (res) {
                        final list = [...?res.data, ..._local];
                        return ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(12),
                          itemCount: list.length,
                          itemBuilder: (_, i) => _bubble(context, list[i]),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    decoration: const BoxDecoration(
                      border: Border(
                          top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            decoration: const InputDecoration(
                              hintText: 'Reply to customer…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        IconButton(
                          onPressed: _sending ? null : _send,
                          icon: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brand),
                                )
                              : const Icon(Icons.send,
                                  color: AppColors.brand),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage msg) {
    final isAgent = msg.fromAgent;
    return Align(
      alignment: isAgent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
        decoration: BoxDecoration(
          color: isAgent ? AppColors.brand : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isAgent ? 12 : 2),
            bottomRight: Radius.circular(isAgent ? 2 : 12),
          ),
          border: Border.all(
              color: isAgent ? AppColors.brand : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              isAgent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(msg.text,
                style: TextStyle(
                    color: isAgent ? Colors.white : AppColors.text)),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a').format(msg.sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isAgent ? Colors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Online users panel ─────────────────────────────────────────────

class _OnlineUsersPanel extends StatelessWidget {
  final List<PresencePeer> presence;
  const _OnlineUsersPanel({required this.presence});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.brand, size: 14),
              const SizedBox(width: 6),
              Text('Online now',
                  style: TextStyle(
                      color: context.textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('${presence.length}',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (presence.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('No one online yet — share a session link.',
                  style: TextStyle(
                      color: context.textMutedColor, fontSize: 11)),
            )
          else
            for (final p in presence)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.brandLight,
                          child: Text(
                            p.name.isNotEmpty
                                ? p.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppColors.brand,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: p.online
                                  ? AppColors.success
                                  : AppColors.textSubtle,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: context.surfaceColor, width: 1.4),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                  color: context.textColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (p.room != null)
                            Text('in ${p.room}',
                                style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 9.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _BridgeStatusDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Live bridge connected',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.success.withValues(alpha: 0.6),
                blurRadius: 6,
                spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}
