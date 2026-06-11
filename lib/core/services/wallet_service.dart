import 'dart:convert';
import 'dart:io' show File, Platform;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:url_launcher/url_launcher.dart';

import '../config/env.dart';
import '../models/shipment.dart';

/// Apple Wallet integration.
///
/// Production flow:
///   1. App POSTs the shipment to your backend:
///        POST {WALLET_BACKEND_URL}/v1/wallet/passes
///        body: { passTypeIdentifier, teamIdentifier, shipment, ... }
///   2. Backend signs the pass with your Apple pass type certificate
///      (P12 + WWDR), zips it, returns the bytes of `shipment.pkpass`.
///   3. The app writes the bytes to a temp file and opens them — iOS
///      automatically launches the add-to-Wallet sheet for `.pkpass`
///      files.
///
/// If [AppEnv.walletBackendUrl] is empty we build an *unsigned* pass
/// in-app. Apple will reject unsigned passes on real devices, but the
/// bundle structure is correct (manifest.json, pass.json, icon) and
/// the rest of the flow is wired up — useful for staging / Android.
class WalletService {
  WalletService._();
  static final WalletService instance = WalletService._();

  bool get isAvailable {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool get isLive => AppEnv.walletBackendUrl.isNotEmpty;

  /// Probes the native side for Wallet support. On iOS this is
  /// `true`; on Android / web it returns `false`. We use this to
  /// decide whether to show the "Add to Wallet" CTA.
  Future<bool> nativeIsAvailable() async {
    if (!isAvailable) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isAvailable');
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> nativeIsInstalled(String serial) async {
    if (!isAvailable) return false;
    try {
      final res = await _channel.invokeMethod<bool>('isPassInstalled', {
        'serial': serial,
      });
      return res ?? false;
    } on PlatformException {
      return false;
    }
  }

  static const _channel = MethodChannel('shipnow/wallet');

  /// Build a signed/unsigned pkpass and trigger the iOS add-to-Wallet
  /// flow. Returns `true` if the OS accepted the file.
  Future<bool> presentForShipment(Shipment s) async {
    if (!isAvailable) return false;
    final bytes = await buildPass(s);
    return present(bytes, s.trackingNumber);
  }

  Future<Uint8List> buildPass(Shipment s) async {
    if (isLive) return _fetchFromBackend(s);
    return _buildClientSide(s);
  }

  Future<bool> present(Uint8List pkpass, String serial) async {
    if (!isAvailable) return false;
    // Try the native PKAddPassesViewController first — gives the
    // polished sheet with the Add / Cancel buttons.
    try {
      final ok = await _channel.invokeMethod<bool>('addPass', {
        'pkpassBase64': base64Encode(pkpass),
        'serial': serial,
      });
      if (ok == true) return true;
    } on PlatformException {
      // fall through to the file-launch fallback
    } catch (_) {
      // fall through
    }
    // Fallback — write to temp dir, then ask the OS to open it. iOS
    // still maps the .pkpass extension to the Wallet app, but this
    // path is shared with the Android FileProvider flow.
    try {
      final dir = await pp.getTemporaryDirectory();
      final file = File('${dir.path}/$serial.pkpass');
      await file.writeAsBytes(pkpass, flush: true);
      final ok = await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
      return ok;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Wallet present failed: $e');
      }
      return false;
    }
  }

  // ── Backend fetch (production) ────────────────────────────────────────
  Future<Uint8List> _fetchFromBackend(Shipment s) async {
    final res = await http.post(
      Uri.parse('${AppEnv.walletBackendUrl}/v1/wallet/passes'),
      headers: const {'Content-Type': 'application/json'},
      body: _serialiseForBackend(s),
    );
    if (res.statusCode != 200) {
      throw Exception('Wallet backend error: ${res.statusCode}');
    }
    return res.bodyBytes;
  }

  String _serialiseForBackend(Shipment s) {
    return '''
{
  "passTypeIdentifier": "${AppEnv.walletPassTypeId}",
  "teamIdentifier": "${AppEnv.walletTeamId}",
  "serialNumber": "${s.trackingNumber}",
  "organizationName": "AirPak Express",
  "description": "Shipment ${s.trackingNumber}",
  "logoText": "ShipNow",
  "foregroundColor": "rgb(255, 255, 255)",
  "backgroundColor": "rgb(220, 38, 38)",
  "labelColor": "rgb(255, 255, 255)",
  "formatVersion": 1,
  "generic": {
    "primaryFields": [
      { "key": "tracking", "label": "TRACKING", "value": "${s.trackingNumber}" }
    ],
    "secondaryFields": [
      { "key": "route", "label": "ROUTE", "value": "${s.origin.city} → ${s.destination.city}" }
    ],
    "auxiliaryFields": [
      { "key": "service", "label": "SERVICE", "value": "${s.service}" },
      { "key": "eta", "label": "ETA", "value": "${s.etaFormatted}" }
    ],
    "backFields": [
      { "key": "origin", "label": "Origin", "value": "${_esc(s.origin.oneLine)}" },
      { "key": "destination", "label": "Destination", "value": "${_esc(s.destination.oneLine)}" },
      { "key": "status", "label": "Status", "value": "${s.status.label}" }
    ]
  },
  "barcodes": [
    { "format": "PKBarcodeFormatQR", "message": "${s.trackingNumber}", "messageEncoding": "iso-8859-1" }
  ]
}
''';
  }

  String _esc(String v) =>
      v.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', ' ');

  // ── Client-side builder (dev fallback) ────────────────────────────────
  Future<Uint8List> _buildClientSide(Shipment s) async {
    final passJson = _passJson(s);
    final jsonBytes = Uint8List.fromList(passJson.codeUnits);
    final iconBytes = _placeholderPng();
    final manifest = _buildManifest([
      MapEntry('pass.json', jsonBytes),
      MapEntry('icon.png', iconBytes),
    ]);
    final manifestBytes = Uint8List.fromList(manifest.codeUnits);

    final archive = Archive()
      ..addFile(ArchiveFile('pass.json', jsonBytes.length, jsonBytes))
      ..addFile(ArchiveFile('icon.png', iconBytes.length, iconBytes))
      ..addFile(
          ArchiveFile('manifest.json', manifestBytes.length, manifestBytes));
    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded ?? const <int>[]);
  }

