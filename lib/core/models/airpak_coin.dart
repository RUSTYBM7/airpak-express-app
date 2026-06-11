import 'package:flutter/material.dart';

/// Airpak Coin — the brand-native settlement token for the app.
/// Pegged 1:1 to USD, and billed 1:1 against any fiat currency
/// the user selects. Not a crypto, not a withdrawal instrument —
/// strictly Buy / Deposit / Pay.
class AirpakCoin {
  /// The settlement unit. The user sees their preferred fiat
  /// (e.g. USD 248.50) but the app always settles in APC.
  static const String symbol = 'APC';
  static const String ticker = 'APC';
  static const String fullName = 'Airpak Coin';
  static const String tagline = 'Brand-native settlement · 1:1 USD peg';
  static const String taglineSub = 'Buy · Deposit · Pay · No withdrawal';

  /// Brand gradient.
  static const Gradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0052FF), Color(0xFF1E40AF), Color(0xFF3B82F6)],
    stops: [0.0, 0.6, 1.0],
  );

  /// Sparkline accent for charts.
  static const Color spark = Color(0xFF0052FF);
}

/// Supported fiat display currencies. The user can switch in the
/// payments screen; the wallet balance is always 1 USD = 1 APC,
/// so the displayed value mirrors the local currency 1:1.
class FiatCurrency {
  final String code;
  final String symbol;
  final String flag;
  final String name;
  final String locale;
  const FiatCurrency({
    required this.code,
    required this.symbol,
    required this.flag,
    required this.name,
    required this.locale,
  });
}

const List<FiatCurrency> kFiatCurrencies = [
  FiatCurrency(code: 'USD', symbol: r'$', flag: '🇺🇸', name: 'US Dollar', locale: 'en_US'),
  FiatCurrency(code: 'EUR', symbol: '€', flag: '🇪🇺', name: 'Euro', locale: 'de_DE'),
  FiatCurrency(code: 'GBP', symbol: '£', flag: '🇬🇧', name: 'British Pound', locale: 'en_GB'),
  FiatCurrency(code: 'MYR', symbol: 'RM', flag: '🇲🇾', name: 'Malaysian Ringgit', locale: 'ms_MY'),
  FiatCurrency(code: 'SGD', symbol: r'S$', flag: '🇸🇬', name: 'Singapore Dollar', locale: 'en_SG'),
  FiatCurrency(code: 'AED', symbol: 'AED ', flag: '🇦🇪', name: 'UAE Dirham', locale: 'ar_AE'),
  FiatCurrency(code: 'IDR', symbol: 'Rp', flag: '🇮🇩', name: 'Indonesian Rupiah', locale: 'id_ID'),
  FiatCurrency(code: 'JPY', symbol: '¥', flag: '🇯🇵', name: 'Japanese Yen', locale: 'ja_JP'),
  FiatCurrency(code: 'CNY', symbol: '¥', flag: '🇨🇳', name: 'Chinese Yuan', locale: 'zh_CN'),
  FiatCurrency(code: 'AUD', symbol: r'A$', flag: '🇦🇺', name: 'Australian Dollar', locale: 'en_AU'),
  FiatCurrency(code: 'CAD', symbol: r'C$', flag: '🇨🇦', name: 'Canadian Dollar', locale: 'en_CA'),
  FiatCurrency(code: 'INR', symbol: '₹', flag: '🇮🇳', name: 'Indian Rupee', locale: 'en_IN'),
  FiatCurrency(code: 'PHP', symbol: '₱', flag: '🇵🇭', name: 'Philippine Peso', locale: 'en_PH'),
  FiatCurrency(code: 'VND', symbol: '₫', flag: '🇻🇳', name: 'Vietnamese Dong', locale: 'vi_VN'),
  FiatCurrency(code: 'THB', symbol: '฿', flag: '🇹🇭', name: 'Thai Baht', locale: 'th_TH'),
];

FiatCurrency findCurrency(String code) =>
    kFiatCurrencies.firstWhere((c) => c.code == code,
        orElse: () => kFiatCurrencies.first);

/// Convert APC ↔ fiat at the 1:1 peg.
double apcToFiat(double apc, FiatCurrency cur) => apc;
double fiatToApc(double fiat, FiatCurrency cur) => fiat;

/// Format a fiat number with the currency's locale.
String formatFiat(double amount, FiatCurrency cur) {
  // Simple in-house formatting — keeps things deterministic without
  // shipping the intl package's heavy lookup tables.
  final isBig = cur.code == 'IDR' || cur.code == 'VND' || cur.code == 'JPY';
  final isSmall = cur.code == 'JPY' || cur.code == 'VND';
  final fixed = isSmall ? 0 : 2;
  final s = amount.toStringAsFixed(fixed);
  // Group thousands
  final parts = s.split('.');
  final intPart = parts[0];
  final grouped = intPart.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
  final withFraction = parts.length > 1 ? '.$parts[1]' : '';
  final prefix = isBig ? cur.symbol : cur.symbol;
  return '$prefix$grouped$withFraction';
}
