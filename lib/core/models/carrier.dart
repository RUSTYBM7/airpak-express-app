import 'package:flutter/material.dart';

/// Worldwide shipping carrier — pre-aggregated so the customer picks
/// from the same brands they see in the real world.
///
/// IMPORTANT: AirPak itself is NOT in this list. AirPak is the
/// **platform** — the routing engine that ships through these carriers.
/// Customers choose the carrier they want AirPak to dispatch via.
class Carrier {
  final String id;
  final String name;
  final String tagline;
  final String country;
  final String currencyCode;
  final String flag;
  final Color brandColor;
  final IconData icon;
  final double rating;
  final String eta;
  final bool supportsTracking;
  final bool supportsAir;
  final bool supportsSea;
  final bool supportsExpress;

  /// Bundled logo asset path (e.g. "assets/carriers/dhl.svg") if we
  /// have the official mark, otherwise null and the widget falls back
  /// to a styled brand-letter.
  final String? logoAsset;

  const Carrier({
    required this.id,
    required this.name,
    required this.tagline,
    required this.country,
    required this.currencyCode,
    required this.flag,
    required this.brandColor,
    required this.icon,
    required this.rating,
    required this.eta,
    this.logoAsset,
    this.supportsTracking = true,
    this.supportsAir = true,
    this.supportsSea = true,
    this.supportsExpress = true,
  });
}

