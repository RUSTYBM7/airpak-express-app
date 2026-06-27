import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/smartsupp_controller.dart';

import '../features/admin/screens/admin_2fa_screen.dart';
import '../features/admin/screens/admin_ai_studio_screen.dart';
import '../features/admin/screens/admin_ai_templates_screen.dart';
import '../features/admin/screens/admin_audit_logs_screen.dart';
import '../features/admin/screens/admin_automation_screen.dart';
import '../features/admin/screens/admin_chat_screen.dart';
import '../features/admin/screens/admin_dashboard_screen.dart';
import '../features/admin/screens/admin_document_parser_screen.dart';
import '../features/admin/screens/admin_forgot_password_screen.dart';
import '../features/admin/screens/admin_layout.dart';
import '../features/admin/screens/admin_login_screen.dart';
import '../features/admin/screens/admin_reset_password_screen.dart';
import '../features/admin/screens/admin_settings_screen.dart';
import '../features/admin/screens/admin_shipment_create_screen.dart';
import '../features/admin/screens/admin_shipments_screen.dart';
import '../features/admin/screens/admin_tracking_editor_screen.dart';
import '../features/admin/screens/admin_users_screen.dart';
import '../features/admin/screens/admin_user_detail_screen.dart';
import '../features/admin/screens/admin_voice_tools_screen.dart';
import '../features/auth/providers/auth_controller.dart';
import '../features/auth/screens/biometric_setup_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/reset_password_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/welcome_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/onboarding/screens/enterprise_onboarding_screen.dart';
import '../features/portal/screens/create_shipment_screen.dart';
import '../features/portal/screens/payments_screen.dart';
import '../features/payments/screens/crypto_deposit_screen.dart';
import '../features/portal/screens/portal_dashboard_screen.dart';
import '../features/portal/screens/portal_layout.dart';
import '../features/portal/screens/profile_screen.dart';
import '../features/portal/screens/rewards_screen.dart';
import '../features/portal/screens/settings_screen.dart';
import '../features/portal/screens/shipment_detail_screen.dart';
import '../features/portal/screens/shipments_screen.dart';
import '../features/portal/screens/support_chat_screen.dart';
import '../features/portal/screens/live_chat_screen.dart';
import '../features/portal/screens/notifications_screen.dart';
import '../features/privacy/screens/privacy_screen.dart';
import '../features/terms/screens/terms_screen.dart';
import '../features/tracking/screens/live_map_screen.dart';
import '../features/tracking/screens/tracking_screen.dart';
import '../core/models/profile.dart';

class AppRoutes {
  static const splash = '/splash';
  static const home = '/';
  static const tracking = '/tracking';
  static const liveMap = '/live-map';
  static const liveMapWithId = '/live-map/:tracking';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot-password';
  static const reset = '/reset-password';
  static const otp = '/otp';
  static const welcome = '/welcome';
  static const biometric = '/biometric-setup';
  static const onboarding = '/onboarding';
  static const terms = '/terms';
  static const privacy = '/privacy';

  static const portalDashboard = '/portal/dashboard';
  static const portalShipments = '/portal/shipments';
  static const portalCreate = '/portal/create';
  static const portalPayments = '/portal/payments';
  static const portalRewards = '/portal/rewards';
  static const portalSettings = '/portal/settings';
  static const portalSupport = '/portal/support';
  static const portalProfile = '/portal/profile';

  static const adminLogin = '/admin/login';
  static const admin2fa = '/admin/2fa';
  static const adminForgot = '/admin/forgot-password';
  static const adminReset = '/admin/reset-password';
  static const adminPortal = '/admin/portal';
  static const adminUsers = '/admin/portal/users';
  static const adminCreate = '/admin/portal/create';
  static const adminChat = '/admin/portal/chat';
  static const adminSettings = '/admin/portal/settings';
  static const adminAiStudio = '/admin/portal/ai-studio';
  static const adminAiTemplates = '/admin/portal/ai-templates';
  static const adminAutomation = '/admin/portal/automation';
  static const adminDocParser = '/admin/portal/document-parser';
  static const adminVoiceTools = '/admin/portal/voice-tools';
  static const adminAuditLogs = '/admin/portal/audit-logs';
  static const adminWorkflows = '/admin/portal/workflows';
  static const adminAutopilot = '/admin/portal/autopilot';
  static const adminShipments = '/admin/portal/shipments';
  static const adminTrackingEditor = '/admin/portal/shipment/tracking';
}

