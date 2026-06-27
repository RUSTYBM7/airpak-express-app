import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final String? actionRoute;
  final String? iconName;
  final bool isRead;
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    this.actionRoute,
    this.iconName,
    this.isRead = false,
  });
  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        sentAt: sentAt,
        actionRoute: actionRoute,
        iconName: iconName,
        isRead: isRead ?? this.isRead,
      );
}

/// In-memory notification center. The user-side support chat controller
/// surfaces a notification whenever an admin agent replies. The admin
/// can also push broadcast notifications (e.g. "Shipment delayed").
class NotificationCenter extends StateNotifier<List<AppNotification>> {
  NotificationCenter() : super(const []);

  // ignore: invalid_override_of_non_virtual_member
  Stream<List<AppNotification>> get stream async* {
    yield state;
  }

  void add({
    required String title,
    required String body,
    String? actionRoute,
    String? iconName,
  }) {
    final n = AppNotification(
      id: 'n_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      sentAt: DateTime.now(),
      actionRoute: actionRoute,
      iconName: iconName,
    );
    state = [n, ...state];
  }

  void markRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllRead() {
    state = [for (final n in state) n.copyWith(isRead: true)];
  }

  void clear() {
    state = const [];
  }

  int get unread => state.where((n) => !n.isRead).length;
}

final notificationCenterProvider =
    StateNotifierProvider<NotificationCenter, List<AppNotification>>((ref) {
  return NotificationCenter();
});

/// Bridge: when the user-side chat controller gets a new agent message,
/// push a notification. This is hooked in the chat screen's build via ref.listen.
void pushChatNotification(
  WidgetRef ref, {
  required String threadId,
  required String fromUserId,
  required String messageText,
}) {
  ref.read(notificationCenterProvider.notifier).add(
        title: 'New message from AirPak Support',
        body: messageText.length > 80
            ? '${messageText.substring(0, 80)}…'
            : messageText,
        actionRoute: '/portal/chat/$fromUserId',
        iconName: 'support_agent',
      );
}
