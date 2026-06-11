import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

import '../config/env.dart';
import '../models/shipment.dart';

/// Result of a payment attempt.
class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? error;
  final String? receiptUrl;
  const PaymentResult.ok({
    required this.paymentIntentId,
    this.receiptUrl,
  })  : success = true,
        error = null;
  const PaymentResult.fail(this.error)
      : success = false,
        paymentIntentId = null,
        receiptUrl = null;
}

/// Stripe + FPX payment façade.
///
/// The flow is:
///   1. App calls [createPaymentIntent] on your backend (or the
///      built-in mock) to get a client secret.
///   2. [presentPaymentSheet] opens the Stripe sheet, including FPX
///      as a payment method when [AppEnv.fpxEnabled] is true and
///      FPX is enabled in your Stripe account.
///   3. On success we return the PaymentIntent id; the caller
///      marks the shipment as paid.
class PaymentService {
  PaymentService._();
  static final PaymentService instance = PaymentService._();

  bool _initialised = false;

  Future<void> init() async {
    if (_initialised) return;
    if (!AppEnv.enableStripe) return;
    if (AppEnv.stripePublishableKey.isEmpty) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Stripe publishable key not set — payment sheet is disabled.');
      }
      return;
    }
    Stripe.publishableKey = AppEnv.stripePublishableKey;
    if (kIsWeb) {
      // nothing extra on web
    } else {
      try {
        await Stripe.instance.applySettings();
      } catch (_) {
        // applySettings is iOS-only; safe to swallow on Android.
      }
    }
    _initialised = true;
  }

  /// True when Stripe has been initialised and a publishable key is
  /// available. UI uses this to decide whether to show a "Pay with
  /// card / FPX" button or fall back to a mock confirm flow.
  bool get isReady => _initialised && AppEnv.stripePublishableKey.isNotEmpty;

  /// Open the Stripe payment sheet for a shipment. Returns success /
  /// failure once the user finishes (or cancels) the flow.
  Future<PaymentResult> payForShipment(Shipment s) async {
    if (!isReady) {
      // Mock / unsigned mode — pretend the payment worked.
      await Future<void>.delayed(const Duration(milliseconds: 800));
      return PaymentResult.ok(
          paymentIntentId: 'pi_mock_${s.id}');
    }
    try {
      final intent = await createPaymentIntent(
        amountCents: (s.price * 100).round(),
        currency: s.currency.toLowerCase(),
        description: 'ShipNow ${s.trackingNumber}',
        metadata: {
          'shipment_id': s.id,
          'tracking_number': s.trackingNumber,
        },
      );
      if (intent.clientSecret.isEmpty) {
        return const PaymentResult.fail('Could not create PaymentIntent');
      }
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent.clientSecret,
          customerEphemeralKeySecret: intent.ephemeralKey,
          customerId: intent.customerId,
          merchantDisplayName: 'AirPak Express',
          style: ThemeMode.light,
          billingDetails: BillingDetails(
            name: s.destination.name,
            email: s.userId,
            phone: s.destination.phone,
          ),
          // FPX shows up automatically when the PaymentIntent is
          // created with the MY account and FPX is enabled in the
          // Stripe dashboard.
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      return PaymentResult.ok(
        paymentIntentId: intent.paymentIntentId,
        receiptUrl: intent.receiptUrl,
      );
    } on StripeException catch (e) {
      final msg = e.error.localizedMessage ?? e.toString();
      return PaymentResult.fail(msg);
    } catch (e) {
      return PaymentResult.fail(e.toString());
    }
  }

  /// Creates a PaymentIntent. The exact contract with the backend is
  /// `{ amount, currency, description, metadata, payment_method_types }`
  /// → `{ id, client_secret, customer, ephemeral_key, receipt_url }`.
  ///
  /// When [AppEnv.stripeBackendUrl] is empty (mock mode) we return a
  /// synthesised intent so the rest of the flow can be exercised.
  Future<PaymentIntentData> createPaymentIntent({
    required int amountCents,
    required String currency,
    required String description,
    Map<String, String> metadata = const {},
  }) async {
    // Either call your backend or simulate a successful intent.
    if (AppEnv.stripeBackendUrl.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('${AppEnv.stripeBackendUrl}/v1/payment_intents'),
          headers: {
            'Content-Type': 'application/json',
            if (AppEnv.stripePublishableKey.isNotEmpty)
              'Authorization':
                  'Bearer ${AppEnv.stripePublishableKey}',
          },
          body: jsonEncode({
            'amount': amountCents,
            'currency': currency,
            'description': description,
            'metadata': metadata,
            'payment_method_types': [
              'card',
              if (AppEnv.fpxEnabled) 'fpx',
            ],
          }),
        );
        if (res.statusCode != 200) {
          if (kDebugMode) {
            // ignore: avoid_print
            print('PaymentIntent backend error: ${res.statusCode}');
          }
          throw Exception('PaymentIntent backend error: ${res.statusCode}');
        }
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return PaymentIntentData(
          clientSecret: json['client_secret'] as String,
          paymentIntentId: json['id'] as String?,
          customerId: json['customer'] as String?,
          ephemeralKey: json['ephemeral_key'] as String?,
          receiptUrl: json['receipt_url'] as String?,
        );
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('PaymentIntent request failed: $e');
        }
        rethrow;
      }
    }

    // Mock — return a fake but well-formed secret so the sheet can open
    // in test mode. Replace with the real backend before launch.
    return PaymentIntentData(
      clientSecret:
          'pi_mock_secret_${DateTime.now().millisecondsSinceEpoch}',
      paymentIntentId: 'pi_mock',
    );
  }
}

/// Public shape of a Stripe PaymentIntent as returned by the backend.
class PaymentIntentData {
  final String clientSecret;
  final String? paymentIntentId;
  final String? customerId;
  final String? ephemeralKey;
  final String? receiptUrl;
  const PaymentIntentData({
    required this.clientSecret,
    this.paymentIntentId,
    this.customerId,
    this.ephemeralKey,
    this.receiptUrl,
  });
}