/// Real carrier directory that AirPak routes through. We bundle
/// official SVGs for the brands that publish them (DHL, FedEx, UPS,
/// USPS, DPD, Glovo). For the rest we draw a styled brand-letter mark
/// using the official brand colour — the widget handles both cases
/// automatically.
///
/// Geographic note: this is a **global** routing list — we do NOT
/// bias toward any single country. Customers anywhere can dispatch
/// through any of these partners.
const List<Carrier> kWorldwideCarriers = [
  Carrier(
    id: 'dhl',
    name: 'DHL',
    tagline: 'Global logistics leader',
    country: 'DE',
    currencyCode: 'EUR',
    flag: '🇩🇪',
    brandColor: Color(0xFFFFCC00),
    icon: Icons.flight_takeoff_rounded,
    rating: 4.7,
    eta: '2–5 days',
    logoAsset: 'assets/carriers/dhl.svg',
  ),
  Carrier(
    id: 'fedex',
    name: 'FedEx',
    tagline: 'Express worldwide',
    country: 'US',
    currencyCode: 'USD',
    flag: '🇺🇸',
    brandColor: Color(0xFF4D148C),
    icon: Icons.bolt_rounded,
    rating: 4.6,
    eta: '2–5 days',
    logoAsset: 'assets/carriers/fedex.svg',
  ),
  Carrier(
    id: 'ups',
    name: 'UPS',
    tagline: 'Brown is moving the world',
    country: 'US',
    currencyCode: 'USD',
    flag: '🇺🇸',
    brandColor: Color(0xFF351C15),
    icon: Icons.inventory_2_rounded,
    rating: 4.5,
    eta: '3–6 days',
    logoAsset: 'assets/carriers/ups.svg',
  ),
  Carrier(
    id: 'usps',
    name: 'USPS',
    tagline: 'Every door, every day',
    country: 'US',
    currencyCode: 'USD',
    flag: '🇺🇸',
    brandColor: Color(0xFF004B87),
    icon: Icons.markunread_mailbox_rounded,
    rating: 4.2,
    eta: '5–10 days',
    logoAsset: 'assets/carriers/usps.svg',
  ),
  Carrier(
    id: 'royal',
    name: 'Royal Mail',
    tagline: 'Trusted across the UK',
    country: 'GB',
    currencyCode: 'GBP',
    flag: '🇬🇧',
    brandColor: Color(0xFFCF0A2C),
    icon: Icons.mail_rounded,
    rating: 4.3,
    eta: '4–8 days',
    logoAsset: 'assets/carriers/royal_mail.svg',
  ),
  Carrier(
    id: 'aramex',
    name: 'Aramex',
    tagline: 'Middle East & beyond',
    country: 'AE',
    currencyCode: 'AED',
    flag: '🇦🇪',
    brandColor: Color(0xFFE4002B),
    icon: Icons.flight_rounded,
    rating: 4.4,
    eta: '2–6 days',
    logoAsset: 'assets/carriers/aramex.svg',
  ),
  Carrier(
    id: 'jnt',
    name: 'J&T Express',
    tagline: 'Express ASEAN coverage',
    country: 'ID',
    currencyCode: 'IDR',
    flag: '🇮🇩',
    brandColor: Color(0xFFE60012),
    icon: Icons.departure_board_rounded,
    rating: 4.4,
    eta: '2–5 days',
    logoAsset: 'assets/carriers/jt_express.svg',
  ),
  Carrier(
    id: 'sf',
    name: 'SF Express',
    tagline: 'China-wide next-day',
    country: 'CN',
    currencyCode: 'CNY',
    flag: '🇨🇳',
    brandColor: Color(0xFF0066B3),
    icon: Icons.directions_boat_rounded,
    rating: 4.6,
    eta: '2–5 days',
    logoAsset: 'assets/carriers/sf_express.svg',
  ),
  Carrier(
    id: 'ems',
    name: 'EMS',
    tagline: 'Universal postal network',
    country: 'JP',
    currencyCode: 'JPY',
    flag: '🇯🇵',
    brandColor: Color(0xFF003D7A),
    icon: Icons.public_rounded,
    rating: 4.1,
    eta: '5–12 days',
    logoAsset: 'assets/carriers/ems.svg',
  ),
  Carrier(
    id: 'dpd',
    name: 'DPD',
    tagline: 'Europe parcel network',
    country: 'FR',
    currencyCode: 'EUR',
    flag: '🇫🇷',
    brandColor: Color(0xFFDC0032),
    icon: Icons.directions_car_rounded,
    rating: 4.3,
    eta: '3–7 days',
    logoAsset: 'assets/carriers/dpd.svg',
  ),
  Carrier(
    id: 'auspost',
    name: 'Australia Post',
    tagline: 'All addresses, Australia',
    country: 'AU',
    currencyCode: 'AUD',
    flag: '🇦🇺',
    brandColor: Color(0xFFE1141A),
    icon: Icons.local_post_office_rounded,
    rating: 4.2,
    eta: '5–10 days',
    logoAsset: 'assets/carriers/australia_post.svg',
  ),
  Carrier(
    id: 'canada',
    name: 'Canada Post',
    tagline: 'From coast to coast',
    country: 'CA',
    currencyCode: 'CAD',
    flag: '🇨🇦',
    brandColor: Color(0xFFFE1717),
    icon: Icons.map_rounded,
    rating: 4.1,
    eta: '5–12 days',
    logoAsset: 'assets/carriers/canada_post.svg',
  ),
  Carrier(
    id: 'yodel',
    name: 'Yodel',
    tagline: 'UK doorstep specialist',
    country: 'GB',
    currencyCode: 'GBP',
    flag: '🇬🇧',
    brandColor: Color(0xFFFFB81C),
    icon: Icons.warehouse_rounded,
    rating: 3.9,
    eta: '3–7 days',
    logoAsset: 'assets/carriers/yodel.svg',
  ),
  Carrier(
    id: 'glovo',
    name: 'Glovo',
    tagline: 'Same-city courier',
    country: 'ES',
    currencyCode: 'EUR',
    flag: '🇪🇸',
    brandColor: Color(0xFF00A082),
    icon: Icons.delivery_dining_rounded,
    rating: 4.0,
    eta: '< 24 hours',
    supportsAir: false,
    supportsSea: false,
    logoAsset: 'assets/carriers/glovo.svg',
  ),
];

Carrier findCarrier(String id) =>
    kWorldwideCarriers.firstWhere((c) => c.id == id,
        orElse: () => kWorldwideCarriers.first);

/// A short curated list of the most-booked carriers for quick picks.
const List<Carrier> kFeaturedCarriers = [
  /* filled at runtime from kWorldwideCarriers */
];
