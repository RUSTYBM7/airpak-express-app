import 'dart:async';
import 'dart:math';

import '../models/chat.dart';
import '../models/profile.dart';
import '../models/shipment.dart';

/// In-memory data source used when no Supabase backend is configured.
/// Repository code calls into the same surface so the app looks identical
/// once real keys are dropped in.
class MockData {
  MockData._() {
    _seed();
  }

  static final MockData instance = MockData._();

  final _rng = Random(7);

  final List<AppProfile> _profiles = [];
  final List<Shipment> _shipments = [];
  final List<TrackingEvent> _events = [];
  final List<ChatMessage> _messages = [];
  final List<NotificationItem> _notifications = [];

  // ── Realistic-looking sample data (numbers, names, cities) ───────────────

  static const _cities = [
    ['Kuala Lumpur', 'Wilayah Persekutuan', '50000', 'Malaysia', 3.1390, 101.6869],
    ['Singapore', 'Central', '048619', 'Singapore', 1.3521, 103.8198],
    ['Penang', 'Pulau Pinang', '10000', 'Malaysia', 5.4164, 100.3327],
    ['Bangkok', 'Bangkok', '10110', 'Thailand', 13.7563, 100.5018],
    ['Manila', 'Metro Manila', '1000', 'Philippines', 14.5995, 120.9842],
    ['Jakarta', 'DKI Jakarta', '10110', 'Indonesia', -6.2088, 106.8456],
    ['Hong Kong', 'Central', '999077', 'Hong Kong', 22.3193, 114.1694],
    ['Tokyo', 'Shinjuku', '160-0022', 'Japan', 35.6895, 139.6917],
    ['Sydney', 'NSW', '2000', 'Australia', -33.8688, 151.2093],
    ['Dubai', 'Dubai', '00000', 'UAE', 25.2048, 55.2708],
    ['London', 'England', 'EC1A 1BB', 'United Kingdom', 51.5074, -0.1278],
    ['Los Angeles', 'CA', '90001', 'United States', 34.0522, -118.2437],
  ];

  static const _firstNames = [
    'Aaliyah', 'Ben', 'Chloe', 'Daniel', 'Evelyn', 'Farid', 'Grace',
    'Hiroshi', 'Ivy', 'Jin', 'Kavya', 'Liam', 'Mei', 'Noah', 'Olivia',
    'Putri', 'Qasim', 'Rohan', 'Sofia', 'Tariq', 'Umi', 'Victor',
    'Wen', 'Xiomara', 'Yara', 'Zane',
  ];
  static const _lastNames = [
    'Tan', 'Lim', 'Wong', 'Singh', 'Patel', 'Lee', 'Kumar',
    'Nakamura', 'Sato', 'Reyes', 'Garcia', 'Cohen', 'Ibrahim',
    'Chen', 'Wang', 'Yamada', 'Park', 'Nguyen', 'Ahmad',
  ];
  // ignore: unused_field
  static const _companies = [
    'Lumen Trading', 'Tropika Goods', 'Acanthus Co.', 'Merlion Imports',
    'Pelangi Apparel', 'Selat Logistics', 'Bayu Wholesale', 'Asiamart',
  ];

  // ── Public reads (async to match the real repository contract) ─────────

