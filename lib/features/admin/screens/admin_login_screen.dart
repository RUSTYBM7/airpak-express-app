import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../auth/providers/auth_controller.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _email = TextEditingController(text: 'admin@airpak-express.com');
  final _password = TextEditingController(text: 'admin1234');
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .adminSignIn(_email.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      context.go(AppRoutes.admin2fa);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top > 20 ? 8 : 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded,
                            size: 12, color: AppColors.brand),
                        SizedBox(width: 4),
                        Text('Restricted',
                            style: TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Admin Portal',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                    color: context.textColor,
                  )),
              const SizedBox(height: 4),
              Text(
                'Restricted access. All activity is logged.',
                style: TextStyle(color: context.textMutedColor, fontSize: 14),
              ),
              const SizedBox(height: 32),
              IosTextField(
                controller: _email,
                label: 'Admin email',
                hint: 'admin@airpak-express.com',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              IosTextField(
                controller: _password,
                label: 'Password',
                prefixIcon: Icons.lock_outline_rounded,
                obscure: _obscure,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.adminForgot),
                  child: const Text('Forgot password?',
                      style: TextStyle(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              if (auth.error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(auth.error!,
                              style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              IosPrimaryButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _submit,
                busy: _busy,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFEDD5), Color(0xFFFFE4B5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        color: AppColors.warning, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Demo credentials prefilled. You will be asked for a 2FA code next (use 000000).',
                        style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
