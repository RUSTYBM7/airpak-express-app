import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/design_system.dart';
import '../../../app/router.dart';
import '../providers/auth_controller.dart';
import '../services/auth_validators.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _ok = false;
  PasswordScore _pwdScore = const PasswordScore(
      strength: PasswordStrength.empty,
      fraction: 0,
      label: '',
      score: 0,
      feedback: []);

  @override
  void initState() {
    super.initState();
    _pwd.addListener(() {
      setState(() {
        _pwdScore = evaluatePassword(_pwd.text);
      });
    });
  }

  @override
  void dispose() {
    _pwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_pwd.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    setState(() => _busy = true);
    final ok = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(_pwd.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = ok;
    });
    if (ok) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) context.go(AppRoutes.login);
      });
    }
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
              child: const Icon(Icons.lock_open_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          const SizedBox(height: 20),
          AuthHeading(
            title: 'Set a new password',
            subtitle:
                'Pick a strong password to keep your shipments and Airpak Coin balance safe.',
          ),
          const SizedBox(height: 28),
          AuthTextField(
            controller: _pwd,
            label: 'NEW PASSWORD',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            validator: validatePassword,
          ),
          PasswordStrengthMeter(score: _pwdScore),
          const SizedBox(height: 18),
          AuthTextField(
            controller: _confirm,
            label: 'CONFIRM NEW PASSWORD',
            icon: Icons.lock_outline_rounded,
            obscure: true,
            validator: (v) =>
                (v == null || v != _pwd.text) ? 'Passwords do not match' : null,
          ),
          if (_ok) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Password updated! Redirecting to sign in…',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'Update password',
            icon: Icons.check_rounded,
            onPressed: _submit,
            busy: _busy,
            sublabel: 'You\'ll be signed out of all devices',
          ),
          const SizedBox(height: 14),
          Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Text('Back',
                  style: GoogleFonts.inter(
                      color: context.textMutedColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
