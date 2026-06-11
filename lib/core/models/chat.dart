class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;
  final bool fromAgent;
  final String? attachmentUrl;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
    required this.fromAgent,
    this.attachmentUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id']?.toString() ?? '',
        threadId: m['thread_id']?.toString() ?? '',
        senderId: m['sender_id']?.toString() ?? '',
        senderName: m['sender_name']?.toString() ?? 'Unknown',
        text: m['text']?.toString() ?? '',
        sentAt: DateTime.tryParse(m['sent_at']?.toString() ?? '') ??
            DateTime.now(),
        fromAgent: m['from_agent'] as bool? ?? false,
        attachmentUrl: m['attachment_url']?.toString(),
      );
}

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime sentAt;
  final bool read;
  final String? shipmentTracking;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.sentAt,
    required this.read,
    this.shipmentTracking,
  });

  factory NotificationItem.fromMap(Map<String, dynamic> m) => NotificationItem(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        body: m['body']?.toString() ?? '',
        sentAt: DateTime.tryParse(m['sent_at']?.toString() ?? '') ??
            DateTime.now(),
        read: m['read'] as bool? ?? false,
        shipmentTracking: m['shipment_tracking']?.toString(),
      );
}
