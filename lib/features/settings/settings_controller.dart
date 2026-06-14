import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme_provider.dart';

/// Live, persisted settings for the customer portal & admin app.
///
/// All settings are kept in a single `SettingsState` so that
/// changes broadcast to every UI that watches it (toggles
/// flip instantly, dropdowns re-render, headers update).
class SettingsState {
  // ── Notifications ───────────────────────────────────────────────
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool shipmentUpdates;
  final bool priceAlerts;
  final bool newsletter;

  // ── Security ─────────────────────────────────────────────────────
  final bool twoFactor;
  final bool faceId;
  final bool biometricPayments;
  final bool analyticsOptIn;

  // ── Appearance ───────────────────────────────────────────────────
  final AppThemeMode themeMode;
  final String accentColor; // red, orange, yellow, green, blue, purple, pink
  final String textSize;    // small, medium, large
  final bool reduceMotion;
  final bool haptics;

  // ── Connected services ───────────────────────────────────────────
  final String defaultCurrency;
  final String language;
  final String defaultCarrier;
  final bool autoPayWithCoin;

  // ── Admin-specific ───────────────────────────────────────────────
  final bool adminTelemetry;
  final bool adminSlack;
  final bool adminAiCopilot;
  final String adminTimezone;

  const SettingsState({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.shipmentUpdates = true,
    this.priceAlerts = false,
    this.newsletter = true,
    this.twoFactor = true,
    this.faceId = false,
    this.biometricPayments = false,
    this.analyticsOptIn = true,
    this.themeMode = AppThemeMode.system,
    this.accentColor = 'red',
    this.textSize = 'medium',
    this.reduceMotion = false,
    this.haptics = true,
    this.defaultCurrency = 'USD',
    this.language = 'English (US)',
    this.defaultCarrier = 'DHL Express',
    this.autoPayWithCoin = true,
    this.adminTelemetry = true,
    this.adminSlack = false,
    this.adminAiCopilot = true,
    this.adminTimezone = 'Asia/Singapore',
  });

  SettingsState copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? shipmentUpdates,
    bool? priceAlerts,
    bool? newsletter,
    bool? twoFactor,
    bool? faceId,
    bool? biometricPayments,
    bool? analyticsOptIn,
    AppThemeMode? themeMode,
    String? accentColor,
    String? textSize,
    bool? reduceMotion,
    bool? haptics,
    String? defaultCurrency,
    String? language,
    String? defaultCarrier,
    bool? autoPayWithCoin,
    bool? adminTelemetry,
    bool? adminSlack,
    bool? adminAiCopilot,
    String? adminTimezone,
  }) =>
      SettingsState(
        pushEnabled: pushEnabled ?? this.pushEnabled,
        emailEnabled: emailEnabled ?? this.emailEnabled,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        shipmentUpdates: shipmentUpdates ?? this.shipmentUpdates,
        priceAlerts: priceAlerts ?? this.priceAlerts,
        newsletter: newsletter ?? this.newsletter,
        twoFactor: twoFactor ?? this.twoFactor,
        faceId: faceId ?? this.faceId,
        biometricPayments: biometricPayments ?? this.biometricPayments,
        analyticsOptIn: analyticsOptIn ?? this.analyticsOptIn,
        themeMode: themeMode ?? this.themeMode,
        accentColor: accentColor ?? this.accentColor,
        textSize: textSize ?? this.textSize,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        haptics: haptics ?? this.haptics,
        defaultCurrency: defaultCurrency ?? this.defaultCurrency,
        language: language ?? this.language,
        defaultCarrier: defaultCarrier ?? this.defaultCarrier,
        autoPayWithCoin: autoPayWithCoin ?? this.autoPayWithCoin,
        adminTelemetry: adminTelemetry ?? this.adminTelemetry,
        adminSlack: adminSlack ?? this.adminSlack,
        adminAiCopilot: adminAiCopilot ?? this.adminAiCopilot,
        adminTimezone: adminTimezone ?? this.adminTimezone,
      );
}