  String _passJson(Shipment s) {
    return '''
{
  "formatVersion": 1,
  "passTypeIdentifier": "${AppEnv.walletPassTypeId}",
  "serialNumber": "${s.trackingNumber}",
  "teamIdentifier": "${AppEnv.walletTeamId.isEmpty ? 'TEAMID0000' : AppEnv.walletTeamId}",
  "organizationName": "AirPak Express",
  "description": "Shipment ${s.trackingNumber}",
  "logoText": "ShipNow",
  "foregroundColor": "rgb(255, 255, 255)",
  "backgroundColor": "rgb(220, 38, 38)",
  "labelColor": "rgb(255, 255, 255)",
  "generic": {
    "primaryFields": [
      { "key": "tracking", "label": "TRACKING", "value": "${s.trackingNumber}" }
    ],
    "secondaryFields": [
      { "key": "route", "label": "ROUTE", "value": "${s.origin.city} → ${s.destination.city}" }
    ],
    "auxiliaryFields": [
      { "key": "service", "label": "SERVICE", "value": "${s.service}" },
      { "key": "eta", "label": "ETA", "value": "${s.etaFormatted}" }
    ],
    "backFields": [
      { "key": "origin", "label": "Origin", "value": "${_esc(s.origin.oneLine)}" },
      { "key": "destination", "label": "Destination", "value": "${_esc(s.destination.oneLine)}" },
      { "key": "status", "label": "Status", "value": "${s.status.label}" }
    ]
  },
  "barcodes": [
    { "format": "PKBarcodeFormatQR", "message": "${s.trackingNumber}", "messageEncoding": "iso-8859-1" }
  ]
}
''';
  }

  String _buildManifest(List<MapEntry<String, Uint8List>> files) {
    final entries = files
        .map((e) => '"${e.key}":"${sha1.convert(e.value)}"')
        .join(',');
    return '{$entries}';
  }

  /// 1×1 transparent PNG used as a placeholder for icon/logo. Apple
  /// rejects unsigned passes on real devices anyway, so the icon is
  /// purely structural.
  Uint8List _placeholderPng() => Uint8List.fromList(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00,
        0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63,
        0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
        0x82,
      ]);
}
