import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/design_system.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_controller.dart';

class AdminForgotPasswordScreen extends ConsumerStatefulWidget {
  const AdminForgotPasswordScreen({super.key});
  @override
  ConsumerState<AdminForgotPasswordScreen> createState() =>
      _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState
    extends ConsumerState<AdminForgotPasswordScreen> {
  final _email = TextEditingController(text: 'admin@airpak-express.com');
  bool _sent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _sent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Reset admin password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: _sent ? _buildSent() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Forgot your password?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(
          'Enter your admin email and we will send a reset link.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.textMutedColor),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Admin email',
            prefixIcon: Icon(Icons.shield_outlined),
          ),
        ),
        const SizedBox(height: 20),
        AppPrimaryButton(
            label: 'Send reset link',
            icon: Icons.send,
            onPressed: _submit,
            busy: _busy),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back to sign in'),
          ),
        ),
      ],
    );
  }

  Widget _buildSent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.brandLight,
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.brand, size: 36),
        ),
        const SizedBox(height: 18),
        Text('Check your email',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('We sent a reset link to ${_email.text.trim()}',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.textMutedColor),
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        AppPrimaryButton(
          label: 'Open reset link',
          icon: Icons.arrow_forward,
          onPressed: () => context.go(AppRoutes.adminReset),
        ),
      ],
    );
  }
}
