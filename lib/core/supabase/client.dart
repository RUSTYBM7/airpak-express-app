import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Thin wrapper around the global Supabase client so feature code can
/// depend on this provider instead of importing supabase_flutter
/// directly. The mock data fallback lives in the repository layer.
class SupabaseClientProvider {
  SupabaseClientProvider._();

  static SupabaseClient get instance {
    return Supabase.instance.client;
  }

  static bool get isConfigured =>
      AppEnv.supabaseAnonKey.isNotEmpty ||
      AppEnv.supabasePublishableKey.isNotEmpty;

  static String get _key =>
      AppEnv.supabasePublishableKey.isNotEmpty
          ? AppEnv.supabasePublishableKey
          : AppEnv.supabaseAnonKey;

  static Future<void> init() async {
    if (!isConfigured) return;
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: _key,
    );
  }
}
