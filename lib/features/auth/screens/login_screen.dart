import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../../../core/widgets/airpak_brand.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController(text: 'demo@airpak-express.com');
  final _password = TextEditingController(text: 'demo1234');
  bool _obscure = true;
  bool _busy = false;
  bool _ssoBusy = false;
  late final AnimationController _entryCtl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();
  late final Animation<double> _entry =
      CurvedAnimation(parent: _entryCtl, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _entryCtl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      final role = ref.read(authControllerProvider).role;
      context.go(role.name == 'admin'
          ? AppRoutes.adminPortal
          : AppRoutes.portalDashboard);
    }
  }

  Future<void> _signInWith(String provider) async {
    setState(() => _ssoBusy = true);
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _ssoBusy = false);
    if (ok) {
      final role = ref.read(authControllerProvider).role;
      context.go(role.name == 'admin'
          ? AppRoutes.adminPortal
          : AppRoutes.portalDashboard);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.fingerprint_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text('$provider sign-in · use email + password'),
            ],
          ),
          backgroundColor: AppColors.brand,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _signInBiometric() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      final role = ref.read(authControllerProvider).role;
      context.go(role.name == 'admin'
          ? AppRoutes.adminPortal
          : AppRoutes.portalDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return AuthScreenScaffold(
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("New to AirPak? ",
              style: TextStyle(
                  color: context.textMutedColor, fontSize: 13.5)),
          GestureDetector(
            onTap: () => context.push(AppRoutes.register),
            child: const Text(
              'Create account',
              style: TextStyle(
                color: AppColors.brand,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _entry,
        builder: (_, __) => Opacity(
          opacity: _entry.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _entry.value) * 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Center(child: AirpakMark(size: 64)),
                  const SizedBox(height: 14),
                  Center(
                    child: AirpakWordmark(size: 32, showUnderline: false),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'E X P R E S S',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontSize: 10,
                        letterSpacing: 6,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthHeading(
                    title: 'Welcome back',
                    subtitle:
                        'Sign in to track shipments, manage deliveries, and pay invoices across the globe.',
                  ),
                  const SizedBox(height: 28),
                  AuthTextField(
                    controller: _email,
                    label: 'EMAIL',
                    icon: Icons.email_outlined,
                    keyboard: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  AuthTextField(
                    controller: _password,
                    label: 'PASSWORD',
                    icon: Icons.lock_outline_rounded,
                    obscure: true,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'At least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _RememberMe(),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.forgot),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (auth.error != null) ...[
                    const SizedBox(height: 16),
                    AuthErrorBanner(message: auth.error!),
                  ],
                  const SizedBox(height: 20),
                  AuthPrimaryButton(
                    label: 'Sign in',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _submit,
                    busy: _busy,
                  ),
                  const SizedBox(height: 18),
                  _DividerWithLabel(label: 'or continue with'),
                  const SizedBox(height: 18),
                  // Biometric quick login
                  _BiometricButton(
                    onTap: _ssoBusy || _busy ? null : _signInBiometric,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SsoButton(
                          icon: Icons.apple_rounded,
                          label: 'Apple',
                          onTap: _ssoBusy
                              ? null
                              : () => _signInWith('Apple'),
                          busy: _ssoBusy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SsoButton(
                          icon: Icons.g_mobiledata_rounded,
                          label: 'Google',
                          onTap: _ssoBusy
                              ? null
                              : () => _signInWith('Google'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SsoButton(
                          icon: Icons.business_rounded,
                          label: 'SSO',
                          onTap: _ssoBusy
                              ? null
                              : () => _signInWith('SSO'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.adminLogin),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.surfaceMutedColor,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded,
                                size: 14, color: context.textMutedColor),
                            const SizedBox(width: 6),
                            Text('Sign in as AirPak staff',
                                style: TextStyle(
                                  color: context.textMutedColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded,
                                size: 16, color: context.textMutedColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

class _RememberMe extends StatefulWidget {
  @override
  State<_RememberMe> createState() => _RememberMeState();
}

class _RememberMeState extends State<_RememberMe> {
  bool _v = true;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _v,
            onChanged: (v) => setState(() => _v = v ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            side: BorderSide(color: context.borderColor, width: 1.2),
            activeColor: AppColors.brand,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5)),
          ),
        ),
        const SizedBox(width: 6),
        Text('Keep me signed in',
            style: TextStyle(
                color: context.textMutedColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DividerWithLabel extends StatelessWidget {
  final String label;
  const _DividerWithLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: context.borderColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(
                color: context.textMutedColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              )),
        ),
        Expanded(child: Container(height: 1, color: context.borderColor)),
      ],
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BiometricButton({this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.brand.withValues(alpha: 0.10),
                AppColors.brandDark.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.4), width: 1.2),
          ),
          child: Row(
            children: [
              const SizedBox(width: 18),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.face_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign in with Face ID',
                      style: GoogleFonts.inter(
                        color: context.textColor,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                    Text(
                      'Use biometric authentication',
                      style: TextStyle(
                        color: context.textMutedColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.brand),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