/// Singleton controller. Persists all settings to local storage so
/// they survive across sessions.
class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState()) {
    _restore();
  }

  static const _kKey = 'airpak_settings_v1';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return;
      // Simple JSON-like parse: key=value;key=value
      final map = <String, String>{};
      for (final part in raw.split(';')) {
        final i = part.indexOf('=');
        if (i > 0) {
          map[part.substring(0, i)] = part.substring(i + 1);
        }
      }
      state = state.copyWith(
        pushEnabled: map['pushEnabled'] != 'false',
        emailEnabled: map['emailEnabled'] != 'false',
        smsEnabled: map['smsEnabled'] == 'true',
        shipmentUpdates: map['shipmentUpdates'] != 'false',
        priceAlerts: map['priceAlerts'] == 'true',
        newsletter: map['newsletter'] != 'false',
        twoFactor: map['twoFactor'] != 'false',
        faceId: map['faceId'] == 'true',
        biometricPayments: map['biometricPayments'] == 'true',
        analyticsOptIn: map['analyticsOptIn'] != 'false',
        themeMode: _themeFromString(map['themeMode']),
        accentColor: map['accentColor'] ?? 'red',
        textSize: map['textSize'] ?? 'medium',
        reduceMotion: map['reduceMotion'] == 'true',
        haptics: map['haptics'] != 'false',
        defaultCurrency: map['defaultCurrency'] ?? 'USD',
        language: map['language'] ?? 'English (US)',
        defaultCarrier: map['defaultCarrier'] ?? 'DHL Express',
        autoPayWithCoin: map['autoPayWithCoin'] != 'false',
        adminTelemetry: map['adminTelemetry'] != 'false',
        adminSlack: map['adminSlack'] == 'true',
        adminAiCopilot: map['adminAiCopilot'] != 'false',
        adminTimezone: map['adminTimezone'] ?? 'Asia/Singapore',
      );
    } catch (e) {
      debugPrint('Settings restore failed: $e');
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = state;
      final buf = StringBuffer();
      buf.write('pushEnabled=${s.pushEnabled};');
      buf.write('emailEnabled=${s.emailEnabled};');
      buf.write('smsEnabled=${s.smsEnabled};');
      buf.write('shipmentUpdates=${s.shipmentUpdates};');
      buf.write('priceAlerts=${s.priceAlerts};');
      buf.write('newsletter=${s.newsletter};');
      buf.write('twoFactor=${s.twoFactor};');
      buf.write('faceId=${s.faceId};');
      buf.write('biometricPayments=${s.biometricPayments};');
      buf.write('analyticsOptIn=${s.analyticsOptIn};');
      buf.write('themeMode=${_themeToString(s.themeMode)};');
      buf.write('accentColor=${s.accentColor};');
      buf.write('textSize=${s.textSize};');
      buf.write('reduceMotion=${s.reduceMotion};');
      buf.write('haptics=${s.haptics};');
      buf.write('defaultCurrency=${s.defaultCurrency};');
      buf.write('language=${s.language};');
      buf.write('defaultCarrier=${s.defaultCarrier};');
      buf.write('autoPayWithCoin=${s.autoPayWithCoin};');
      buf.write('adminTelemetry=${s.adminTelemetry};');
      buf.write('adminSlack=${s.adminSlack};');
      buf.write('adminAiCopilot=${s.adminAiCopilot};');
      buf.write('adminTimezone=${s.adminTimezone};');
      await prefs.setString(_kKey, buf.toString());
    } catch (e) {
      debugPrint('Settings persist failed: $e');
    }
  }

  void setPush(bool v) { state = state.copyWith(pushEnabled: v); _persist(); }
  void setEmail(bool v) { state = state.copyWith(emailEnabled: v); _persist(); }
  void setSms(bool v) { state = state.copyWith(smsEnabled: v); _persist(); }
  void setShipmentUpdates(bool v) { state = state.copyWith(shipmentUpdates: v); _persist(); }
  void setPriceAlerts(bool v) { state = state.copyWith(priceAlerts: v); _persist(); }
  void setNewsletter(bool v) { state = state.copyWith(newsletter: v); _persist(); }
  void set2FA(bool v) { state = state.copyWith(twoFactor: v); _persist(); }
  void setFaceId(bool v) { state = state.copyWith(faceId: v); _persist(); }
  void setBiometricPayments(bool v) { state = state.copyWith(biometricPayments: v); _persist(); }
  void setAnalytics(bool v) { state = state.copyWith(analyticsOptIn: v); _persist(); }
  void setThemeMode(AppThemeMode v) { state = state.copyWith(themeMode: v); _persist(); }
  void setAccentColor(String v) { state = state.copyWith(accentColor: v); _persist(); }
  void setTextSize(String v) { state = state.copyWith(textSize: v); _persist(); }
  void setReduceMotion(bool v) { state = state.copyWith(reduceMotion: v); _persist(); }
  void setHaptics(bool v) { state = state.copyWith(haptics: v); _persist(); }
  void setDefaultCurrency(String v) { state = state.copyWith(defaultCurrency: v); _persist(); }
  void setLanguage(String v) { state = state.copyWith(language: v); _persist(); }
  void setDefaultCarrier(String v) { state = state.copyWith(defaultCarrier: v); _persist(); }
  void setAutoPayWithCoin(bool v) { state = state.copyWith(autoPayWithCoin: v); _persist(); }
  void setAdminTelemetry(bool v) { state = state.copyWith(adminTelemetry: v); _persist(); }
  void setAdminSlack(bool v) { state = state.copyWith(adminSlack: v); _persist(); }
  void setAdminAiCopilot(bool v) { state = state.copyWith(adminAiCopilot: v); _persist(); }
  void setAdminTimezone(String v) { state = state.copyWith(adminTimezone: v); _persist(); }

  static String _themeToString(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.system: return 'system';
      case AppThemeMode.light: return 'light';
      case AppThemeMode.dark: return 'dark';
    }
  }
  static AppThemeMode _themeFromString(String? s) {
    switch (s) {
      case 'light': return AppThemeMode.light;
      case 'dark': return AppThemeMode.dark;
      default: return AppThemeMode.system;
    }
  }
}

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
        (ref) => SettingsController());
