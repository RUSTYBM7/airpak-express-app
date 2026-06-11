/// A peer observed via the live bridge.
class PresencePeer {
  final String userId;
  final String name;
  final String role;
  final bool online;
  final String? room;
  const PresencePeer({
    required this.userId,
    required this.name,
    required this.role,
    this.online = true,
    this.room,
  });
}
