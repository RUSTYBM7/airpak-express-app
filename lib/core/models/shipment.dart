import 'package:intl/intl.dart';

enum ShipmentStatus {
  created,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  exception,
  cancelled,
  returned;

  String get label {
    switch (this) {
      case ShipmentStatus.created:
        return 'Created';
      case ShipmentStatus.pickedUp:
        return 'Picked up';
      case ShipmentStatus.inTransit:
        return 'In transit';
      case ShipmentStatus.outForDelivery:
        return 'Out for delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.exception:
        return 'Exception';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
      case ShipmentStatus.returned:
        return 'Returned';
    }
  }

  static ShipmentStatus fromString(String? raw) {
    if (raw == null) return ShipmentStatus.created;
    final normalised = raw.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    switch (normalised) {
      case 'created':
        return ShipmentStatus.created;
      case 'pickedup':
        return ShipmentStatus.pickedUp;
      case 'intransit':
        return ShipmentStatus.inTransit;
      case 'outfordelivery':
        return ShipmentStatus.outForDelivery;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'exception':
        return ShipmentStatus.exception;
      case 'cancelled':
      case 'canceled':
        return ShipmentStatus.cancelled;
      case 'returned':
        return ShipmentStatus.returned;
      default:
        return ShipmentStatus.created;
    }
  }

  /// 0..1 progress used by the tracker timeline.
  double get progress {
    switch (this) {
      case ShipmentStatus.created:
        return 0.05;
      case ShipmentStatus.pickedUp:
        return 0.2;
      case ShipmentStatus.inTransit:
        return 0.5;
      case ShipmentStatus.outForDelivery:
        return 0.8;
      case ShipmentStatus.delivered:
        return 1.0;
      case ShipmentStatus.exception:
        return 0.5;
      case ShipmentStatus.cancelled:
        return 0.0;
      case ShipmentStatus.returned:
        return 0.5;
    }
  }
}

class Address {
  final String name;
  final String phone;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? lat;
  final double? lng;

  const Address({
    required this.name,
    required this.phone,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.lat,
    this.lng,
  });

  factory Address.fromMap(Map<String, dynamic> m) => Address(
        name: m['name']?.toString() ?? '',
        phone: m['phone']?.toString() ?? '',
        line1: m['line1']?.toString() ?? '',
        line2: m['line2']?.toString(),
        city: m['city']?.toString() ?? '',
        state: m['state']?.toString() ?? '',
        postalCode: m['postal_code']?.toString() ?? '',
        country: m['country']?.toString() ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lng: (m['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'line1': line1,
        'line2': line2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  String get oneLine {
    final parts = <String>[
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      city,
      postalCode,
      country,
    ];
    return parts.where((p) => p.isNotEmpty).join(', ');
  }
}

class Package {
  final double weightKg;
  final double lengthCm;
  final double widthCm;
  final double heightCm;
  final int pieces;
  final String? description;
  final String? contents;

  const Package({
    this.weightKg = 1.0,
    this.lengthCm = 20,
    this.widthCm = 15,
    this.heightCm = 10,
    this.pieces = 1,
    this.description,
    this.contents,
  });

  factory Package.fromMap(Map<String, dynamic> m) => Package(
        weightKg: (m['weight_kg'] as num?)?.toDouble() ?? 1.0,
        lengthCm: (m['length_cm'] as num?)?.toDouble() ?? 20,
        widthCm: (m['width_cm'] as num?)?.toDouble() ?? 15,
        heightCm: (m['height_cm'] as num?)?.toDouble() ?? 10,
        pieces: (m['pieces'] as num?)?.toInt() ?? 1,
        description: m['description']?.toString(),
        contents: m['contents']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        'weight_kg': weightKg,
        'length_cm': lengthCm,
        'width_cm': widthCm,
        'height_cm': heightCm,
        'pieces': pieces,
        if (description != null) 'description': description,
        if (contents != null) 'contents': contents,
      };
}

class Shipment {
  final String id;
  final String trackingNumber;
  final String userId;
  final ShipmentStatus status;
  final String service; // Express / Standard / Sea / Air
  final Address origin;
  final Address destination;
  final Package package;
  final DateTime createdAt;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final double declaredValue;
  final String currency;
  final double price;
  final String? labelUrl;
  final String? invoiceUrl;
  final String? reference;

  const Shipment({
    required this.id,
    required this.trackingNumber,
    required this.userId,
    required this.status,
    required this.service,
    required this.origin,
    required this.destination,
    required this.package,
    required this.createdAt,
    this.estimatedDelivery,
    this.deliveredAt,
    this.declaredValue = 0,
    this.currency = 'USD',
    this.price = 0,
    this.labelUrl,
    this.invoiceUrl,
    this.reference,
  });

  factory Shipment.fromMap(Map<String, dynamic> m) => Shipment(
        id: m['id']?.toString() ?? '',
        trackingNumber: m['tracking_number']?.toString() ?? '',
        userId: m['user_id']?.toString() ?? '',
        status: ShipmentStatus.fromString(m['status']?.toString()),
        service: m['service']?.toString() ?? 'Express',
        origin: Address.fromMap(
            (m['origin'] as Map?)?.cast<String, dynamic>() ?? const {}),
        destination: Address.fromMap(
            (m['destination'] as Map?)?.cast<String, dynamic>() ?? const {}),
        package: Package.fromMap(
            (m['package'] as Map?)?.cast<String, dynamic>() ?? const {}),
        createdAt: DateTime.tryParse(m['created_at']?.toString() ?? '') ??
            DateTime.now(),
        estimatedDelivery: DateTime.tryParse(
            m['estimated_delivery']?.toString() ?? ''),
        deliveredAt: DateTime.tryParse(m['delivered_at']?.toString() ?? ''),
        declaredValue:
            (m['declared_value'] as num?)?.toDouble() ?? 0,
        currency: m['currency']?.toString() ?? 'USD',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        labelUrl: m['label_url']?.toString(),
        invoiceUrl: m['invoice_url']?.toString(),
        reference: m['reference']?.toString(),
      );

  String get route {
    final o = origin.city.isNotEmpty ? origin.city : origin.country;
    final d = destination.city.isNotEmpty
        ? destination.city
        : destination.country;
    return '$o → $d';
  }

  String get priceFormatted {
    final f = NumberFormat.simpleCurrency(name: currency);
    return f.format(price);
  }

  String get etaFormatted {
    final dt = estimatedDelivery;
    if (dt == null) return '—';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}

class TrackingEvent {
  final String id;
  final String shipmentId;
  final ShipmentStatus status;
  final String location;
  final String? description;
  final DateTime occurredAt;

  const TrackingEvent({
    required this.id,
    required this.shipmentId,
    required this.status,
    required this.location,
    required this.occurredAt,
    this.description,
  });

  factory TrackingEvent.fromMap(Map<String, dynamic> m) => TrackingEvent(
        id: m['id']?.toString() ?? '',
        shipmentId: m['shipment_id']?.toString() ?? '',
        status: ShipmentStatus.fromString(m['status']?.toString()),
        location: m['location']?.toString() ?? '',
        description: m['description']?.toString(),
        occurredAt: DateTime.tryParse(m['occurred_at']?.toString() ?? '') ??
            DateTime.now(),
      );

  String get occurredAtFormatted =>
      DateFormat('MMM d, yyyy • h:mm a').format(occurredAt);
}
