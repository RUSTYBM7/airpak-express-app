import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../app/design_system.dart';
import '../../../app/ios_components.dart';
import '../../../app/router.dart';
import '../../auth/providers/auth_controller.dart';

class Admin2FAScreen extends ConsumerStatefulWidget {
  const Admin2FAScreen({super.key});
  @override
  ConsumerState<Admin2FAScreen> createState() => _Admin2FAScreenState();
}

class _Admin2FAScreenState extends ConsumerState<Admin2FAScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(authControllerProvider.notifier).verify2FA(_code.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.go(AppRoutes.adminPortal);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.zero,
                onPressed: () => context.go(AppRoutes.adminLogin),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const SizedBox(height: 24),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.lock_clock_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 20),
              Text('Two-factor authentication',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: context.textColor,
                  )),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code from your authenticator app.',
                style: TextStyle(color: context.textMutedColor, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Center(
                child: Pinput(
                  controller: _code,
                  length: 6,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  defaultPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.brand, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.18),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  submittedPinTheme: PinTheme(
                    width: 48,
                    height: 56,
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                    decoration: BoxDecoration(
                      color: AppColors.brandSoft,
                      border: Border.all(color: AppColors.brand, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onCompleted: (_) => _verify(),
                ),
              ),
              if (auth.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppColors.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(auth.error!,
                              style: TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),
              IosPrimaryButton(
                label: 'Verify',
                icon: Icons.verified_user_rounded,
                onPressed: _verify,
                busy: _busy,
              ),
              const SizedBox(height: 8),
              Center(
                child: IosTextButton(
                  'Use demo code 000000',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    _code.text = '000000';
                    _verify();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
