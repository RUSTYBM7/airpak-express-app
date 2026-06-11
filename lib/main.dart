import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/payment_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/supabase/client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialise backend + platform integrations. Each one is a safe
  // no-op when its keys / configs are missing, so the app always boots.
  await SupabaseClientProvider.init();
  await PushNotificationService.instance.init();
  await PaymentService.instance.init();

  runApp(const ProviderScope(child: ShipNowApp()));
}