  Future<List<Shipment>> listShipments({String? userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final list = userId == null
        ? List<Shipment>.from(_shipments)
        : _shipments.where((s) => s.userId == userId).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<Shipment?> getShipmentByTracking(String tracking) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final hits = _shipments
        .where((s) => s.trackingNumber.toUpperCase() == tracking.toUpperCase())
        .toList();
    return hits.isEmpty ? null : hits.first;
  }

  Future<List<TrackingEvent>> eventsForShipment(String shipmentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final list =
        _events.where((e) => e.shipmentId == shipmentId).toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  Future<List<ChatMessage>> messagesForThread(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final list = _messages.where((m) => m.threadId == threadId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return list;
  }

  Future<List<NotificationItem>> notificationsForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return List<NotificationItem>.from(_notifications);
  }

  Future<AppProfile?> getProfile(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    try {
      return _profiles.firstWhere((p) => p.id == userId);
    } on StateError {
      return null;
    }
  }

  Future<List<AppProfile>> listProfiles() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<AppProfile>.from(_profiles);
  }

  // ── Mutations ─────────────────────────────────────────────────────────

  Future<Shipment> createShipment({
    required String userId,
    required Address origin,
    required Address destination,
    required Package package,
    required String service,
    String? reference,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    final tracking = _generateTracking();
    final price = _quotePrice(package, service, origin.country, destination.country);
    final eta = _computeEta(service, origin.country, destination.country, now);
    final shipment = Shipment(
      id: 'shp_${tracking.toLowerCase()}',
      trackingNumber: tracking,
      userId: userId,
      status: ShipmentStatus.created,
      service: service,
      origin: origin,
      destination: destination,
      package: package,
      createdAt: now,
      estimatedDelivery: eta,
      declaredValue: 0,
      currency: 'USD',
      price: price,
      reference: reference,
    );
    _shipments.add(shipment);
    _events.add(TrackingEvent(
      id: 'evt_${tracking}_create',
      shipmentId: shipment.id,
      status: ShipmentStatus.created,
      location: '${origin.city}, ${origin.country}',
      description: 'Shipment label created and awaiting pickup',
      occurredAt: now,
    ));
    return shipment;
  }

  Future<Shipment> updateShipmentStatus(String shipmentId, ShipmentStatus next) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final idx = _shipments.indexWhere((s) => s.id == shipmentId);
    if (idx < 0) throw StateError('shipment not found');
    final old = _shipments[idx];
    final updated = Shipment(
      id: old.id,
      trackingNumber: old.trackingNumber,
      userId: old.userId,
      status: next,
      service: old.service,
      origin: old.origin,
      destination: old.destination,
      package: old.package,
      createdAt: old.createdAt,
      estimatedDelivery: old.estimatedDelivery,
      deliveredAt: next == ShipmentStatus.delivered ? DateTime.now() : old.deliveredAt,
      declaredValue: old.declaredValue,
      currency: old.currency,
      price: old.price,
      labelUrl: old.labelUrl,
      invoiceUrl: old.invoiceUrl,
      reference: old.reference,
    );
    _shipments[idx] = updated;
    _events.add(TrackingEvent(
      id: 'evt_${old.trackingNumber}_${next.name}_${DateTime.now().millisecondsSinceEpoch}',
      shipmentId: old.id,
      status: next,
      location: next == ShipmentStatus.delivered
          ? '${old.destination.city}, ${old.destination.country}'
          : _randomHub(),
      description: _statusDescription(next),
      occurredAt: DateTime.now(),
    ));
    return updated;
  }

  Future<ChatMessage> postMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    required String text,
    required bool fromAgent,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final msg = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      threadId: threadId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      sentAt: DateTime.now(),
      fromAgent: fromAgent,
    );
    _messages.add(msg);
    return msg;
  }

  Future<AppProfile> upsertProfile(AppProfile p) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final idx = _profiles.indexWhere((q) => q.id == p.id);
    if (idx >= 0) {
      _profiles[idx] = p;
    } else {
      _profiles.add(p);
    }
    return p;
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  void _seed() {
    // demo customer profile
    const demo = AppProfile(
      id: 'usr_demo_customer',
      email: 'demo@airpak-express.com',
      fullName: 'Demo Customer',
      phone: '+60 12-345 6789',
      role: UserRole.customer,
      walletBalance: 248.5,
      rewardPoints: 1240,
      companyName: 'Lumen Trading',
      twoFactorEnabled: false,
    );
    const admin = AppProfile(
      id: 'usr_demo_admin',
      email: 'admin@airpak-express.com',
      fullName: 'Admin User',
      phone: '+60 3-7875 7768',
      role: UserRole.admin,
      walletBalance: 0,
      rewardPoints: 0,
      companyName: 'AirPak Express',
      twoFactorEnabled: true,
    );
    _profiles.addAll([demo, admin]);

    final now = DateTime.now();
    final services = ['Express', 'Standard', 'Sea Freight', 'Air Freight'];
    for (var i = 0; i < 12; i++) {
      final origin = _randomAddress();
      final dest = _randomAddress(exclude: origin.country);
      final pkg = Package(
        weightKg: 0.5 + _rng.nextDouble() * 12.0,
        lengthCm: (10 + _rng.nextInt(40)).toDouble(),
        widthCm: (10 + _rng.nextInt(40)).toDouble(),
        heightCm: (5 + _rng.nextInt(30)).toDouble(),
        pieces: 1 + _rng.nextInt(3),
        description: _randomItemDescription(),
      );
      final service = services[_rng.nextInt(services.length)];
      final created = now.subtract(Duration(days: _rng.nextInt(20)));
      final price = _quotePrice(pkg, service, origin.country, dest.country);
      final eta = _computeEta(service, origin.country, dest.country, created);
      final status = _randomStatus();
      final tracking = _generateTracking(seed: i);
      final id = 'shp_${tracking.toLowerCase()}';
      final shipment = Shipment(
        id: id,
        trackingNumber: tracking,
        userId: demo.id,
        status: status,
        service: service,
        origin: origin,
        destination: dest,
        package: pkg,
        createdAt: created,
        estimatedDelivery: eta,
        deliveredAt:
            status == ShipmentStatus.delivered ? eta : null,
        declaredValue: 50 + _rng.nextDouble() * 500,
        currency: 'USD',
        price: price,
        reference: _rng.nextBool() ? 'PO-${1000 + i}' : null,
      );
      _shipments.add(shipment);

      // events walking forward through the status ladder
      final ladder = _ladderFor(status);
      var when = created;
      for (final step in ladder) {
        _events.add(TrackingEvent(
          id: 'evt_${tracking}_${step.name}_${when.millisecondsSinceEpoch}',
          shipmentId: id,
          status: step,
          location: _randomHub(),
          description: _statusDescription(step),
          occurredAt: when,
        ));
        when = when.add(Duration(hours: 4 + _rng.nextInt(20)));
      }
    }

    // sample chat thread
    final firstMsg = ChatMessage(
      id: 'msg_1',
      threadId: 'thread_demo',
      senderId: demo.id,
      senderName: 'Demo Customer',
      text: 'Hi! Can you help me track shipment APK20240521001234?',
      sentAt: now.subtract(const Duration(hours: 2)),
      fromAgent: false,
    );
    final reply = ChatMessage(
      id: 'msg_2',
      threadId: 'thread_demo',
      senderId: 'agent_1',
      senderName: 'AirPak Support',
      text:
          'Of course! That shipment cleared customs this morning and is now out for delivery in Petaling Jaya. ETA today before 6pm.',
      sentAt: now.subtract(const Duration(hours: 1, minutes: 50)),
      fromAgent: true,
    );
    _messages.addAll([firstMsg, reply]);

    // sample notifications
    _notifications.addAll([
      NotificationItem(
        id: 'n1',
        title: 'Out for delivery',
        body: 'APK20240521001234 is out for delivery in Petaling Jaya',
        sentAt: now.subtract(const Duration(minutes: 30)),
        read: false,
        shipmentTracking: 'APK20240521001234',
      ),
      NotificationItem(
        id: 'n2',
        title: 'Reward points credited',
        body: 'You earned 120 points on your last shipment',
        sentAt: now.subtract(const Duration(days: 1)),
        read: true,
      ),
    ]);
  }

  String _generateTracking({int? seed}) {
    final seq = seed ?? _rng.nextInt(9000) + 1000;
    final date = DateTime.now()
        .subtract(Duration(days: _rng.nextInt(60)))
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '');
    return 'APK$date${seq.toString().padLeft(5, '0')}';
  }

  Address _randomAddress({String? exclude}) {
    var pool = _cities.where((c) => c[3] != exclude).toList();
    if (pool.isEmpty) pool = List.from(_cities);
    final c = pool[_rng.nextInt(pool.length)];
    return Address(
      name: '${_firstNames[_rng.nextInt(_firstNames.length)]} '
          '${_lastNames[_rng.nextInt(_lastNames.length)]}',
      phone: '+60 ${1 + _rng.nextInt(9)}${_rng.nextInt(10)} '
          '${_rng.nextInt(900) + 100} ${_rng.nextInt(900) + 100}',
      line1: '${10 + _rng.nextInt(200)} Jalan ${_lastNames[_rng.nextInt(_lastNames.length)]}',
      line2: _rng.nextBool() ? 'Unit ${_rng.nextInt(50) + 1}' : null,
      city: c[0] as String,
      state: c[1] as String,
      postalCode: c[2] as String,
      country: c[3] as String,
      lat: (c[4] as num).toDouble() + (_rng.nextDouble() - 0.5) * 0.2,
      lng: (c[5] as num).toDouble() + (_rng.nextDouble() - 0.5) * 0.2,
    );
  }

  String _randomHub() {
    const hubs = [
      'KUL Hub', 'PEN Hub', 'BKK Hub', 'SIN Hub', 'HKG Hub',
      'Tokyo Hub', 'Sydney Hub', 'Dubai Hub', 'LAX Hub',
    ];
    return hubs[_rng.nextInt(hubs.length)];
  }

  String _randomItemDescription() {
    const items = [
      'Apparel & accessories', 'Consumer electronics',
      'Health & beauty products', 'Books & printed material',
      'Home décor samples', 'Cosmetics', 'Sportswear',
      'Phone accessories', 'Coffee beans', 'Specialty food',
    ];
    return items[_rng.nextInt(items.length)];
  }

  double _quotePrice(Package p, String service, String oCountry, String dCountry) {
    final base = switch (service) {
      'Express' => 18.0,
      'Standard' => 9.5,
      'Air Freight' => 75.0,
      'Sea Freight' => 32.0,
      _ => 12.0,
    };
    final weightFactor = p.weightKg * 1.4;
    final sizeFactor = (p.lengthCm * p.widthCm * p.heightCm) / 5000;
    final intl = oCountry == dCountry ? 1.0 : 1.6;
    return double.parse(
        (base + weightFactor + sizeFactor * intl).toStringAsFixed(2));
  }

  DateTime _computeEta(
      String service, String oCountry, String dCountry, DateTime from) {
    final days = switch (service) {
      'Express' => (oCountry == dCountry ? 2 : 4),
      'Standard' => (oCountry == dCountry ? 4 : 8),
      'Air Freight' => 6,
      'Sea Freight' => 22,
      _ => 5,
    };
    return from.add(Duration(days: days));
  }

  ShipmentStatus _randomStatus() {
    const pool = [
      ShipmentStatus.created,
      ShipmentStatus.pickedUp,
      ShipmentStatus.inTransit,
      ShipmentStatus.outForDelivery,
      ShipmentStatus.delivered,
      ShipmentStatus.exception,
    ];
    return pool[_rng.nextInt(pool.length)];
  }

  List<ShipmentStatus> _ladderFor(ShipmentStatus current) {
    const ladder = [
      ShipmentStatus.created,
      ShipmentStatus.pickedUp,
      ShipmentStatus.inTransit,
      ShipmentStatus.outForDelivery,
      ShipmentStatus.delivered,
    ];
    final idx = ladder.indexOf(current);
    if (idx < 0) return const [ShipmentStatus.created];
    return ladder.sublist(0, idx + 1);
  }

  String _statusDescription(ShipmentStatus s) {
    switch (s) {
      case ShipmentStatus.created:
        return 'Shipment label created and awaiting pickup';
      case ShipmentStatus.pickedUp:
        return 'Picked up by courier';
      case ShipmentStatus.inTransit:
        return 'In transit to destination hub';
      case ShipmentStatus.outForDelivery:
        return 'Out for delivery — courier nearby';
      case ShipmentStatus.delivered:
        return 'Delivered — signed by recipient';
      case ShipmentStatus.exception:
        return 'Exception — action required';
      case ShipmentStatus.cancelled:
        return 'Cancelled by sender';
      case ShipmentStatus.returned:
        return 'Returned to sender';
    }
  }
}