GoRouter buildRouter(Ref ref) {
  final smartsupp = ref.read(smartsuppControllerProvider);
  final goRouter = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: _AuthRefresh(ref),
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      // Sync Smartsupp with the active route.
      smartsupp.syncWithRoute(loc);

      // Splash manages its own routing — leave it alone.
      if (loc == AppRoutes.splash) return null;

      // Until auth bootstrap is done, send everyone to the splash.
      if (auth.initializing) return AppRoutes.splash;

      final isAdminRoute = loc.startsWith('/admin/portal');
      final isPortalRoute = loc.startsWith('/portal');
      final isAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.register ||
          loc == AppRoutes.forgot ||
          loc == AppRoutes.reset ||
          loc == AppRoutes.otp ||
          loc == AppRoutes.welcome;
      final isAdminAuthRoute = loc.startsWith('/admin') && !isAdminRoute;
      final isOnboardingRoute = loc == AppRoutes.biometric;

      if (isAdminRoute && auth.role != UserRole.admin) {
        return AppRoutes.adminLogin;
      }
      if (isPortalRoute && !auth.authenticated) {
        return AppRoutes.login;
      }
      if (isAuthRoute && auth.authenticated) {
        return auth.role == UserRole.admin
            ? AppRoutes.adminPortal
            : AppRoutes.portalDashboard;
      }
      if (isAdminAuthRoute && auth.authenticated && auth.role == UserRole.admin) {
        return AppRoutes.adminPortal;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, __) => const WelcomeScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, st) {
          final email = st.uri.queryParameters['email'] ?? 'your email';
          final next = st.uri.queryParameters['next'] ?? AppRoutes.portalDashboard;
          final title = st.uri.queryParameters['title'] ?? 'Verify your email';
          return OtpScreen(
            email: email,
            title: title,
            nextRoute: next,
            onVerify: (code) async => code.length == 6,
          );
        },
      ),
      GoRoute(
          path: AppRoutes.biometric,
          builder: (_, __) => const BiometricSetupScreen()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: AppRoutes.tracking,
        builder: (_, __) => const TrackingScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.tracking}/:tracking',
        builder: (_, st) =>
            TrackingScreen(initialTracking: st.pathParameters['tracking']),
      ),
      GoRoute(
        path: AppRoutes.liveMap,
        builder: (_, st) {
          final t = st.uri.queryParameters['tracking'] ?? 'APK2026052600003';
          return LiveMapScreen(tracking: t);
        },
      ),
      GoRoute(
        path: '/portal/track/:tracking',
        builder: (_, st) {
          final t = st.pathParameters['tracking'] ?? 'APK2026052600003';
          return LiveMapScreen(tracking: t);
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgot,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.reset,
        builder: (_, __) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const EnterpriseOnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (_, __) => const TermsScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (_, __) => const PrivacyScreen(),
      ),
      // ── Customer portal shell ─────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => PortalLayout(child: child),
        routes: [
          GoRoute(
              path: AppRoutes.portalDashboard,
              builder: (_, __) => const PortalDashboardScreen()),
          GoRoute(
              path: AppRoutes.portalShipments,
              builder: (_, __) => const ShipmentsScreen()),
          GoRoute(
              path: AppRoutes.portalPayments,
              builder: (_, __) => const PaymentsScreen()),
          GoRoute(
              path: AppRoutes.portalRewards,
              builder: (_, __) => const RewardsScreen()),
          GoRoute(
              path: AppRoutes.portalSettings,
              builder: (_, __) => const SettingsScreen()),
        ],
      ),
      GoRoute(
        path: AppRoutes.portalCreate,
        builder: (_, __) => const CreateShipmentScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.portalShipments}/:id',
        builder: (_, st) => ShipmentDetailScreen(shipmentId: st.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.portalSupport,
        builder: (_, __) => const LiveChatScreen(userId: 'demo'),
      ),
      GoRoute(
        path: '/portal/chat/:userId',
        builder: (_, st) => LiveChatScreen(userId: st.pathParameters['userId'] ?? 'demo'),
      ),
      GoRoute(
        path: '/portal/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.portalProfile,
        builder: (_, __) => const ProfileScreen(),
      ),
      // ── Admin auth ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin2fa,
        builder: (_, __) => const Admin2FAScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminForgot,
        builder: (_, __) => const AdminForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReset,
        builder: (_, __) => const AdminResetPasswordScreen(),
      ),
      // ── Admin shell ───────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
              path: AppRoutes.adminPortal,
              builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: AppRoutes.adminUsers,
              builder: (_, __) => const AdminUsersScreen()),
          GoRoute(
              path: AppRoutes.adminChat,
              builder: (_, __) => const AdminChatScreen()),
          GoRoute(
              path: AppRoutes.adminSettings,
              builder: (_, __) => const AdminSettingsScreen()),
          GoRoute(
              path: AppRoutes.adminAiStudio,
              builder: (_, __) => const AdminAiStudioScreen()),
          GoRoute(
              path: AppRoutes.adminAutomation,
              builder: (_, __) => const AdminAutomationScreen()),
          GoRoute(
              path: AppRoutes.adminDocParser,
              builder: (_, __) => const AdminDocumentParserScreen()),
          GoRoute(
              path: AppRoutes.adminVoiceTools,
              builder: (_, __) => const AdminVoiceToolsScreen()),
          GoRoute(
              path: AppRoutes.adminAuditLogs,
              builder: (_, __) => const AdminAuditLogsScreen()),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminCreate,
        builder: (_, __) => const AdminShipmentCreateScreen(),
      ),
      GoRoute(
        path: '/admin/portal/user/:userId',
        builder: (_, st) => AdminUserDetailScreen(
          userId: st.pathParameters['userId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.adminAiTemplates,
        builder: (_, __) => const AdminAiTemplatesScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminShipments,
        builder: (_, __) => const AdminShipmentsScreen(),
      ),
      GoRoute(
        path: '/admin/portal/shipment/:shipmentId/tracking',
        builder: (_, st) => AdminTrackingEditorScreen(
          shipmentId: st.pathParameters['shipmentId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/portal/crypto-deposit',
        builder: (_, __) => const CryptoDepositScreen(),
      ),
    ],
  );
  return goRouter;
}

/// Bridge between Riverpod's StateNotifier and GoRouter's redirect listener.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _sub = _ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
  late final ProviderSubscription<AuthState> _sub;
  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));
