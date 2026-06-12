/// Centralised runtime configuration.
///
/// Every value is read from --dart-define at build time so the same
/// binary can target staging, prod or a local mock without code changes.
///
/// See README.md "Build flags" for the full list.
class AppEnv {
  const AppEnv._();

  // ── Supabase ──────────────────────────────────────────────────────────
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://zygoqqsgzhgpvlpttfbk.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  // ── Maps ──────────────────────────────────────────────────────────────
  /// Tile provider preset:
  ///   "demotiles"  → free MapLibre demo (default)
  ///   "maptiler"   → MapTiler (needs MAPTILER_KEY)
  ///   "mapbox"     → Mapbox (needs MAPBOX_TOKEN)
  ///   "stadia"     → Stadia Maps (needs STADIA_KEY)
  ///   "custom"     → MAPLIBRE_STYLE_URL is used verbatim
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',
  );
  static const bool liveBridgeEnabled = bool.fromEnvironment(
    'LIVE_BRIDGE',
    defaultValue: true,
  );
  static const String mapProvider = String.fromEnvironment(
    'MAP_PROVIDER',
    defaultValue: 'demotiles',
  );
  static const String maplibreStyleUrl = String.fromEnvironment(
    'MAPLIBRE_STYLE_URL',
    defaultValue: 'https://demotiles.maplibre.org/style.json',
  );
  static const String maptilerKey = String.fromEnvironment(
    'MAPTILER_KEY',
    defaultValue: '',
  );
  static const String stadiaKey = String.fromEnvironment(
    'STADIA_KEY',
    defaultValue: '',
  );
  static const String mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );

  // ── Stripe ────────────────────────────────────────────────────────────
  /// Test publishable key (pk_test_…) from your Stripe dashboard.
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  /// Your backend URL that creates a PaymentIntent. Required for live
  /// payments. Leave blank to run in mock mode (the payment sheet will
  /// just confirm a fake intent).
  static const String stripeBackendUrl = String.fromEnvironment(
    'STRIPE_BACKEND_URL',
    defaultValue: '',
  );
  /// Set true to enable FPX (Malaysian online banking) as a payment
  /// method. Requires your Stripe account to have FPX enabled in the
  /// dashboard.
  static const bool fpxEnabled = bool.fromEnvironment(
    'FPX_ENABLED',
    defaultValue: true,
  );

  // ── Apple Wallet ──────────────────────────────────────────────────────
  /// Base URL of your Wallet pass backend. The Flutter app POSTs the
  /// shipment to this URL and receives a signed .pkpass blob.
  /// In dev, leave empty — the on-device signer is used as a fallback
  /// (unsigned passes won't be installable, but the UI flow works).
  static const String walletBackendUrl = String.fromEnvironment(
    'WALLET_BACKEND_URL',
    defaultValue: '',
  );
  static const String walletPassTypeId = String.fromEnvironment(
    'WALLET_PASS_TYPE_ID',
    defaultValue: 'pass.com.airpak-express.shipnow',
  );
  static const String walletTeamId = String.fromEnvironment(
    'WALLET_TEAM_ID',
    defaultValue: '',
  );

  // ── FCM / Push ────────────────────────────────────────────────────────
  static const String fcmSenderId = String.fromEnvironment(
    'FCM_SENDER_ID',
    defaultValue: '',
  );
  static const String fcmVapidKey = String.fromEnvironment(
    'FCM_VAPID_KEY',
    defaultValue: '',
  );

  // ── Support AI ────────────────────────────────────────────────────────
  /// URL of your backend endpoint that proxies to MiniMax-M3 (or any
  /// OpenAI-compatible chat completions API). The Flutter app POSTs:
  ///   { "messages": [{role, content}, ...] }
  /// and expects:
  ///   { "message": { "role": "assistant", "content": "..." } }
  static const String supportAiUrl = String.fromEnvironment(
    'SUPPORT_AI_URL',
    defaultValue: '',
  );
  static const String supportAiApiKey = String.fromEnvironment(
    'SUPPORT_AI_API_KEY',
    defaultValue: '',
  );
  /// System prompt sent on the first turn of every new conversation.
  /// Branded around Mavis (the MiniMax agent) and the MiniMax-M3 model.
  static const String supportAiSystemPrompt = String.fromEnvironment(
    'SUPPORT_AI_SYSTEM_PROMPT',
    defaultValue:
        'You are AirPak Support, the in-app AI assistant for ShipNow — '
        'a shipping & logistics platform by AirPak Express, powered by '
        'the Mavis agent (built by MiniMax) on the MiniMax-M3 model. '
        '\n\n'
        'Your job: help customers track shipments, book pickups, understand '
        'charges, customs rules, refund policy, FPX / card payment options, '
        'and resolve delivery issues. Be concise, friendly, and accurate. '
        'Use short paragraphs. Quote a tracking number, ETA or price '
        'when you have one. If you do not know the answer, offer to '
        'connect the customer with a human agent (tap the switcher in the '
        'app bar). Never invent tracking numbers; if a number is '
        'malformed, ask for it again.',
  );
  /// Model identifier sent to the backend (informational only). The
  /// app is wired against any OpenAI-compatible chat completions API
  /// — the default value reflects the Mavis (by MiniMax) M3 model that
  /// powers this project's development workflow.
  static const String supportAiModel = String.fromEnvironment(
    'SUPPORT_AI_MODEL',
    defaultValue: 'MiniMax-M3',
  );

  // ── App behaviour ─────────────────────────────────────────────────────
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  // ── Brand ─────────────────────────────────────────────────────────────
  static const String brandName = 'AirPak Express';
  static const String brandTagline = 'AirPak Express';
  static const String supportEmail = 'support@airpak-express.com';
  static const String supportPhone = '+60 3-7875 7768';

  // ── Feature flags ─────────────────────────────────────────────────────
  static const bool enablePush = bool.fromEnvironment(
    'ENABLE_PUSH',
    defaultValue: true,
  );
  static const bool enableStripe = bool.fromEnvironment(
    'ENABLE_STRIPE',
    defaultValue: true,
  );
  static const bool enableAppleWallet = bool.fromEnvironment(
    'ENABLE_APPLE_WALLET',
    defaultValue: true,
  );
  static const bool enableSupportAi = bool.fromEnvironment(
    'ENABLE_SUPPORT_AI',
    defaultValue: true,
  );
}
