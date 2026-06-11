import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

class AdminResetPasswordScreen extends ConsumerStatefulWidget {
  const AdminResetPasswordScreen({super.key});
  @override
  ConsumerState<AdminResetPasswordScreen> createState() =>
      _AdminResetPasswordScreenState();
}

class _AdminResetPasswordScreenState
    extends ConsumerState<AdminResetPasswordScreen> {
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _ok = false;

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
        if (mounted) context.go(AppRoutes.adminLogin);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Set new admin password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Set a new password',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('Use at least 6 characters.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.textMutedColor)),
              const SizedBox(height: 24),
              TextField(
                controller: _pwd,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 20),
              if (_ok)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text('Password updated. Redirecting…',
                              style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              AppPrimaryButton(
                label: 'Update password',
                icon: Icons.check,
                onPressed: _submit,
                busy: _busy,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
