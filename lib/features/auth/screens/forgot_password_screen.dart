import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty) return;
    setState(() => _busy = true);
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() => _busy = false);
    context.push(
      '${AppRoutes.otp}?email=${Uri.encodeComponent(_email.text.trim())}'
      '&title=${Uri.encodeComponent('Reset your password')}'
      '&next=${Uri.encodeComponent(AppRoutes.reset)}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      onBack: () => context.pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 20),
          AuthHeading(
            title: 'Forgot password?',
            subtitle:
                'Enter your email and we will send you a 6-digit code to reset your AirPak Express account.',
          ),
          const SizedBox(height: 28),
          AuthTextField(
            controller: _email,
            label: 'EMAIL',
            icon: Icons.email_outlined,
            keyboard: TextInputType.emailAddress,
            autofocus: true,
          ),
          const SizedBox(height: 22),
          AuthPrimaryButton(
            label: 'Send reset code',
            icon: Icons.send_rounded,
            onPressed: _submit,
            busy: _busy,
          ),
          const SizedBox(height: 22),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text(
                'Back to sign in',
                style: GoogleFonts.inter(
                  color: context.textMutedColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
