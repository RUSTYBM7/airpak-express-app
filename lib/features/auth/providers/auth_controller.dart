import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env.dart';
import '../../../core/data/repositories.dart';
import '../../../core/models/profile.dart';
import '../../../core/supabase/client.dart';

final shipmentRepoProvider =
    Provider<ShipmentRepository>((_) => ShipmentRepository());

/// Top-level auth state, derived from Supabase when available
/// or from a local session store otherwise.
class AuthState {
  final bool initializing;
  final bool authenticated;
  final String userId;
  final String email;
  final UserRole role;
  final AppProfile? profile;
  final String? error;
  const AuthState({
    this.initializing = true,
    this.authenticated = false,
    this.userId = '',
    this.email = '',
    this.role = UserRole.customer,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    bool? initializing,
    bool? authenticated,
    String? userId,
    String? email,
    UserRole? role,
    AppProfile? profile,
    String? error,
    bool clearError = false,
  }) =>
      AuthState(
        initializing: initializing ?? this.initializing,
        authenticated: authenticated ?? this.authenticated,
        userId: userId ?? this.userId,
        email: email ?? this.email,
        role: role ?? this.role,
        profile: profile ?? this.profile,
        error: clearError ? null : (error ?? this.error),
      );
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._ref) : super(const AuthState()) {
    _bootstrap();
  }

  final Ref _ref;
  ShipmentRepository get _repo => _ref.read(shipmentRepoProvider);

  Future<void> _bootstrap() async {
    if (SupabaseClientProvider.isConfigured && !AppEnv.useMockData) {
      final client = SupabaseClientProvider.instance;
      final session = client.auth.currentSession;
      if (session != null) {
        await _hydrateFromSupabase(session.user);
        return;
      }
      state = state.copyWith(initializing: false);
      client.auth.onAuthStateChange.listen((event) {
        if (event.event == sb.AuthChangeEvent.signedIn) {
          _hydrateFromSupabase(event.session!.user);
        } else if (event.event == sb.AuthChangeEvent.signedOut) {
          state = const AuthState(initializing: false);
        }
      });
    } else {
      // Mock mode: stay signed OUT on first launch. The user is
      // taken to the welcome screen, and can sign in with the demo
      // credentials, or use the Continue as guest button to skip
      // straight into the demo experience.
      state = const AuthState(initializing: false);
    }
  }

  Future<void> _hydrateFromSupabase(sb.User user) async {
    final res = await _repo.getProfile(user.id);
    final profile = res.data ??
        AppProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: user.userMetadata?['full_name']?.toString(),
        );
    state = AuthState(
      initializing: false,
      authenticated: true,
      userId: user.id,
      email: user.email ?? '',
      role: profile.role,
      profile: profile,
    );
  }

  // ── Email + password (mock + real) ────────────────────────────────────

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(clearError: true);
    if (SupabaseClientProvider.isConfigured && !AppEnv.useMockData) {
      try {
        await SupabaseClientProvider.instance.auth
            .signInWithPassword(email: email, password: password);
        return true;
      } on sb.AuthException catch (e) {
        state = state.copyWith(error: e.message);
        return false;
      }
    }
    // mock
    if (email.isEmpty || password.length < 6) {
      state = state.copyWith(error: 'Invalid email or password');
      return false;
    }
    final isAdmin = email.toLowerCase().contains('admin');
    final role = isAdmin ? UserRole.admin : UserRole.customer;
    final res = await _repo.upsertProfile(AppProfile(
      id: isAdmin ? 'usr_demo_admin' : 'usr_demo_customer',
      email: email,
      fullName: isAdmin ? 'Admin User' : 'Demo Customer',
      role: role,
      companyName: isAdmin ? 'AirPak Express' : 'Lumen Trading',
    ));
    final profile = res.data!;
    state = state.copyWith(
      authenticated: true,
      userId: profile.id,
      email: profile.email,
      role: profile.role,
      profile: profile,
    );
    return true;
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = state.copyWith(clearError: true);
    if (SupabaseClientProvider.isConfigured && !AppEnv.useMockData) {
      try {
        await SupabaseClientProvider.instance.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName, 'phone': phone},
        );
        return true;
      } on sb.AuthException catch (e) {
        state = state.copyWith(error: e.message);
        return false;
      }
    }
    final res = await _repo.upsertProfile(AppProfile(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      fullName: fullName,
      phone: phone,
      role: UserRole.customer,
    ));
    final profile = res.data!;
    state = state.copyWith(
      authenticated: true,
      userId: profile.id,
      email: profile.email,
      role: profile.role,
      profile: profile,
    );
    return true;
  }

  Future<bool> adminSignIn(String email, String password) async {
    final ok = await signIn(email, password);
    if (!ok) return false;
    if (state.role != UserRole.admin) {
      final current = state.profile!;
      final updated = await _repo.upsertProfile(AppProfile(
        id: current.id,
        email: current.email,
        fullName: current.fullName,
        phone: current.phone,
        role: UserRole.admin,
        walletBalance: current.walletBalance,
        rewardPoints: current.rewardPoints,
        companyName: 'AirPak Express',
        twoFactorEnabled: true,
      ));
      state = state.copyWith(role: UserRole.admin, profile: updated.data);
    }
    return true;
  }

  Future<bool> verify2FA(String code) async {
    if (code == '000000' || code.length != 6) {
      state = state.copyWith(error: 'Invalid 2FA code (use 000000 in demo)');
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }

  Future<void> sendPasswordReset(String email) async {
    if (SupabaseClientProvider.isConfigured && !AppEnv.useMockData) {
      await SupabaseClientProvider.instance.auth
          .resetPasswordForEmail(email);
    }
  }

  Future<bool> resetPassword(String newPassword) async {
    if (newPassword.length < 6) {
      state = state.copyWith(error: 'Password must be at least 6 characters');
      return false;
    }
    state = state.copyWith(clearError: true);
    return true;
  }

  Future<void> signOut() async {
    if (SupabaseClientProvider.isConfigured && !AppEnv.useMockData) {
      await SupabaseClientProvider.instance.auth.signOut();
    }
    state = const AuthState(initializing: false);
    // auto re-sign in as customer for demo flow
    await _bootstrap();
  }

  Future<void> updateProfile(AppProfile updated) async {
    final res = await _repo.upsertProfile(updated);
    state = state.copyWith(profile: res.data);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref);
});
